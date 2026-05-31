# Câu hỏi thường gặp

Apple Watch và iOS có một số hạn chế và lỗi đã biết. Các vấn đề như chậm cập nhật complication và tần suất thu thập HRV thường do giới hạn hệ thống watchOS hoặc iOS — không phải lỗi StressMonitor.

## HRV & Dữ liệu

**Tại sao dữ liệu HRV không cập nhật?**

Apple Watch ghi HRV khoảng mỗi 2–5 giờ khi đeo đúng cách. Thu thập dữ liệu dừng khi:
- Low Power Mode đang bật
- Phiên tập luyện đang hoạt động
- Bạn đang di chuyển nhiều
- Đồng hồ không đeo chặt hoặc bị khóa
- watchOS phiên bản 7 trở về trước

Kiểm tra trực tiếp trong Health app — nếu dữ liệu nhịp tim bị kẹt ở một thời điểm, đồng hồ và iPhone có thể mất kết nối hoặc đồng hồ cần khởi động lại.

**Tại sao dữ liệu căng thẳng real-time không cập nhật?**

Căng thẳng real-time được tính từ dữ liệu nhịp tim và HRV gần đây. Người dùng mới cần 3–7 ngày để tích lũy đủ dữ liệu đường cơ sở. Di chuyển nhiều tự động loại trừ dữ liệu khỏi tính toán.

**Tôi có thể xóa dữ liệu HRV không?**

Có. Trong Health app: Heart → Heart Rate Variability → Show All Data → vuốt để xóa từng mục.

## Watch Face & Complications

**Tại sao complication bị trống sau khi thêm?**

Thường là vấn đề tạm thời sau khi watch app cài đặt hoặc cập nhật. Nếu vẫn thiếu, cấu hình trực tiếp trên Apple Watch thay vì qua iPhone Watch app — nhấn giữ mặt đồng hồ, chọn Edit, rồi thêm StressMonitor từ tab Complications.

**Tại sao mặt đồng hồ cập nhật chậm?**

Complications trên Apple Watch không cập nhật real-time. Chậm tới 30 phút là bình thường và ngoài tầm kiểm soát của nhà phát triển. Nếu không cập nhật trong vài giờ, kiểm tra:
- Quyền Health đã bật cho StressMonitor trên cả iPhone và Watch
- Background App Refresh đã bật cho StressMonitor
- Thông báo căng thẳng đang hoạt động (cho thấy pipeline đang chạy)

## Quyền & Background Refresh

**Tôi có thực sự cần bật Background App Refresh không?**

Có. Nhiều tính năng StressMonitor — bao gồm thông báo và cập nhật complication — yêu cầu Background App Refresh. Ứng dụng đã được tối ưu để tiêu thụ pin tối thiểu.

Bật tại: **Settings → General → Background App Refresh → StressMonitor**

**Ứng dụng liên tục yêu cầu bật quyền Health.**

Vào **Settings → Privacy & Security → Health → StressMonitor** và bật tất cả loại dữ liệu. Cũng kiểm tra Apple Watch: **Settings → Health → Data Sources & Access → StressMonitor**.

## Kiến thức về căng thẳng

**StressMonitor có theo dõi được căng thẳng cảm xúc hay nhận thức không?**

Không. StressMonitor theo dõi căng thẳng thể chất bằng HRV và nhịp tim. Mặc dù căng thẳng cảm xúc và nhận thức thường biểu hiện qua phản ứng thể chất, ứng dụng không thể phát hiện trực tiếp trạng thái tinh thần hay cảm xúc.

**Thông báo Stress Overload có nghĩa gì?**

Các chỉ số căng thẳng thể chất (HRV và nhịp tim lúc nghỉ) đã di chuyển đáng kể khỏi đường cơ sở cá nhân vào vùng căng thẳng cao. Hãy cân nhắc nghỉ ngơi, uống nước và giảm hoạt động. Thông báo mang tính thông tin — không phải chẩn đoán y tế.
