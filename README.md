# DMAG Insight: dashboard "mì ăn liền" cho phòng khám nha khoa

Dashboard thống kê cho các phòng khám nha khoa. Dữ liệu lấy từ phần mềm quản lý họ đang dùng (Bambu, Nha Khoa Số Plus, SimlyDent, DentalFlow, VTTech…), chuẩn hóa về một mô hình chung, rồi tính các chỉ số do DMAG định nghĩa.

## Trong repo

| Đường dẫn | Nội dung |
|---|---|
| `docs/nghien-cuu-thi-truong-pm-nha-khoa.md` | Nghiên cứu thị trường phần mềm nha khoa, cách lấy dữ liệu, rủi ro pháp lý và kiến trúc đề xuất |
| `demo/` | Bản demo giao diện dùng **dữ liệu giả lập** (8 phòng khám mẫu, 01/10/2025 – 13/10/2026) |
| `schema/dmag_canonical.sql` | Mô hình dữ liệu chuẩn (PostgreSQL) mà mọi connector đổ về |

## Chạy demo

Mở `demo/index.html` bằng trình duyệt. Không cần cài đặt gì.

Nguồn chỉnh sửa là `demo/dashboard.html`. Sau khi sửa, chạy lệnh sau để tạo lại `index.html`:

```bash
python3 demo/build.py
```

Các trang trong demo:

- **Tổng quan:** doanh thu phát sinh, thực thu, công nợ, khách mới, tỷ lệ chốt, tỷ lệ đến hẹn; xu hướng doanh thu; doanh thu theo dịch vụ; khách mới theo nguồn; top bác sĩ; định nghĩa chỉ số.
- **Khách hàng & Marketing:** phễu lead → đặt hẹn → đến khám → chốt; hiệu quả từng nguồn (chi phí / khách mới, doanh thu / chi phí quảng cáo).
- **Lịch hẹn:** trạng thái lịch hẹn; bản đồ giờ cao điểm theo thứ và giờ.
- **Bác sĩ:** doanh thu, lượt khám, tỷ lệ chốt, hoa hồng ước tính.
- **Tài chính:** thu và chi, cơ cấu chi phí, tuổi công nợ, hình thức thanh toán.
- **So sánh phòng khám:** xếp hạng toàn chuỗi.
- **Kết nối dữ liệu:** trạng thái đồng bộ của từng phòng khám và luồng dữ liệu.

Bộ lọc dùng chung cho mọi trang: chọn phòng khám (hoặc toàn chuỗi) và khoảng thời gian (có sẵn các mốc hoặc tự chọn ngày). Mọi chỉ số đều so sánh với kỳ liền trước có cùng độ dài. Mỗi biểu đồ có nút **Xem bảng** để xem số liệu chi tiết.

## Bước tiếp theo

1. Chốt bộ KPI với dashboard đang dùng (dash.io.vn) và mẫu file Excel thật từ Bambu và Nha Khoa Số Plus.
2. Viết connector Bambu (Playwright + đọc Excel), chạy trên máy chủ đặt tại Việt Nam.
3. Thay phần sinh dữ liệu giả trong demo bằng API đọc từ PostgreSQL (`dmag.kpi_daily` và các view khác).
