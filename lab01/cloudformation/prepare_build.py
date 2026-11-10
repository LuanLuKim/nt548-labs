"""Prepare TaskCat and CodePipeline inputs from CodeBuild environment variables."""

import ipaddress
import json
import os
import re
from pathlib import Path


def required(name: str) -> str:
    value = os.environ.get(name, "").strip()
    if not value:
        raise SystemExit(f"Missing CodeBuild environment variable: {name}")
    return value


ssh_cidr = required("SSH_CIDR")
ami_id = required("AMI_ID")
key_name = required("KEY_NAME")
required("TEMPLATE_BUCKET")

try:
    network = ipaddress.IPv4Network(ssh_cidr, strict=True)
except ValueError as exc:
    raise SystemExit("SSH_CIDR must be a valid IPv4 /32") from exc
if network.prefixlen != 32:
    raise SystemExit("SSH_CIDR must be a valid IPv4 /32")
if not re.fullmatch(r"ami-[0-9a-f]{8,17}", ami_id):
    raise SystemExit("AMI_ID must look like an EC2 AMI ID")
if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9_.@+\-=]{0,254}", key_name):
    raise SystemExit("KEY_NAME contains invalid characters")

parameters = {
    "ProjectName": "nt548-cfn",
    "SshCidr": ssh_cidr,
    "AmiId": ami_id,
    "KeyName": key_name,
}
Path("template-configuration.json").write_text(
    json.dumps({"Parameters": parameters}, indent=2) + "\n", encoding="utf-8"
)

taskcat_config = {
    "project": {"name": "nt548-cfn-lab02", "regions": ["us-east-1"]},
    "tests": {
        "infrastructure": {
            "template": "packaged.yaml",
            "parameters": parameters,
        }
    },
}
# JSON is valid YAML, and TaskCat accepts a .taskcat.yml file in YAML format.
Path(".taskcat.yml").write_text(
    json.dumps(taskcat_config, indent=2) + "\n", encoding="utf-8"
)
