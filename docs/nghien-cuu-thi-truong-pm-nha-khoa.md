# Nghiên cứu: phần mềm quản lý nha khoa tại Việt Nam và cách lấy dữ liệu cho Dashboard DMAG

_Cập nhật: 10/2026. Phạm vi: các phần mềm khách hàng DMAG đang dùng + thị trường chung._

> **Giới hạn của nghiên cứu này.** Từ môi trường nghiên cứu, mạng bị chặn tới các tên miền `*.bambu.vn`, `*.simlydent.vn`, `*.dentalflow.vn`, `*.nhakhoasoplus.net`, `*.vttechsolution.*`, `*.dash.io.vn`.
> Vì vậy chưa mở được dashboard tham khảo hay trang đăng nhập của bên nào. Dữ liệu dưới đây lấy từ website/tài liệu công khai, kết quả tìm kiếm và mã nguồn công khai trên GitHub.
> - **Đã xác minh** = có nguồn chính thức hoặc thấy trực tiếp (URL, code).
> - **Suy luận** = đánh giá kỹ thuật, cần kiểm chứng khi có tài khoản thử.

---

## 1. Tóm tắt nhanh

1. **Thị trường phân mảnh, không có ông lớn.** Có hàng chục phần mềm SaaS nội địa nhỏ.
   - IMARC ước tính quy mô khoảng 13,5 triệu USD (2024), tăng trưởng khoảng 10,8%/năm.
   - Gần như **không bên nào có API công khai, tự phục vụ**.
2. **Một số bên có API nhưng "đóng"**: chỉ có ở gói cao nhất và phải xin hoặc báo giá.
   - **SimlyDent** (gói Enterprise): REST API, webhook, SDK. Họ tự nhận đã có khách nối Power BI/Metabase.
   - **VTTech** (gói Pro): "Central API" có trang docs.
   - **DentalFlow** (gói Advanced): "kết nối API với CRM".
   - **Nextsoft iDental** (gói Advanced): REST API.
   - Bạn "hỏi thì không có API" có thể vì chưa hỏi đúng kênh (bộ phận kỹ thuật/đối tác) hoặc khách đang ở gói thấp.
3. **Bambu và Nha Khoa Số Plus chiếm 12/18 khách hàng của DMAG**, và cả hai **không có API**. Với hai bên này, đơn vị gia công trước đây buộc phải dùng tài khoản admin để đăng nhập rồi cào dữ liệu hoặc tải file Excel. Đây là thực tế chung của thị trường.
4. **Rủi ro lớn nhất hiện nay không nằm ở kỹ thuật mà ở bảo mật và pháp lý.**
   - Bảng quản lý đang lưu mật khẩu admin của 18 phòng khám ở dạng chữ thường.
   - Tài khoản đăng nhập dashboard lại trùng với tài khoản admin của phần mềm nguồn.
   - Từ 01/01/2026, Luật Bảo vệ dữ liệu cá nhân 91/2025/QH15 và Nghị định 356/2025 có hiệu lực. Dữ liệu sức khỏe là **dữ liệu nhạy cảm**, và DMAG đóng vai trò **bên xử lý dữ liệu**. Xem mục 5.

---

## 2. Danh sách khách hàng hiện tại theo phần mềm nguồn

| Phần mềm nguồn | Số khách | Khách hàng | Công nghệ (nhận định) | API |
|---|---|---|---|---|
| **Bambu** | 7 | Tâm An, Lê Hưng, Minh Vương, Huân Hương, Thanh Bạch, Long Hưng, Tân Tiến | ASP.NET WebForms (`login.aspx`), mỗi phòng khám một subdomain | Không |
| **Nha Khoa Số Plus** | 5 | Nguyễn Giang, Quang Minh, Bạch Mai, C&N, Gia Đình | Gốc là app Windows offline; `dangnhap.` và `chuyennghiep.` là bản web (suy luận) | Không |
| **SimlyDent** | 3 | MIDA, Lệ Thanh, Sakura | SPA cloud (app.simlydent.vn) | Có, chỉ ở Enterprise |
| **DentalFlow** | 1 | OSWIN | SaaS cloud, SPA | Có "API CRM", chỉ ở Advanced |
| **VTTech** | 1 | Kim Cương (đang tô đỏ) | ASP.NET Core Razor Pages, có endpoint JSON | Có "Central API", chỉ ở Pro |
| Chưa rõ | 1 | Thiên Hương | Cột "link đầu vào" đang ghi nhầm link dashboard | ? |

