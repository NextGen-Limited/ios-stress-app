# Tại sao giá trị HRV khác với Apple Health?

Bạn có thể nhận thấy con số HRV trong StressMonitor khác với trong Apple Health. Điều này là bình thường — hai ứng dụng sử dụng phương pháp tính HRV khác nhau.

## Apple Health dùng SDNN

Apple Health hiển thị **SDNN** (Standard Deviation of Normal-to-Normal intervals) — độ lệch chuẩn của tất cả khoảng nhịp tim bình thường. SDNN phản ánh biến thiên nhịp tim tổng thể, bao gồm cả ảnh hưởng từ hệ giao cảm và phó giao cảm. Giá trị SDNN lớn hơn thường cho thấy biến thiên cao hơn và khả năng thích nghi tim mạch mạnh hơn.

## StressMonitor dùng RMSSD

StressMonitor sử dụng **RMSSD** (Root Mean Square of Successive Differences) — căn bậc hai của trung bình bình phương chênh lệch giữa các khoảng nhịp tim liên tiếp. RMSSD chủ yếu đo hoạt động hệ phó giao cảm và khả năng phục hồi ngắn hạn.

## Khác biệt chính

| | SDNN | RMSSD |
|---|------|-------|
| Phạm vi | HRV tổng thể (dài + ngắn hạn) | Chỉ HRV ngắn hạn |
| Tập trung | Tất cả biến thiên khoảng cách | Chênh lệch khoảng cách liền kề |
| Độ nhạy | Thay đổi khung thời gian dài | Thay đổi vi tế ngắn hạn |
| Phù hợp cho | Đánh giá thần kinh thực vật tổng thể | Trạng thái căng thẳng ngắn hạn |

## Tại sao StressMonitor chọn RMSSD

RMSSD nhạy hơn SDNN và phù hợp hơn để nắm bắt những thay đổi vi tế, real-time trong cơ thể — làm cho nó trở thành chỉ số thích hợp hơn cho theo dõi căng thẳng ngắn hạn và cảnh báo.

Đây là lý do các con số trông khác nhau. Cả hai chỉ số đều hợp lệ; chúng chỉ đo các khía cạnh khác nhau của biến thiên nhịp tim.
