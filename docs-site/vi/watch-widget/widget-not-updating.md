# Mặt đồng hồ không tự động cập nhật

Do hạn chế hệ thống Apple Watch, tất cả complications trên mặt đồng hồ có thể bị chậm. **Chậm tới 15–30 phút là bình thường** — Apple Watch không cập nhật complications real-time để tiết kiệm pin. Nhà phát triển không thể trực tiếp kiểm soát tần suất làm mới complication.

Nếu complication không cập nhật trong vài giờ, hoặc chỉ cập nhật khi mở Watch app, hãy làm theo danh sách kiểm tra:

## Bước 1: Xác nhận dữ liệu Health đang chạy

iPhone app có hiển thị được dữ liệu HRV hiện tại không?

- **iPhone:** Settings → Privacy & Security → Health → StressMonitor → bật tất cả loại dữ liệu
- **Apple Watch:** Settings → Health → Data Sources & Access → Apps & Services → StressMonitor → bật tất cả

## Bước 2: Xác nhận thông báo hoạt động

Nếu bạn nhận được thông báo căng thẳng trên iPhone, pipeline dữ liệu đang hoạt động. Nếu không, xem [Sự cố thông báo](../user-guide/notifications-troubleshoot) trước — sửa thông báo thường giải quyết luôn cả cập nhật complication.

## Bước 3: Bật Background App Refresh trên Watch

Trên Apple Watch: **Settings → General → Background App Refresh** → bật cho StressMonitor.

Mặc dù tài liệu Apple nói điều này không ảnh hưởng complications, thử nghiệm cho thấy nó có tác động đến tần suất cập nhật.

## Bước 4: Khởi động lại Watch

Nếu tất cả cài đặt đúng nhưng complication vẫn không cập nhật, khởi động lại Apple Watch. Vấn đề này phổ biến hơn trên watchOS 10.

## Widget iPhone trên màn hình chính không cập nhật

Nếu widget bị cũ:

1. Mở StressMonitor và chờ dashboard làm mới
2. Quay lại màn hình chính — widget sẽ cập nhật trong vài phút

Nếu vẫn bị kẹt, xóa và thêm lại widget: nhấn giữ màn hình chính → **–** để xóa → **+** để thêm lại.

Đồng thời đảm bảo **Settings → General → Background App Refresh** đã bật cho StressMonitor.
