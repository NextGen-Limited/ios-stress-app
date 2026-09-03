# Chính sách bảo mật

*Cập nhật lần cuối: 2026-08-09*

## Tổng quan

StressMonitor cam kết bảo vệ quyền riêng tư của bạn. Tất cả dữ liệu sức khỏe được xử lý cục bộ trên thiết bị. Chúng tôi không bán hoặc cho thuê thông tin cá nhân.

## Dữ liệu chúng tôi truy cập

- **Heart Rate Variability (HRV)** — chỉ đọc từ Apple Health
- **Nhịp tim lúc nghỉ** — chỉ đọc từ Apple Health
- **Điểm căng thẳng tính toán** — xử lý trên thiết bị, lưu cục bộ qua SwiftData

## Dữ liệu chúng tôi không thu thập

- Dữ liệu HealthKit thô không bao giờ được truyền lên máy chủ của chúng tôi — ngoại lệ duy nhất là dữ liệu đã xử lý được mô tả trong mục "Trò Chuyện Cùng AI" dưới đây
- Không có phân tích bên thứ ba hoặc trình theo dõi quảng cáo
- Không có mã nhận dạng quảng cáo
- Dữ liệu HealthKit không bao giờ dùng cho quảng cáo hoặc marketing

## Đồng bộ iCloud

Nếu bạn bật đồng bộ iCloud, lịch sử căng thẳng đồng bộ qua các thiết bị Apple của bạn qua CloudKit. Dữ liệu này được Apple mã hóa đầu cuối. Chúng tôi không thể truy cập.

## Trò Chuyện Cùng AI

Khi bạn mở Trò Chuyện Cùng AI, ứng dụng gửi các giá trị đã xử lý đến máy chủ của StressMonitor để tạo phản hồi tư vấn: điểm căng thẳng, phân loại căng thẳng, độ tin cậy, xu hướng, và điểm số đã chuẩn hóa theo từng yếu tố cho HRV, nhịp tim, giấc ngủ, hoạt động và hồi phục. Dữ liệu HealthKit thô (ví dụ: giá trị HRV chính xác theo milisecond, nhịp tim chính xác theo bpm) không bao giờ được gửi kèm.

Yêu cầu này được thực hiện qua một phiên đăng nhập xác thực (Bearer JWT, được thiết lập qua Firebase Auth — đăng nhập ẩn danh hoặc Google Sign-In). Tin nhắn trò chuyện và dữ liệu đã xử lý này được lưu giữ theo chính sách lưu trữ lịch sử trò chuyện của máy chủ, tách biệt với dữ liệu sức khỏe lưu trên thiết bị đã nêu trên.

## HealthKit

StressMonitor có quyền **chỉ đọc** HealthKit. Chúng tôi không bao giờ ghi dữ liệu trở lại Apple Health.

## Lưu trữ dữ liệu

Tất cả dữ liệu được lưu trên thiết bị. Bạn có thể xóa mọi dữ liệu bất cứ lúc nào từ StressMonitor → Settings → Data Management → Delete All Data.

## Trẻ em

StressMonitor không dành cho trẻ em dưới 18 tuổi.

## Thay đổi

Chúng tôi có thể cập nhật chính sách này. Tiếp tục sử dụng ứng dụng sau khi thay đổi đồng nghĩa với chấp nhận.

## Liên hệ

Câu hỏi về quyền riêng tư: **support@stressmonitor.app**
