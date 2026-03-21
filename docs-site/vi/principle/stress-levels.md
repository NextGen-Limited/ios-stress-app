# Cấp độ căng thẳng

StressMonitor phân loại căng thẳng thể chất thành bốn cấp độ dựa trên đường cơ sở HRV và nhịp tim lúc nghỉ cá nhân.

| Cấp độ | Chỉ báo | Ý nghĩa |
|--------|---------|---------|
| Trạng thái xuất sắc | 🟢 Xanh lá | HRV cao, nhịp tim lúc nghỉ thấp — áp lực cơ thể rất thấp |
| Trạng thái bình thường | 🔵 Xanh dương | HRV và nhịp tim bình thường — áp lực trong tầm kiểm soát |
| Cần chú ý | 🟡 Vàng | HRV thấp hoặc nhịp tim tăng — cần điều chỉnh lối sống |
| Quá tải áp lực | 🔴 Đỏ | HRV giảm mạnh, nhịp tim tăng đáng kể — nguy cơ quá tải cao |

Tất cả ngưỡng đều được cá nhân hóa theo lịch sử của bạn — không phải giá trị cố định chung. Cùng một con số HRV tuyệt đối có thể là "Xuất sắc" với người này nhưng "Cần chú ý" với người khác.

## Cách tính cấp độ

Điểm căng thẳng kết hợp:
- **Thành phần HRV** (trọng số 70%) — độ lệch so với đường cơ sở cá nhân
- **Thành phần nhịp tim lúc nghỉ** (trọng số 30%) — độ lệch so với nhịp tim lúc nghỉ cá nhân

Điểm 0–100 kết hợp được ánh xạ sang bốn cấp độ trên.

## Tại sao cá nhân hóa quan trọng

StressMonitor đánh giá mỗi lần đo so với lịch sử **30 ngày của bạn**, không phải trung bình dân số. Điều này có nghĩa:

- Người dùng mới có thể nhận kết quả kém chính xác trong 7–30 ngày đầu khi đường cơ sở đang xây dựng
- Sau 30 ngày, ứng dụng có tham chiếu cá nhân ổn định để so sánh có ý nghĩa
- Thay đổi lối sống đột ngột (chế độ tập mới, bệnh tật, du lịch) tạm thời làm lệch đường cơ sở
