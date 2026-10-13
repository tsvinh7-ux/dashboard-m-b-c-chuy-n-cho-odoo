-- Mô hình dữ liệu chuẩn DMAG (PostgreSQL)
-- Mọi connector (Bambu, Nha Khoa Số Plus, SimlyDent, DentalFlow, VTTech, upload Excel)
-- đều ánh xạ dữ liệu về các bảng dưới đây. KPI chỉ tính trên các bảng này.
--
-- Nguyên tắc:
--   * Mỗi dòng có (clinic_id, source_system, source_id) để truy ngược về bản ghi gốc và upsert khi đồng bộ lại.
--   * Không lưu tên, số điện thoại hay chẩn đoán của bệnh nhân: chỉ lưu mã đã băm (patient_key).
--   * Tiền lưu bằng VND, kiểu BIGINT.

CREATE SCHEMA IF NOT EXISTS dmag;

CREATE TABLE dmag.clinic (
    clinic_id      SERIAL PRIMARY KEY,
    name           TEXT NOT NULL,
    city           TEXT,
    source_system  TEXT NOT NULL CHECK (source_system IN ('bambu', 'nhakhoasoplus', 'simlydent', 'dentalflow', 'vttech', 'excel')),
    source_url     TEXT,                        -- vd. https://<ten>.bambu.vn
    sync_method    TEXT NOT NULL CHECK (sync_method IN ('api', 'db', 'browser_excel', 'browser_html', 'manual_upload')),
    secret_ref     TEXT,                        -- khóa tham chiếu tới Secret Manager, KHÔNG lưu mật khẩu ở đây
    active         BOOLEAN NOT NULL DEFAULT TRUE,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE dmag.branch (
    branch_id      SERIAL PRIMARY KEY,
    clinic_id      INT NOT NULL REFERENCES dmag.clinic,
    source_id      TEXT NOT NULL,
    name           TEXT NOT NULL,
    chairs         INT,
    UNIQUE (clinic_id, source_id)
);

CREATE TABLE dmag.doctor (
    doctor_id      SERIAL PRIMARY KEY,
    clinic_id      INT NOT NULL REFERENCES dmag.clinic,
    source_id      TEXT NOT NULL,
    name           TEXT NOT NULL,
    commission_rate NUMERIC(5, 4),              -- vd. 0.1000 = 10%
    UNIQUE (clinic_id, source_id)
);

-- Danh mục nguồn khách và dịch vụ chuẩn của DMAG; mỗi phòng khám ánh xạ tên riêng của họ về đây.
CREATE TABLE dmag.lead_source (
    source_code    TEXT PRIMARY KEY,            -- facebook, tiktok, google, zalo, referral, walk_in, other
    name           TEXT NOT NULL,
    is_paid        BOOLEAN NOT NULL
);

CREATE TABLE dmag.service_group (
    service_code   TEXT PRIMARY KEY,            -- exam, scaling, filling, extraction, endo, whitening, crown, ortho, implant, other
    name           TEXT NOT NULL,
    uses_lab       BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE dmag.mapping (
    clinic_id      INT NOT NULL REFERENCES dmag.clinic,
    kind           TEXT NOT NULL CHECK (kind IN ('lead_source', 'service', 'expense_category', 'payment_method')),
    source_value   TEXT NOT NULL,               -- giá trị gốc trong phần mềm của phòng khám
    target_code    TEXT NOT NULL,
    PRIMARY KEY (clinic_id, kind, source_value)
);

CREATE TABLE dmag.patient (
    patient_key    TEXT NOT NULL,               -- sha256(clinic_id || source_id || salt)
    clinic_id      INT NOT NULL REFERENCES dmag.clinic,
    first_visit_date DATE,
    source_code    TEXT REFERENCES dmag.lead_source,
    birth_year     SMALLINT,
    gender         CHAR(1),
    PRIMARY KEY (clinic_id, patient_key)
);

CREATE TABLE dmag.lead_daily (                -- lead và chi phí quảng cáo theo ngày
    clinic_id      INT NOT NULL REFERENCES dmag.clinic,
    day            DATE NOT NULL,
    source_code    TEXT NOT NULL REFERENCES dmag.lead_source,
    leads          INT NOT NULL DEFAULT 0,
    ad_spend       BIGINT NOT NULL DEFAULT 0,
    PRIMARY KEY (clinic_id, day, source_code)
);

CREATE TABLE dmag.appointment (
    clinic_id      INT NOT NULL REFERENCES dmag.clinic,
    source_id      TEXT NOT NULL,
    branch_id      INT REFERENCES dmag.branch,
    doctor_id      INT REFERENCES dmag.doctor,
    patient_key    TEXT,
    scheduled_at   TIMESTAMP NOT NULL,
    status         TEXT NOT NULL CHECK (status IN ('arrived', 'cancelled', 'no_show', 'booked')),
    is_new_patient BOOLEAN NOT NULL,
    source_code    TEXT REFERENCES dmag.lead_source,
    consulted      BOOLEAN NOT NULL DEFAULT FALSE,
    accepted_treatment BOOLEAN NOT NULL DEFAULT FALSE,   -- khách mới đồng ý điều trị (chốt)
    PRIMARY KEY (clinic_id, source_id)
);

CREATE TABLE dmag.invoice_line (               -- doanh thu phát sinh
    clinic_id      INT NOT NULL REFERENCES dmag.clinic,
    source_id      TEXT NOT NULL,
    branch_id      INT REFERENCES dmag.branch,
    doctor_id      INT REFERENCES dmag.doctor,
    patient_key    TEXT,
    service_date   DATE NOT NULL,
    service_code   TEXT NOT NULL REFERENCES dmag.service_group,
    service_name_raw TEXT,
    quantity       NUMERIC(10, 2) NOT NULL DEFAULT 1,
    amount         BIGINT NOT NULL,              -- sau giảm giá
    discount       BIGINT NOT NULL DEFAULT 0,
    PRIMARY KEY (clinic_id, source_id)
);

CREATE TABLE dmag.payment (                    -- phiếu thu (thực thu)
    clinic_id      INT NOT NULL REFERENCES dmag.clinic,
    source_id      TEXT NOT NULL,
    branch_id      INT REFERENCES dmag.branch,
    patient_key    TEXT,
    paid_at        TIMESTAMP NOT NULL,
    amount         BIGINT NOT NULL,
    method         TEXT NOT NULL CHECK (method IN ('bank_transfer', 'cash', 'card', 'installment', 'other')),
    invoice_source_id TEXT,                      -- nếu phần mềm nguồn có liên kết với hóa đơn
    PRIMARY KEY (clinic_id, source_id)
);

CREATE TABLE dmag.expense (                    -- phiếu chi
    clinic_id      INT NOT NULL REFERENCES dmag.clinic,
    source_id      TEXT NOT NULL,
    branch_id      INT REFERENCES dmag.branch,
    spent_on       DATE NOT NULL,
    category       TEXT NOT NULL CHECK (category IN ('payroll', 'rent', 'supplies', 'lab', 'marketing', 'utilities_other')),
    amount         BIGINT NOT NULL,
    allocate_monthly BOOLEAN NOT NULL DEFAULT FALSE,   -- TRUE: phân bổ đều theo ngày trong tháng khi báo cáo
    PRIMARY KEY (clinic_id, source_id)
);

CREATE TABLE dmag.sync_run (                   -- nhật ký đồng bộ, hiển thị ở trang "Kết nối dữ liệu"
    run_id         BIGSERIAL PRIMARY KEY,
    clinic_id      INT NOT NULL REFERENCES dmag.clinic,
    started_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    finished_at    TIMESTAMPTZ,
    status         TEXT NOT NULL CHECK (status IN ('running', 'ok', 'warning', 'error')),
    message        TEXT,
    rows_upserted  INT,
    raw_object_key TEXT                          -- vị trí file/JSON gốc đã mã hóa
);

-- ===== Ví dụ một KPI: các chỉ số chính theo ngày =====
CREATE VIEW dmag.kpi_daily AS
WITH rev AS (
    SELECT clinic_id, service_date AS day, SUM(amount) AS revenue, COUNT(*) AS lines
    FROM dmag.invoice_line GROUP BY 1, 2
), pay AS (
    SELECT clinic_id, paid_at::date AS day, SUM(amount) AS collected
    FROM dmag.payment GROUP BY 1, 2
), appt AS (
    SELECT clinic_id, scheduled_at::date AS day,
           COUNT(*) FILTER (WHERE status <> 'booked')                         AS appointments,
           COUNT(*) FILTER (WHERE status = 'arrived')                         AS arrived,
           COUNT(*) FILTER (WHERE status = 'arrived' AND is_new_patient)      AS new_patients,
           COUNT(*) FILTER (WHERE accepted_treatment)                         AS accepted
    FROM dmag.appointment GROUP BY 1, 2
)
SELECT COALESCE(r.clinic_id, p.clinic_id, a.clinic_id) AS clinic_id,
       COALESCE(r.day, p.day, a.day)                   AS day,
       COALESCE(r.revenue, 0)      AS revenue,
       COALESCE(p.collected, 0)    AS collected,
       COALESCE(a.appointments, 0) AS appointments,
       COALESCE(a.arrived, 0)      AS arrived,
       COALESCE(a.new_patients, 0) AS new_patients,
       COALESCE(a.accepted, 0)     AS accepted
FROM rev r
FULL JOIN pay p  ON p.clinic_id = r.clinic_id AND p.day = r.day
FULL JOIN appt a ON a.clinic_id = COALESCE(r.clinic_id, p.clinic_id) AND a.day = COALESCE(r.day, p.day);
-- Tỷ lệ chốt = SUM(accepted) / SUM(new_patients); tỷ lệ đến hẹn = SUM(arrived) / SUM(appointments)
-- (tính trên tổng của kỳ, không lấy trung bình các tỷ lệ theo ngày).
