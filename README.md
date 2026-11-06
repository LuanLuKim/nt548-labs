# NT548 — Thực hành Điện toán Đám mây & DevOps (Cloud Computing Labs)

Kho lưu trữ mã nguồn các bài thực hành môn học **NT548** tại Trường Đại học Công nghệ Thông tin (UIT - VNU-HCM).

---

## 📌 Tổng quan Lab 01: Infrastructure as Code (IaC)

Bài Lab 01 tập trung vào việc tự động hóa toàn bộ quy trình thiết kế, triển khai, kiểm thử và thu hồi một cụm hạ tầng mạng VPC phân tầng bảo mật trên AWS bằng cả hai công cụ:
* **Terraform** (HashiCorp HCL - Mô hình Modules)
* **AWS CloudFormation** (YAML - Mô hình Nested Stacks)

### 📐 Sơ đồ kiến trúc hạ tầng (Architecture)

```text
Laptop Quản trị (Admin / Whitelist IP)
        │
        │ [SSH TCP 22 qua Internet]
        ▼
┌────────────────────────────────────────────────────────────────────────┐
│ AWS VPC: 10.10.0.0/16                                                  │
│                                                                        │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │ Public Subnet: 10.10.1.0/24 (us-east-1a)                         │  │
│  │                                                                  │  │
│  │   [Public EC2 / Bastion Host] (Amazon Linux 2023)                │  │
│  │   - Public IPv4 + Private IPv4 (10.10.1.x)                       │  │
│  │   - Public Security Group: Chỉ mở TCP 22 cho Whitelist IP (/32)  │  │
│  │                                                                  │  │
│  │   [NAT Gateway]                                                  │  │
│  │   - Gắn Elastic IP (EIP) cố định                                 │  │
│  │   - Public Route Table: 0.0.0.0/0 -> Internet Gateway            │  │
│  └──────────────────┬───────────────────────────────────────────────┘  │
│                     │                                                  │
│                     │ [SSH ProxyJump qua mạng nội bộ 10.10.0.0/16]     │
│                     ▼                                                  │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │ Private Subnet: 10.10.2.0/24 (us-east-1a)                        │  │
│  │                                                                  │  │
│  │   [Private EC2 / Internal Server] (Amazon Linux 2023)            │  │
│  │   - Private IPv4 (10.10.2.x) - KHÔNG có Public IP                │  │
│  │   - Private Security Group: TCP 22 CHỈ TỪ Public Security Group  │  │
│  │   - Private Route Table: 0.0.0.0/0 -> NAT Gateway                │  │
│  └──────────────────┬───────────────────────────────────────────────┘  │
└─────────────────────┼──────────────────────────────────────────────────┘
                      │
                      │ [Lưu lượng HTTPS ra ngoài: curl https://aws.amazon.com]
                      ▼
             Internet Gateway (IGW)
                      │
                      ▼
                   Internet
```

---

## 📂 Cấu trúc mã nguồn

