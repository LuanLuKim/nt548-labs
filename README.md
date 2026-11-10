# NT548 — Bài thực hành DevOps cơ bản

Đây là kho lưu trữ các bài thực hành của nhóm cho môn **NT548** tại Trường Đại học Công nghệ Thông tin (UIT). Mỗi bài lab có một thư mục riêng chứa mã nguồn và hướng dẫn thực hành.

## Các bài lab

- [Lab 01 — Infrastructure as Code (IaC)](lab01/README.md) — Triển khai hạ tầng mạng trên AWS bằng Terraform và AWS CloudFormation.

## GitHub Actions cho Terraform (bài thực hành 02, câu 1)

Workflow [terraform-lab01.yml](.github/workflows/terraform-lab01.yml) tự chạy kiểm tra định dạng, cú pháp, test Terraform và Checkov khi mã Terraform được đẩy lên nhánh `main`. Checkov hiện còn các cảnh báo cần phân loại; workflow ghi số lượng cảnh báo vào phần Summary và chỉ dừng khi không phân tích được mã Terraform. Kết quả Checkov không được coi là đã đạt toàn bộ chính sách.

Để triển khai trong AWS Academy Learner Lab:

1. Hoàn tất việc chuyển state cục bộ sang S3 backend trong `lab01/terraform/backend.tf`. Kiểm tra `terraform state list` vẫn có 18 tài nguyên trước khi dùng workflow triển khai.
2. Tại GitHub repository, mở **Settings → Secrets and variables → Actions**. Tạo ba **repository secrets** `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN` từ mục **AWS Details → AWS CLI** của phiên lab đang chạy. Tạo ba **repository variables** `SSH_CIDR` (IP quản trị dạng `/32`), `AMI_ID` (AMI hợp lệ ở `us-east-1`) và `EC2_KEY_NAME` (tên EC2 key pair, ví dụ `vockey`). Không đưa khóa AWS, `terraform.tfvars` hoặc state lên Git.
3. Mở **Actions → Terraform Lab 01 → Run workflow**, bật `deploy` để chạy `plan` rồi `apply`. Workflow dừng nếu plan có thao tác xóa tài nguyên. Sau khi chạy, kiểm tra Terraform outputs và tài nguyên trên AWS Console.

Credential của Learner Lab hết hạn theo phiên. Cập nhật cả ba secrets khi khởi động phiên mới trước khi chạy deploy.
