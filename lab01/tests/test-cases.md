# Lab01 — kiểm chứng kết nối để viết báo cáo

Theo yêu cầu mới nhất, không dùng khung 13 test case. Phần kết quả trình bày giống mục 4 của báo cáo Terraform: thao tác kết nối, kết quả thực tế và ảnh minh chứng.

## Hai phép thử chính của CloudFormation

| Nội dung | Thao tác | Kỳ vọng | Ảnh |
|---|---|---|---|
| SSH public EC2 | Từ PowerShell dùng SSH config; trong EC2 chạy hostname, whoami, ip -4 -brief address show scope global | Đăng nhập bằng ec2-user; hostname/IP đúng public EC2 | Ảnh SSH public |
| SSH private EC2 | Thoát public, dùng alias private có ProxyJump; chạy cùng ba lệnh | Đăng nhập bằng ec2-user; IP đúng private EC2 | Ảnh SSH private; có thể ghép với public nếu đọc rõ |

Giữ thêm ảnh change set và root/ba nested stacks CREATE_COMPLETE để minh chứng triển khai, tương tự plan/apply của Terraform. Các ảnh này đã có ở lượt 20261105-user-212956; không cần triển khai lại để chụp lại.

## Ảnh cấu hình và thông tin tham khảo bằng log

Theo yêu cầu bổ sung, chụp cấu hình VPC/subnet, route tables, NAT, EC2 và SG để minh họa phần triển khai. Đây là bằng chứng cấu hình, không phải bộ test kết nối riêng. HTTPS/NAT, chi tiết EC2 checks, IMDSv2/EBS và drift có thể dùng log, không bắt buộc chụp riêng. Log kiểm tra đã có được giữ lại để tra cứu; không chạy/chụp lại chỉ để đủ số lượng. Nếu mô tả trong báo cáo phải dùng đúng kết quả và đúng lượt tài nguyên.

Thử bảo mật bằng key sai hoặc từ mạng có public IP khác là tùy chọn, chưa yêu cầu thực hiện. Máy khác cùng Wi-Fi có thể dùng cùng public IP nên không tự chứng minh giới hạn nguồn SSH.

## Trạng thái hiện tại

CloudFormation đã thu hồi theo yêu cầu mới nhất, xác minh lúc 23:32:06 ngày 05/11/2026; lượt sau cần deploy mới để chụp ảnh kết nối. Terraform cũng đã thu hồi; phần bổ sung Terraform để ngày sau. Public IP CloudFormation có thể đổi sau khi stop/start, phải dùng ssh-config-current và outputs/EC2 hiện tại. Không gán ảnh/IP Terraform cho CloudFormation.