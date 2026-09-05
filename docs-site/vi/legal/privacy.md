# Chính sách bảo mật

*Cập nhật lần cuối: 2026-09-03*

## Tổng quan

StressMonitor cam kết bảo vệ quyền riêng tư của bạn. Tất cả dữ liệu sức khỏe được xử lý cục bộ trên thiết bị. Chúng tôi không bán hoặc cho thuê thông tin cá nhân.

## Dữ liệu chúng tôi truy cập

- **Heart Rate Variability (HRV)** — chỉ đọc từ Apple Health
- **Nhịp tim lúc nghỉ** — chỉ đọc từ Apple Health
- **Điểm căng thẳng tính toán** — xử lý trên thiết bị, lưu cục bộ qua SwiftData
- **Ảnh & video** — chỉ những ảnh hoặc video bạn chọn chia sẻ trong Trò Chuyện Cùng AI; được gửi kèm tin nhắn của bạn để tạo phản hồi (xem "Trò Chuyện Cùng AI")
- **Nội dung tin nhắn trò chuyện** — tin nhắn bạn gửi trong Trò Chuyện Cùng AI, lưu giữ theo chính sách lưu trữ lịch sử trò chuyện của máy chủ (xem "Trò Chuyện Cùng AI")
- **Mã nhận dạng thiết bị & ứng dụng** — mã nhận dạng thiết bị và ứng dụng được truyền cho Google (Firebase Auth / Google Sign-In) chỉ nhằm xác thực và phục vụ chức năng ứng dụng; không bao giờ dùng để theo dõi hay quảng cáo
- **Tương tác sản phẩm** — dữ liệu tương tác cơ bản với ứng dụng (ví dụ: tính năng nào được sử dụng) được chia sẻ qua Google Firebase cho chức năng ứng dụng; không bao giờ dùng để theo dõi hay quảng cáo

## Dữ liệu chúng tôi không thu thập

- Dữ liệu HealthKit thô không bao giờ được truyền lên máy chủ của chúng tôi — ngoại lệ duy nhất là dữ liệu đã xử lý được mô tả trong mục "Trò Chuyện Cùng AI" dưới đây
- Không có phân tích bên thứ ba hoặc trình theo dõi quảng cáo (Google/Firebase chỉ dùng để đăng nhập — xem "Mã nhận dạng thiết bị & ứng dụng" trên)
- Không có mã nhận dạng quảng cáo
- Dữ liệu HealthKit không bao giờ dùng cho quảng cáo hoặc marketing

## Đồng bộ iCloud

Nếu bạn bật đồng bộ iCloud, lịch sử căng thẳng đồng bộ qua các thiết bị Apple của bạn qua CloudKit. Dữ liệu này được Apple mã hóa đầu cuối. Chúng tôi không thể truy cập.

## Trò Chuyện Cùng AI

Khi bạn mở Trò Chuyện Cùng AI, ứng dụng gửi các giá trị đã xử lý đến máy chủ của StressMonitor để tạo phản hồi tư vấn: điểm căng thẳng, phân loại căng thẳng, độ tin cậy, xu hướng, và điểm số đã chuẩn hóa theo từng yếu tố cho HRV, nhịp tim, giấc ngủ, hoạt động và hồi phục. Dữ liệu HealthKit thô (ví dụ: giá trị HRV chính xác theo milisecond, nhịp tim chính xác theo bpm) không bao giờ được gửi kèm.

Yêu cầu này được thực hiện qua một phiên đăng nhập xác thực (Bearer JWT, được thiết lập qua Firebase Auth — đăng nhập ẩn danh hoặc Google Sign-In). Tin nhắn trò chuyện và dữ liệu đã xử lý này được lưu giữ theo chính sách lưu trữ lịch sử trò chuyện của máy chủ, tách biệt với dữ liệu sức khỏe lưu trên thiết bị đã nêu trên. Nếu bạn đính kèm ảnh hoặc video trong trò chuyện, nội dung đó được gửi kèm tin nhắn và áp dụng chính sách lưu giữ tương tự.

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
