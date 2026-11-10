# Bài thực hành 02, câu 1 — Kết quả Checkov và ảnh minh chứng

## Kết quả quét

- Công cụ: Checkov 3.4.3, quét thư mục `lab01/terraform` với framework Terraform.
- Kết quả: **40 passed, 12 failed, 0 skipped, 0 parsing errors** trên 18 tài nguyên trong mã.
- Nguồn đối chiếu: [lần chạy GitHub Actions triển khai thành công](https://github.com/LuanLuKim/nt548-labs/actions/runs/42821873440), phần **Summary** của job `checks`. Kết quả quét cục bộ cùng phiên bản cho đúng 12 cảnh báo bên dưới.
- Workflow hiện ghi nhận các cảnh báo nhưng chưa dùng chúng để chặn deploy. **Job xanh không có nghĩa là đã đạt cả 12 quy tắc này.**

## Chi tiết 12 cảnh báo

| # | Rule | Tài nguyên bị đánh dấu | Ý nghĩa và cách xử lý/đối chiếu |
|---|---|---|---|
| 1 | `CKV_AWS_126` | `module.compute.aws_instance.public` | Chưa bật EC2 detailed monitoring. Nếu yêu cầu chính sách bắt buộc, thêm `monitoring = true` cho máy public; xem xét chi phí CloudWatch trước khi áp dụng. |
| 2 | `CKV_AWS_135` | `module.compute.aws_instance.public` | Mã chưa khai báo `ebs_optimized = true`. Kiểm tra loại instance đang dùng có hỗ trợ và chính sách yêu cầu gì; khai báo rõ nếu cần. |
| 3 | `CKV_AWS_88` | `module.compute.aws_instance.public` | Máy public được gán public IPv4. Đây là bastion của mô hình lab để SSH từ địa chỉ quản trị `/32`; ghi nhận ngoại lệ thiết kế và kiểm tra Security Group không mở SSH rộng hơn. |
| 4 | `CKV_AWS_126` | `module.compute.aws_instance.private` | Chưa bật EC2 detailed monitoring cho máy private. Cách xử lý tương tự mục 1. |
| 5 | `CKV_AWS_135` | `module.compute.aws_instance.private` | Mã chưa khai báo `ebs_optimized = true` cho máy private. Cách đối chiếu tương tự mục 2. |
| 6 | `CKV_AWS_24` | `module.security.aws_vpc_security_group_ingress_rule.private_ssh` | Checkov cảnh báo SSH từ nguồn rộng. Trong mã, rule này dùng `referenced_security_group_id` trỏ tới public SG, không dùng `0.0.0.0/0`. Cần kiểm tra tab **Inbound rules** của private SG trên AWS Console để xác nhận nguồn thực tế là public SG; nếu đúng, ghi nhận khả năng Checkov phân tích chưa đầy đủ. |
| 7 | `CKV2_AWS_41` | `module.compute.aws_instance.public` | Public EC2 chưa gắn IAM instance profile/role. Mô hình hiện không khai báo quyền AWS API cho máy; nếu ứng dụng cần gọi AWS API, tạo role với quyền tối thiểu và gắn vào instance. |
| 8 | `CKV2_AWS_41` | `module.compute.aws_instance.private` | Private EC2 chưa gắn IAM instance profile/role. Cách xử lý tương tự mục 7. |
| 9 | `CKV2_AWS_5` | `module.security.aws_security_group.public` | Checkov chưa xác nhận SG được gắn vào tài nguyên. Terraform truyền ID của public SG sang `aws_instance.public.vpc_security_group_ids` qua module output. Kiểm tra tab **Security** của public EC2 trên Console trước khi kết luận đây là cảnh báo do quan hệ xuyên module. |
| 10 | `CKV2_AWS_5` | `module.security.aws_security_group.private` | Tương tự mục 9: private SG được truyền sang `aws_instance.private.vpc_security_group_ids`. Kiểm tra tab **Security** của private EC2 trên Console. |
| 11 | `CKV2_AWS_11` | `module.network.aws_vpc.this` | VPC chưa cấu hình Flow Logs. Nếu cần nhật ký lưu lượng mạng, bổ sung VPC Flow Logs cùng nơi lưu log và quyền cần thiết. |
| 12 | `CKV2_AWS_12` | `module.network.aws_vpc.this` | Chưa quản lý default Security Group của VPC để giới hạn toàn bộ ingress/egress. Kiểm tra SG mặc định trên Console; nếu phải tuân thủ rule này, quản lý và siết rule của default SG trong Terraform. |

Mã liên quan: [compute](lab01/terraform/modules/compute/main.tf), [security](lab01/terraform/modules/security/main.tf), [network](lab01/terraform/modules/network/main.tf). Hai trường hợp `CKV_AWS_24` và `CKV2_AWS_5` **chưa được xác nhận là false positive** cho đến khi đối chiếu cấu hình AWS thực tế.

## Cần chụp gì trên AWS Console?

Đặt Region ở **us-east-1**. Dùng ID trong `terraform output` hoặc log job deploy để chọn đúng tài nguyên của lab, tránh chụp nhầm default VPC/tài nguyên khác.

1. **EC2 → Instances:** chụp hai máy `nt548-tf-public` và `nt548-tf-private`, trạng thái `Running`, VPC/subnet và cột Public IPv4. Máy public có IP công khai; máy private không có. Nếu một ảnh không đủ cột, chụp thêm tab **Details/Networking** của từng máy.
2. **VPC → Your VPCs** và **Subnets:** chụp VPC CIDR `10.10.0.0/16`; public subnet `10.10.1.0/24`, private subnet `10.10.2.0/24`, cả hai ở `us-east-1a`. Có thể dùng hai ảnh.
3. **VPC → Route tables:** chụp tab **Routes** của cả hai bảng. Public route `0.0.0.0/0 → Internet Gateway`; private route `0.0.0.0/0 → NAT Gateway`. Chụp thêm tab **Subnet associations** nếu cần chứng minh mỗi bảng gắn đúng subnet.
4. **VPC → NAT gateways:** chụp NAT ở trạng thái `Available`, nằm trong public subnet, có Elastic IP. Có thể chụp **Internet gateways** để thấy IGW gắn với VPC của lab.
5. **EC2 → Security Groups:** chụp **Inbound rules** của public SG (TCP 22 chỉ từ IP quản trị `/32`) và private SG (TCP 22 chỉ từ **public SG ID**). Hai ảnh này cũng dùng để đối chiếu `CKV_AWS_24`.
6. **EC2 → Instances → chọn từng máy → Security:** chụp SG được gắn cho public và private EC2; đối chiếu `CKV2_AWS_5`.
7. **S3 → bucket `nt548-tfstate-wtf12`:** chụp danh sách object có khóa `lab01/terraform.tfstate` để minh chứng remote state. Chỉ chụp tên object, không mở hoặc tải nội dung state.

Ngoài AWS Console, chụp [GitHub Actions run](https://github.com/LuanLuKim/nt548-labs/actions/runs/42821873440): cả hai job `checks` và `deploy` thành công; phần Checkov Summary; log `Apply complete! Resources: 0 added, 0 changed, 0 destroyed.` Đây là bằng chứng quy trình tự động hóa đã chạy.

Ảnh chụp có IP, Account ID hoặc chi tiết hệ thống nên lưu trong báo cáo/thư mục minh chứng riêng; không commit ảnh chứa thông tin riêng tư lên repository.