**Thứ tự ưu tiên khi xây connector:** Bambu (7) → Nha Khoa Số Plus (5) → SimlyDent (3) → DentalFlow, VTTech.
Chỉ cần hai connector đầu là đã phủ **67% khách hàng**.

---

## 3. Đánh giá từng phần mềm

### 3.1 Bambu / BambuFit — Công ty TNHH Bambu Việt Nam (Hà Nội)

- **Quy mô:** tự nhận hơn 500 phòng khám, 15 năm hoạt động.
- **Kiến trúc** (đã xác minh qua URL): mỗi khách một subdomain `xxx.bambu.vn/login.aspx`, chạy ASP.NET WebForms.
  - Có `__VIEWSTATE` và postback; lưới dữ liệu được render phía server.
  - Trang đăng nhập hiển thị IP người truy cập. Phần mềm có tính năng **"giới hạn điểm truy cập"** (whitelist IP) và **phân quyền ma trận**.
- **Module:** khách hàng, lịch hẹn, công nợ khách, labo và công nợ labo, thẻ bảo hành, SMS, lương thưởng, thu chi nhiều nguồn quỹ, kho, đa chi nhánh.
- **Xuất Excel:** có (ví dụ báo cáo doanh thu bác sĩ).
- **API:** không có.
- **Cách lấy dữ liệu khả thi:**
  1. Dùng trình duyệt tự động (Playwright) đăng nhập, mở từng báo cáo, bấm "Xuất Excel" rồi parse file. Cách này ổn định hơn cào HTML.
  2. Hoặc cào HTML các lưới báo cáo. Phải xử lý ViewState và phân trang postback, dễ vỡ khi giao diện đổi.
- **Lưu ý:**
  - Nếu phòng khám bật whitelist IP, máy chạy connector phải có **IP tĩnh tại Việt Nam** và được thêm vào whitelist.
  - Nên đề nghị phòng khám tạo **user riêng chỉ có quyền xem báo cáo** (Bambu có phân quyền ma trận) thay vì dùng admin.

### 3.2 Nha Khoa Số Plus — Công ty TNHH Dịch vụ Tin học 247 (247 ITS, Hà Nội)

- **Quy mô:** tự nhận hơn 3.000 khách từ 2011. Tracxn ghi thành lập 2016; các nguồn không thống nhất.
- **Kiến trúc:** các bài review mô tả đây là app Windows cài máy, bán license theo máy.
  - Subdomain `dangnhap.` và `chuyennghiep.nhakhoasoplus.net` cho thấy đã có **bản web / bản host từ xa** (suy luận).
  - Khả năng cao là .NET + SQL Server.
- **Module:** hồ sơ, khám và điều trị, đơn thuốc, lịch hẹn, thanh toán, công nợ, labo, phiếu thu chi, SMS chăm sóc khách. Có gửi email báo cáo thu chi tự động cho chủ phòng khám.
- **API / Excel:** chưa tìm thấy.
- **Cách lấy dữ liệu khả thi:**
  1. Nếu phòng khám còn chạy bản cài máy: **kết nối thẳng database** (đọc SQL Server bằng user read-only) với sự đồng ý của phòng khám. Đây là cách ổn định nhất.
  2. Với bản web: dùng trình duyệt tự động như Bambu.
  3. Tận dụng email báo cáo tự động: tạo hộp thư riêng để nhận rồi parse. Cách rẻ nhưng chỉ có số liệu tổng.
- **Cần xác minh:** 5 khách của DMAG đang dùng bản web hay bản cài máy, và đơn vị gia công cũ đang lấy dữ liệu theo cách nào.

### 3.3 SimlyDent — Công ty CP Ecomdent (TP.HCM, thành lập 2020)

- **Quy mô:** tự nhận hơn 800 phòng khám.
- **Giá:** 190k / 490k / 990k mỗi tháng; Enterprise từ 1,2 triệu mỗi chi nhánh mỗi tháng.
- **Tích hợp nhiều:**
  - Zalo OA/ZNS, Facebook/TikTok.
  - Hóa đơn điện tử: VNPT, Viettel, MISA, Bkav…
  - Kế toán MISA, đơn thuốc quốc gia, BHYT, tổng đài VoIP.