```text
nt548-labs/
├── .gitignore                      # Loại trừ credentials, tfstate, private keys, evidence
├── README.md                       # Hướng dẫn chi tiết dự án và kiểm thử
└── lab01/
    ├── terraform/                  # Mã nguồn triển khai Terraform
    │   ├── versions.tf             # Yêu cầu Terraform >= 1.17.1 và AWS provider ~> 6.0
    │   ├── providers.tf            # Cấu hình AWS provider, region và default tags
    │   ├── variables.tf            # Khai báo các biến đầu vào
    │   ├── terraform.tfvars.example # File mẫu cấu hình biến môi trường
    │   ├── main.tf                 # Gọi 3 modules: network -> security -> compute
    │   ├── outputs.tf              # Xuất ID và IP phục vụ kiểm thử
    │   ├── modules/
    │   │   ├── network/            # VPC, Subnets, IGW, EIP, NAT Gateway, Route Tables (10 tài nguyên)
    │   │   ├── security/           # Public & Private Security Groups, Ingress/Egress Rules (6 tài nguyên)
    │   │   └── compute/            # 2 EC2 instances, IMDSv2, gp3 EBS (2 tài nguyên)
    │   └── tests/
    │       └── local.tftest.hcl    # Unit test Terraform cục bộ với mock provider
    ├── cloudformation/             # Mã nguồn triển khai AWS CloudFormation
    │   ├── root.yaml               # Template gốc quản lý 3 nested stacks
    │   └── modules/
    │       ├── network.yaml        # Nested stack cho VPC, Subnets, NAT, IGW, Routing
    │       ├── security.yaml       # Nested stack cho Security Groups
    │       └── compute.yaml        # Nested stack cho EC2 instances
    └── tests/
        ├── check-local.py          # Bộ kiểm tra tính hợp lệ cú pháp và ràng buộc của template
        └── test-cases.md           # Đặc tả các ca kiểm thử T01 - T13
```

---

## 🚀 Hướng dẫn thử nghiệm (Testing Guide)

### 1. Kiểm tra mã nguồn cục bộ (Không tốn chi phí AWS)

#### Với Terraform:
```powershell
cd lab01/terraform

# Kiểm tra định dạng mã nguồn:
terraform fmt -check -recursive

# Xác thực cú pháp cấu hình:
terraform validate

# Chạy unit tests giả lập (Mock tests):
terraform test
```

#### Với CloudFormation:
```powershell
cd lab01

# Kiểm tra cú pháp template bằng cfn-lint:
cfn-lint cloudformation/root.yaml cloudformation/modules/*.yaml

# Chạy bộ test kiểm tra hợp đồng cấu hình:
python tests/check-local.py
```

---

### 2. Quy trình triển khai và kiểm thử với Terraform

#### Bước 2.1: Chuẩn bị biến cấu hình
Sao chép file mẫu và điền thông số thực tế của bạn:
```powershell
cd lab01/terraform
Copy-Item terraform.tfvars.example terraform.tfvars
```
Cấu hình trong `terraform.tfvars`:
- `aws_region = "us-east-1"`
- `az = "us-east-1a"`
- `ssh_cidr = "<IP_PUBLIC_CUA_BAN>/32"` *(Lấy IP bằng: `(Invoke-RestMethod 'https://checkip.amazonaws.com').Trim() + '/32'`)*
- `key_name = "vockey"`
- `ami_id = "ami-0c230065b91270bc6"`

#### Bước 2.2: Khởi tạo và xem trước kế hoạch (Plan)
```powershell
terraform init
terraform plan -out=deploy.tfplan
```
*Kỳ vọng:* `Plan: 18 to add, 0 to change, 0 to destroy.`

#### Bước 2.3: Thực thi triển khai (Apply)
```powershell
terraform apply deploy.tfplan
```
*Kỳ vọng:* `Apply complete! Resources: 18 added, 0 changed, 0 destroyed.` kèm bảng Outputs hiển thị VPC ID, Subnet IDs, Instance IDs và Public IP.

---

### 3. Các kịch bản kiểm thử trực tiếp trên AWS (Verification & Testing)

#### Kịch bản 1: Thử nghiệm an ninh chặn IP lạ (Negative Test)
- Từ một máy tính/thiết bị có **IP nằm ngoài whitelist**:
  ```bash
  ssh -i <private_key.pem> -o ConnectTimeout=10 ec2-user@<PUBLIC_EC2_IP>
  ```
- **Kết quả kỳ vọng:** Bị `Connection timed out` sau 10 giây.
- **Ý nghĩa:** Chứng minh Security Group hoạt động chính xác, gói tin bị DROP ngay tại biên mạng AWS, bảo vệ máy chủ trước các cuộc quét cổng và brute-force.

