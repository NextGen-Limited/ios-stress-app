# Tần suất đo & Đo thủ công

## Tần suất đo tự động

Trong điều kiện bình thường, Apple Watch tự động đo HRV mỗi **2 đến 5 giờ**. StressMonitor đọc dữ liệu này từ Apple Health — không tự điều khiển cảm biến.

Apple Watch tạm dừng đo HRV tự động khi:
- Low Power Mode đang bật
- Phiên tập luyện đang hoạt động
- Bạn đang di chuyển nhiều
- Đồng hồ không đeo chặt hoặc bị khóa
- watchOS 7 trở về trước

> **Lưu ý:** Là nhà phát triển, chúng tôi không thể điều chỉnh tần suất đo HRV tích hợp của Apple Watch.

## Tăng tần suất đo (Tùy chọn)

Với người dùng ngoài Trung Quốc đại lục, bạn có thể kích hoạt Apple Watch kiểm tra HRV mỗi ~15 phút bằng cách bật **AFib History**:

1. Mở **Health** app trên iPhone → Heart → AFib History → Bật
2. Mở **Watch** app → Heart → AFib History → Bật

Lưu ý điều này tăng tiêu thụ pin. Đây hiện là cách duy nhất tăng tần suất lấy mẫu HRV.

## Đo thủ công

Để kích hoạt đo HRV ngay lập tức:

1. Mở **Mindfulness** app trên Apple Watch
2. Bắt đầu phiên **Breathe** — chọn **3 phút trở lên** để đảm bảo chính xác
3. Đảm bảo đồng hồ đeo chặt; giữ yên cơ thể và thở tự nhiên (không cần theo nhịp hướng dẫn)
4. Sau khi hoàn tất, khóa rồi mở khóa iPhone
5. Chờ khoảng 1 phút — StressMonitor sẽ nhận dữ liệu và cập nhật

> Do hạn chế Apple Watch, dữ liệu đôi khi mất thêm thời gian. Nếu chưa cập nhật sau 30 phút, thử lại sau.

### Thời điểm tốt nhất để đo thủ công

Khuyến nghị đo **trong vòng 10 phút sau khi thức dậy**, trước khi ăn, uống cà phê, tập luyện, hoặc tương tác xã hội. Điều này nắm bắt trạng thái cơ sở thực sự.

Điều kiện lý tưởng:
- Ngồi hoặc nằm
- Hoạt động thể chất tối thiểu
- Không ăn nhiều, rượu bia, hoặc caffeine gần đây
- Cảm xúc bình tĩnh

### Khi nào nên tránh đo

- Trong vòng 30 phút sau tập luyện cường độ cao
- Khi cảm xúc mạnh hoặc căng thẳng
- Sau khi uống rượu bia hoặc caffeine
- Sau khi hút thuốc hoặc dùng thuốc ảnh hưởng nhịp tim

## Tại sao dữ liệu có thể cũ

HRV có ý nghĩa nhất theo cửa sổ lấy mẫu dài. Nếu bạn kiểm tra giữa buổi chiều mà không có khoảng nghỉ ngơi gần đây, số đo phản ánh lần đo trước — đây là hành vi bình thường, không phải lỗi.

Nếu dữ liệu không cập nhật hơn nửa ngày, kiểm tra:
- iPhone và Watch đang kết nối
- Background App Refresh đã bật cho StressMonitor
- Apple Watch có dữ liệu nhịp tim gần đây trong Health app