- **API:** gói Enterprise có REST API, webhook realtime và SDK Python/Node/PHP. Họ nói đã có khách nối Power BI, Metabase, Tableau. Phí theo báo giá.
- **Đánh giá:** **ứng viên tốt nhất để làm việc chính thức qua API.** Nên liên hệ để xin làm **đối tác tích hợp** (một API key cho nhiều phòng khám) thay vì bắt từng khách nâng gói.
- **Phương án dự phòng:** SPA thường gọi API JSON nội bộ. Có thể dùng chính các API đó sau khi đăng nhập (suy luận), nhưng có thể vi phạm điều khoản sử dụng.

### 3.4 DentalFlow — CTCP Dentaflow (Hà Nội)

- **Quy mô:** tự nhận hơn 500 phòng khám.
- **Giá:** 249k / 599k / 999k–1,099 triệu mỗi tháng.
- **Module:** lịch hẹn, EMR (theo TT 13/2025), CRM đa kênh, nhân sự, tài chính, kho, labo.
- **Xuất Excel:** báo cáo doanh thu có nút Export; tính năng khác nhau theo gói.
- **API:** gói Advanced có "kết nối API với hệ thống CRM", chưa có tài liệu công khai. Nên hỏi trực tiếp.

### 3.5 VTTech Dental — Công ty TNHH VTTech (TP.HCM)

- **Kiến trúc** (đã xác minh qua một repo GitHub công khai của bên thứ ba đồng bộ dữ liệu VTTech):
  - Chạy ASP.NET Core Razor Pages.
  - Đăng nhập qua `/api/Author/Login`, nhận token.
  - Dữ liệu lấy qua các endpoint `?handler=LoadData` trả JSON: danh sách khách, thanh toán, kế hoạch điều trị, chi nhánh, ticket marketing.
- **API chính thức:** "Central API" có trang docs, yêu cầu **gói Pro**.
- **Báo cáo:** xuất Excel, có phân quyền xuất.
- **Đánh giá:** về kỹ thuật là dễ lấy dữ liệu nhất, kể cả khi không có gói Pro.
  - Lưu ý: repo GitHub nói trên **để lộ mật khẩu tenant ở dạng chữ thường**. Đây là ví dụ thực tế của rủi ro ở mục 5.

### 3.6 Các phần mềm khác trên thị trường (để chuẩn bị mở rộng)

| Phần mềm | Đơn vị | Ghi chú |
|---|---|---|
| TDental | Trường Minh Thịnh (từ 2011) | Cloud, khoảng 300–500k mỗi tháng mỗi chi nhánh, báo cáo theo kênh quảng cáo. Chưa thấy API |
| Nextsoft iDental | Nextsoft | 200–400k mỗi tháng. **REST API + token** ở gói Advanced |
| Edental | CTCP Công nghệ Salo | Cloud. Chưa thấy API |
| Odental | SALAVO | Chưa thấy API |
| Odoo | — | Không có module nha khoa Việt Nam phổ biến, chỉ có module phòng khám chung trên apps.odoo.com |

---

## 4. Các cách lấy dữ liệu (xếp theo độ ưu tiên)

| # | Cách | Áp dụng cho | Ưu điểm | Nhược điểm |
|---|---|---|---|---|
| 1 | **API / webhook chính thức** | SimlyDent, VTTech Pro, DentalFlow Advanced, iDental | Ổn định, hợp pháp, có thể realtime | Tốn phí nâng gói hoặc đối tác, phải đàm phán |
| 2 | **Đọc thẳng database** (user read-only) | Bản cài máy (Nha Khoa Số Plus cũ) | Đầy đủ, ổn định | Cần agent cài tại phòng khám, máy phải bật |
| 3 | **Trình duyệt tự động tải Excel** (Playwright) | Bambu, DentalFlow, VTTech, NKS web | Không cần vendor hợp tác | Vỡ khi vendor đổi giao diện; cần tài khoản đăng nhập |
| 4 | **Gọi API JSON nội bộ** sau khi đăng nhập | VTTech, SimlyDent, DentalFlow | Nhanh, dữ liệu sạch | Có thể vi phạm điều khoản vendor; dễ vỡ |
| 5 | **Cào HTML** | Bambu (WebForms) | Phương án cuối | Dễ vỡ nhất, chậm |
| 6 | **Phòng khám tự xuất Excel và upload** | Mọi phần mềm | Đơn giản, hợp pháp | Thủ công, chậm |