#### Kịch bản 2: SSH vào Public EC2 (Bastion Host)
- Từ máy tính có **IP đã được whitelist**:
  ```bash
  ssh -i <private_key.pem> ec2-user@<PUBLIC_EC2_IP>
  ```
- Sau khi vào máy, xác nhận định danh:
  ```bash
  hostname
  whoami
  ip -4 -brief addr show dev ens5
  exit
  ```
- **Kết quả kỳ vọng:** Đăng nhập thành công với user `ec2-user`, IP nội bộ `10.10.1.x`.

#### Kịch bản 3: SSH vào Private EC2 qua ProxyJump (Bảo mật cao)
> [!IMPORTANT]
> Tuyệt đối không sao chép private key lên Public EC2. Dùng kỹ thuật **ProxyJump (`-J`)** hoặc **ProxyCommand** để nhảy xuyên qua Public EC2 vào Private EC2. File khóa private key luôn nằm an toàn tại máy cá nhân.

- Chạy lệnh một dòng từ máy cá nhân:
  ```bash
  ssh -i <private_key.pem> -o "ProxyCommand=ssh -i <private_key.pem> -W %h:%p ec2-user@<PUBLIC_EC2_IP>" ec2-user@<PRIVATE_EC2_IP>
  ```
- Khi đã vào bên trong Private EC2:
  ```bash
  # 1. Xác nhận IP nội bộ (không có card mạng Public):
  ip -4 -brief addr show dev ens5

  # 2. KIỂM THỬ NAT GATEWAY (Bài test mấu chốt):
  curl -sI https://aws.amazon.com | head -n 5
  curl https://checkip.amazonaws.com
  exit
  ```
- **Kết quả kỳ vọng:**
  - `ip a`: Hiển thị IP dải `10.10.2.x`.
  - `curl -sI`: Trả về `HTTP/2 200` (Private EC2 truy cập được Internet).
  - `curl checkip`: Trả về đúng địa chỉ **Elastic IP của NAT Gateway** (chứng minh lưu lượng được định tuyến an toàn qua NAT Gateway).

#### Kịch bản 4: Kiểm tra tính nhất quán (Drift Check)
```powershell
terraform plan -detailed-exitcode
```
- **Kết quả kỳ vọng:** `No changes. Your infrastructure matches the configuration.` (Exit code: `0`).

---

### 4. Thu hồi hạ tầng (Clean up)

Sau khi hoàn thành kiểm thử và thu thập minh chứng, thu hồi toàn bộ tài nguyên để tránh phát sinh chi phí:

```powershell
# Tạo kế hoạch hủy:
terraform plan -destroy -out=destroy.tfplan

# Thực thi hủy:
terraform apply destroy.tfplan
```
*Kỳ vọng:* `Apply complete! Resources: 0 added, 0 changed, 18 destroyed.` và state rỗng.

---

## 🔒 Quy chuẩn An toàn và Bảo mật (Security Guidelines)

1. **Không đưa bí mật lên Git:** File `.gitignore` đã cấu hình loại trừ:
   - Các file khóa riêng tư: `*.pem`, `*.key`.
   - Các file quản lý trạng thái: `*.tfstate`, `*.tfstate.*`, `*.tfplan`.
   - File cấu hình chứa IP/thông số thật: `terraform.tfvars`.
   - Credentials và thư mục tài khoản: `.aws/`, `.env`.
   - Nhật ký và hình ảnh minh chứng chứa IP/Account ID.
2. **Nguyên tắc Đặc quyền Tối thiểu (Least Privilege):** 
   - Public Security Group chỉ cho phép truy cập SSH từ địa chỉ IP cụ thể của người quản trị (`/32`).
   - Private Security Group chỉ chấp nhận kết nối từ Public Security Group ID, không mở ra Internet.
3. **Bảo vệ Metadata:** Cả hai máy EC2 đều bắt buộc sử dụng **IMDSv2** (`http_tokens = "required"`) để phòng chống tấn công SSRF.
