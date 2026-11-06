from pathlib import Path
import ipaddress
import re
import unittest
import yaml

ROOT = Path(__file__).resolve().parents[1]

class CfnLoader(yaml.SafeLoader):
    def construct_mapping(self, node, deep=False):
        keys = [self.construct_object(k, deep=deep) for k, _ in node.value]
        if len(keys) != len(set(keys)):
            raise ValueError("Duplicate YAML key")
        return super().construct_mapping(node, deep=deep)

def intrinsic(loader, tag, node):
    value = loader.construct_scalar(node)
    if tag == 'Ref':
        return {'Ref': value}
    if tag == 'GetAtt':
        return {'Fn::GetAtt': value.split('.', 1)}
    if tag == 'Sub':
        return {'Fn::Sub': value}
    raise ValueError(f'Unsupported intrinsic: {tag}')

CfnLoader.add_multi_constructor('!', intrinsic)

def load(name):
    return yaml.load((ROOT / 'cloudformation' / name).read_text(encoding='utf-8'), Loader=CfnLoader)

class LocalPolicies(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.root = load('root.yaml')
        cls.net = load('modules/network.yaml')
        cls.sec = load('modules/security.yaml')
        cls.comp = load('modules/compute.yaml')

    def test_cidrs_and_parity(self):
        text = (ROOT / 'terraform/terraform.tfvars.example').read_text(encoding='utf-8')
        vals = dict(re.findall(r'^\s*(\w+)\s*=\s*"([^"]*)"', text, re.M))
        vpc, pub, priv = [ipaddress.IPv4Network(vals[k], strict=True) for k in ['vpc_cidr', 'public_cidr', 'private_cidr']]
        self.assertTrue(pub.subnet_of(vpc) and priv.subnet_of(vpc))
        self.assertFalse(pub.overlaps(priv))
        self.assertTrue(16 <= vpc.prefixlen <= 28)
        self.assertTrue(16 <= pub.prefixlen <= 28 and 16 <= priv.prefixlen <= 28)
        self.assertEqual(ipaddress.IPv4Network(vals['ssh_cidr']).prefixlen, 32)
        for key, cfn_key in [('vpc_cidr', 'VpcCidr'), ('public_cidr', 'PublicSubnetCidr'), ('private_cidr', 'PrivateSubnetCidr'), ('az', 'AvailabilityZone'), ('instance_type', 'InstanceType')]:
            self.assertEqual(vals[key], self.root['Parameters'][cfn_key]['Default'])

    def test_nested_contracts(self):
        stacks = self.root['Resources']
        self.assertEqual(set(stacks), {'NetworkStack', 'SecurityStack', 'ComputeStack'})
        children = {'NetworkStack': self.net, 'SecurityStack': self.sec, 'ComputeStack': self.comp}
        def walk(value):
            if isinstance(value, dict):
                if 'Fn::GetAtt' in value:
                    stack, attr = value['Fn::GetAtt']
                    self.assertIn(stack, children)
                    self.assertTrue(attr.startswith('Outputs.'))
                    self.assertIn(attr.split('.', 1)[1], children[stack]['Outputs'])
                if 'Ref' in value:
                    self.assertIn(value['Ref'], self.root['Parameters'])
                for item in value.values():
                    walk(item)
            elif isinstance(value, list):
                for item in value:
                    walk(item)
        for name, stack in stacks.items():
            self.assertEqual(stack['Type'], 'AWS::CloudFormation::Stack')
            props = stack['Properties']
            self.assertTrue((ROOT / 'cloudformation' / props['TemplateURL']).is_file())
            supplied = set(props['Parameters'])
            declared = children[name]['Parameters']
            self.assertLessEqual(supplied, set(declared))
            self.assertLessEqual({k for k, v in declared.items() if 'Default' not in v}, supplied)
        walk(self.root['Resources'])
        walk(self.root['Outputs'])
        self.assertEqual(stacks['ComputeStack']['Properties']['Parameters']['PrivateSubnetId'], {'Fn::GetAtt': ['NetworkStack', 'Outputs.PrivateSubnetId']})
        self.assertEqual(stacks['ComputeStack']['Properties']['Parameters']['PrivateSgId'], {'Fn::GetAtt': ['SecurityStack', 'Outputs.PrivateSgId']})

    def test_network_and_routes(self):
        res = self.net['Resources']
        self.assertEqual(len(res), 13)
        for name, cidr in [('PublicSubnet', 'PublicSubnetCidr'), ('PrivateSubnet', 'PrivateSubnetCidr')]:
            p = res[name]['Properties']
            self.assertEqual(p['VpcId'], {'Ref': 'Vpc'})
            self.assertEqual(p['CidrBlock'], {'Ref': cidr})
            self.assertEqual(p['AvailabilityZone'], {'Ref': 'AvailabilityZone'})
            self.assertFalse(p['MapPublicIpOnLaunch'])
        for prefix in ['Public', 'Private']:
            p = res[prefix + 'DefaultRoute']['Properties']
            self.assertEqual(p['RouteTableId'], {'Ref': prefix + 'RouteTable'})
            self.assertEqual(p['DestinationCidrBlock'], '0.0.0.0/0')
            a = res[prefix + 'Association']['Properties']
            self.assertEqual(a, {'SubnetId': {'Ref': prefix + 'Subnet'}, 'RouteTableId': {'Ref': prefix + 'RouteTable'}})
        self.assertEqual(res['PublicDefaultRoute']['Properties']['GatewayId'], {'Ref': 'Igw'})
        self.assertEqual(res['PrivateDefaultRoute']['Properties']['NatGatewayId'], {'Ref': 'Nat'})
        self.assertEqual(res['IgwAttachment']['Properties'], {'VpcId': {'Ref': 'Vpc'}, 'InternetGatewayId': {'Ref': 'Igw'}})
        self.assertEqual(res['PublicDefaultRoute']['DependsOn'], 'IgwAttachment')

    def test_nat_and_default_sg(self):
        res = self.net['Resources']
        self.assertEqual(res['Nat']['Properties'], {'AllocationId': {'Fn::GetAtt': ['NatEip', 'AllocationId']}, 'SubnetId': {'Ref': 'PublicSubnet'}, 'ConnectivityType': 'public'})
        self.assertEqual(res['Nat']['DependsOn'], 'IgwAttachment')
        self.assertEqual(res['NatEip']['Properties']['Domain'], 'vpc')
        self.assertEqual(self.net['Outputs']['DefaultSgId']['Value'], {'Fn::GetAtt': ['Vpc', 'DefaultSecurityGroup']})

    def test_security_policy(self):
        res = self.sec['Resources']
        self.assertEqual(set(res), {'PublicSg', 'PrivateSg'})
        for name in res:
            self.assertEqual(res[name]['Properties']['VpcId'], {'Ref': 'VpcId'})
            self.assertEqual(res[name]['Properties']['SecurityGroupEgress'], [{'IpProtocol': '-1', 'CidrIp': '0.0.0.0/0'}])
        self.assertEqual(res['PublicSg']['Properties']['SecurityGroupIngress'], [{'IpProtocol': 'tcp', 'FromPort': 22, 'ToPort': 22, 'CidrIp': {'Ref': 'SshCidr'}}])
        self.assertEqual(res['PrivateSg']['Properties']['SecurityGroupIngress'], [{'IpProtocol': 'tcp', 'FromPort': 22, 'ToPort': 22, 'SourceSecurityGroupId': {'Fn::GetAtt': ['PublicSg', 'GroupId']}}])

    def test_ec2_policy(self):
        res = self.comp['Resources']
        self.assertEqual(set(res), {'PublicInstance', 'PrivateInstance'})
        for prefix, public_ip in [('Public', True), ('Private', False)]:
            props = res[prefix + 'Instance']['Properties']
            self.assertEqual(props['ImageId'], {'Ref': 'AmiId'})
            self.assertEqual(props['InstanceType'], {'Ref': 'InstanceType'})
            self.assertEqual(props['KeyName'], {'Ref': 'KeyName'})
            self.assertEqual(props['MetadataOptions']['HttpTokens'], 'required')
            nics = props['NetworkInterfaces']
            self.assertEqual(len(nics), 1)
            self.assertEqual(nics[0]['AssociatePublicIpAddress'], public_ip)
            self.assertEqual(nics[0]['SubnetId'], {'Ref': prefix + 'SubnetId'})
            self.assertEqual(nics[0]['GroupSet'], [{'Ref': prefix + 'SgId'}])
            self.assertTrue(nics[0]['DeleteOnTermination'])
            ebs = props['BlockDeviceMappings'][0]['Ebs']
            self.assertTrue(ebs['Encrypted'] and ebs['DeleteOnTermination'])
            self.assertEqual(ebs['VolumeType'], 'gp3')

if __name__ == '__main__':
    unittest.main(verbosity=2)