**Khuyến nghị:**
- **Kiến trúc connector theo plugin:** mỗi phần mềm một adapter, mỗi adapter có thể có nhiều "chiến lược" (API → Excel → HTML).
- Tất cả đổ về **một schema chuẩn của DMAG**, nên các chỉ số KPI chỉ cần viết một lần.

---

## 5. Bảo mật và pháp lý (quan trọng)

### 5.1 Vấn đề trong bảng quản lý hiện tại

1. **Mật khẩu admin của 18 phòng khám đang được lưu ở dạng chữ thường** trong Google Sheet.
2. **Tài khoản dashboard đầu ra đang trùng với tài khoản admin phần mềm nguồn** ở gần như mọi dòng.
   - Hệ quả: ai được cấp quyền xem dashboard thì cũng có toàn quyền quản trị phần mềm nha khoa, và ngược lại.
   - Nếu hệ thống dash.io.vn bị lộ, toàn bộ phần mềm nguồn của khách cũng bị lộ.
3. Mật khẩu khách hàng là bằng chứng truy cập vào **hồ sơ bệnh án**, tức dữ liệu nhạy cảm theo luật.

**Việc nên làm ngay:**
- Đổi mật khẩu các tài khoản đã bị chia sẻ rộng, kể cả qua ảnh chụp màn hình.
- Tách riêng tài khoản dashboard và tài khoản nguồn.
- Đề nghị mỗi phòng khám tạo **một user riêng tên "DMAG-baocao"** chỉ có quyền xem/xuất báo cáo, không dùng admin.
- Lưu thông tin đăng nhập trong **kho bí mật có mã hóa** (Vault, AWS/GCP Secret Manager, Bitwarden Secrets), không để trong Sheet hay trong code.

### 5.2 Khung pháp lý từ 01/01/2026

- **Văn bản áp dụng:** Luật Bảo vệ dữ liệu cá nhân 91/2025/QH15 và Nghị định 356/2025/NĐ-CP. Hai văn bản này thay Nghị định 13/2023.
- **Dữ liệu sức khỏe và bệnh án là dữ liệu cá nhân nhạy cảm.**
- **Vai trò:** phòng khám là bên kiểm soát dữ liệu, DMAG là **bên xử lý dữ liệu**. Hệ quả:
  - Phải có **hợp đồng hoặc thỏa thuận xử lý dữ liệu** với từng phòng khám, ghi rõ: mục đích, phạm vi dữ liệu, thời hạn lưu và xóa, nghĩa vụ bảo mật, phối hợp khi có sự cố.
  - Phải có **hồ sơ đánh giá tác động xử lý dữ liệu**.
  - Nếu máy chủ, bản sao lưu, công cụ BI hoặc API AI nằm ở nước ngoài thì thêm **hồ sơ đánh giá chuyển dữ liệu ra nước ngoài**.
  - Ưu đãi miễn trừ 5 năm cho doanh nghiệp nhỏ **không áp dụng** với bên cung cấp dịch vụ xử lý dữ liệu hoặc bên xử lý dữ liệu nhạy cảm.
  - Có thông tin cho rằng "dịch vụ xử lý dữ liệu cá nhân" là **ngành nghề kinh doanh có điều kiện**. **Cần luật sư xác nhận.**
  - **Mức phạt:** tối đa 5% doanh thu năm trước với vi phạm chuyển dữ liệu ra nước ngoài, tối đa 3 tỷ đồng với vi phạm khác.
- **Ngoài ra:**
  - Tự động đăng nhập hoặc cào dữ liệu có thể vi phạm điều khoản sử dụng của vendor. Cần **ủy quyền bằng văn bản của phòng khám**, tốt nhất là có sự đồng ý của vendor.

### 5.3 Thiết kế để giảm rủi ro

- **Tối thiểu hóa dữ liệu.** Dashboard KPI hầu như không cần tên, SĐT hay chẩn đoán của bệnh nhân.
  - Chỉ lấy: mã khách đã băm (hash), ngày, dịch vụ, số tiền, bác sĩ, nguồn khách, chi nhánh.
  - Như vậy phần lớn hệ thống nằm ngoài vùng "dữ liệu nhạy cảm".
- **Đặt máy chủ tại Việt Nam.** Viettel IDC, FPT Cloud, VNPT, CMC, BizFly Cloud. Việc này vừa tránh hồ sơ chuyển dữ liệu ra nước ngoài, vừa có IP Việt Nam cố định để vendor (Bambu) whitelist.
- **Ghi nhật ký** mọi lần connector đăng nhập; mã hóa dữ liệu khi lưu; phân quyền theo từng phòng khám (row-level security).

---

## 6. Kiến trúc đề xuất cho "Dashboard mì ăn liền" của DMAG

```
 [Bambu] [NK Số Plus] [SimlyDent] [DentalFlow] [VTTech] [Upload Excel]
     \        |            |           |          |         /
      +-------+---- Connector Workers (Python + Playwright / httpx) ----+
                    - chạy theo lịch (mỗi 1–4 giờ, hoặc đêm)
                    - lấy credential từ Secret Manager
                    - lưu file/JSON thô (raw) có mã hóa
                                  |
                     Chuẩn hóa → Schema chuẩn DMAG (PostgreSQL)
         clinic · branch · doctor · patient(hash) · lead_source · appointment
         visit · service · treatment_plan · invoice · payment(thu) · expense(chi)
         debt · commission
                                  |
                     Lớp KPI (SQL views / dbt) — định nghĩa 1 lần
                                  |
         Dashboard: Metabase/Superset nhúng (multi-tenant, RLS) hoặc web tự viết
         + báo cáo tự động gửi Zalo/Email cho chủ phòng khám
```

### Bộ KPI gợi ý (cần đối chiếu với dashboard dash.io.vn hiện tại)

- **Doanh thu:** doanh thu phát sinh, thực thu, công nợ phải thu, doanh thu theo dịch vụ, bác sĩ, chi nhánh, ghế.
- **Khách hàng:** khách mới, khách quay lại, tỷ lệ chốt (tư vấn → điều trị), giá trị trung bình mỗi khách và mỗi kế hoạch điều trị.
- **Lịch hẹn:** số lịch, tỷ lệ đến, hủy hoặc vắng; công suất ghế.
- **Marketing:** khách theo nguồn (Facebook, Zalo, giới thiệu, vãng lai…); chi phí trên mỗi khách nếu nhập thêm chi phí quảng cáo.
- **Tài chính:** thu chi, lợi nhuận gộp, hoa hồng bác sĩ, chi phí labo và vật tư.
- **So sánh:** cùng kỳ, theo tháng; xếp hạng giữa các phòng khám trong hệ thống DMAG.

### Về Odoo (theo tên repo)

- Odoo **không phải công cụ BI tốt**. Dashboard dạng spreadsheet là bản Enterprise và khó nhúng đa khách hàng.
- Nếu DMAG muốn Odoo làm "lõi" (CRM tư vấn, hợp đồng với phòng khám, nhập chi phí quảng cáo…), có hai cách:
  - Đổ schema chuẩn vào chính PostgreSQL của Odoo dưới dạng module `dmag_dental_data`.
  - Hoặc dùng database riêng và đồng bộ sang Odoo.
- Phần hiển thị vẫn nên dùng Metabase/Superset hoặc frontend riêng.

---

## 7. Lộ trình đề xuất

| Giai đoạn | Việc | Thời gian ước tính |
|---|---|---|
| 0 | Đổi mật khẩu, tách tài khoản; soạn mẫu thỏa thuận xử lý dữ liệu và ủy quyền; hỏi luật sư về điều kiện kinh doanh | 1–2 tuần |
| 0 | Liên hệ SimlyDent, VTTech, DentalFlow, Nextsoft xin chương trình đối tác API (docs, giá, giới hạn gọi) | song song |
| 1 | Thu thập mẫu file Excel báo cáo của Bambu và NK Số Plus; chốt schema chuẩn và danh sách KPI | 1–2 tuần |
| 2 | Connector Bambu (Playwright + parse Excel) và dashboard MVP cho 7 khách Bambu | 3–4 tuần |
| 3 | Connector Nha Khoa Số Plus (DB hoặc web), rồi SimlyDent (API) | 3–4 tuần |
| 4 | DentalFlow, VTTech; cảnh báo khi connector lỗi; báo cáo tự động qua Zalo | 2–3 tuần |

---

## 8. Câu hỏi còn mở / cần DMAG cung cấp

- **Ảnh chụp các trang** của dashboard dash.io.vn hiện tại, để trích danh sách KPI và bố cục.
- **Mẫu file Excel xuất từ Bambu và Nha Khoa Số Plus**, đã ẩn thông tin bệnh nhân.
- 5 khách Nha Khoa Số Plus dùng **bản web hay bản cài máy**?
- Thiên Hương dùng phần mềm gì? Kim Cương và Tân Tiến tô đỏ nghĩa là gì: ngừng hợp tác hay lỗi kết nối?
- DMAG có hợp đồng hoặc ủy quyền xử lý dữ liệu với các phòng khám chưa?

---

## Nguồn tham khảo chính

- Thị trường: [IMARC – Vietnam dental PMS](https://www.imarcgroup.com/report/vi/vietnam-dental-practice-management-software-market), [sannhakhoa top 9](https://sannhakhoa.vn/top-9-phan-mem-quan-ly-nha-khoa-duoc-nha-si-tin-tuong-hien-nay-post.28), [YouMed](https://youmed.vn/tin-tuc/phan-mem-quan-ly-nha-khoa/), [Magenest](https://magenest.com/vi/phan-mem-quan-ly-phong-kham-nha-khoa/)
- Bambu: [bambu.vn](https://bambu.vn/), [tính năng](https://bambu.vn/128/tinh-nang.html), [đa chi nhánh](https://bambu.vn/137/quan-ly-nhieu-chi-nhanh.html), [BambuFit doanh thu bác sĩ](https://bambufit.vn/quan-ly-doanh-thu-bac-si-id19.html)
- SimlyDent: [bảng giá](https://simlydent.vn/price), [kết nối](https://simlydent.vn/ket-noi), [quản lý chi nhánh / API](https://simlydent.vn/quan-ly-chi-nhanh), [docs](https://docs.simlydent.vn/)
- DentalFlow: [bảng giá](https://dentalflow.vn/bang-gia-phan-mem-dentalflow), [báo cáo doanh thu](https://dentalflow.vn/cau_hoi/bao-cao-doanh-thu), [mobile app / API](https://dentalflow.vn/mobile-app)
- Nha Khoa Số Plus: [nhakhoasoplus.net](https://www.nhakhoasoplus.net/), [Tracxn](https://tracxn.com/d/companies/nha-khoa-so-plus/__Va7jbikrKClV2VcN5X6PMEWLPJfGpkx3PqEkKcBBSuU)
- VTTech: [phần mềm nha khoa](https://vttechsolution.com/phan-mem-nha-khoa), [báo cáo](https://vttechsolution.com/chuc-nang/nha-khoa/bao-cao-nha-khoa), [tại sao chọn VTTech (API)](https://vttechsolution.com/tai-sao-chon-vttech)
- Pháp lý: [Luật BVDLCN – Bộ Công an](https://vanban.bocongan.gov.vn/co-so-du-lieu-van-ban/luat-bao-ve-du-lieu-ca-nhan-1753688803), [NĐ 356/2025 (LuatVietnam)](https://english.luatvietnam.vn/decree-no-356-2025-nd-cp-dated-december-31-2025-of-the-government-detailing-a-number-of-articles-and-measures-for-the-implementation-of-the-law-on-p-422896-doc1.html), [EY alert NĐ 356](https://www.ey.com/content/dam/ey-unified-site/ey-com/en-vn/technical/tax/documents/ey-vietnam-legal-alert-march-2026-decree-no356-2025-nd-cp-providing-detailed-guidance-for-implementation-of-personal-data-protection-law-eng.pdf), [Rouse](https://rouse.com/insights/news/2025/vietnam-s-new-personal-data-protection-law-what-businesses-need-to-know), [TT 13/2025/TT-BYT](https://luatvietnam.vn/y-te/thong-tu-13-2025-tt-byt-huong-dan-trien-khai-ho-so-benh-an-dien-tu-tu-bo-y-te-402396-d1.html)
