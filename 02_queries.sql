
-- ==========================================================
-- PROJECT: NoShowGuard
-- PART 2: SQL DATABASE ANALYSIS
-- DATABASE: noshowguard
-- ==========================================================


-- ==========================================================
-- TASK 2.1: DATABASE VALIDATION (4 MARKS)
-- ==========================================================

USE noshowguard;

-- Check total number of clinics
SELECT COUNT(*) AS total_clinics
FROM clinics;

-- Check total number of appointments
SELECT COUNT(*) AS total_appointments
FROM appointments;

-- Check total number of no-shows
SELECT SUM(no_show) AS total_no_shows
FROM appointments;

-- Results:
-- Clinics = 8
-- Appointments = 990
-- No-shows = 218


-- Check appointment ID uniqueness
SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT appointment_id) AS unique_appointment_ids
FROM appointments;


-- Duplicate primary key test
-- Execute this statement separately after loading the data.
-- It SHOULD fail with Error Code 1062.

-- INSERT INTO appointments
-- (appointment_id, patient_id, clinic_id)
-- VALUES ('A0001', 'P196', 'C05');


-- ==========================================================
-- TASK 2.2: NO-SHOW RATE BY CLINIC (5 MARKS)
-- ==========================================================

-- Query 1: Clinics with at least 95 appointments

SELECT
    c.clinic_name,
    c.city,
    COUNT(*) AS appointments,
    SUM(a.no_show) AS no_shows,
    ROUND(
        100.0 * SUM(a.no_show) / COUNT(*), 1
    ) AS no_show_pct

FROM appointments a

JOIN clinics c
    ON a.clinic_id = c.clinic_id

GROUP BY
    c.clinic_id,
    c.clinic_name,
    c.city

HAVING COUNT(*) >= 95

ORDER BY no_show_pct DESC;


-- Query 2: All 8 clinics (without HAVING)

SELECT
    c.clinic_name,
    c.city,
    COUNT(*) AS appointments,
    SUM(a.no_show) AS no_shows,
    ROUND(
        100.0 * SUM(a.no_show) / COUNT(*), 1
    ) AS no_show_pct

FROM appointments a

JOIN clinics c
    ON a.clinic_id = c.clinic_id

GROUP BY
    c.clinic_id,
    c.clinic_name,
    c.city

ORDER BY no_show_pct DESC;


-- ==========================================================
-- TASK 2.3: DOES BOOKING FAR AHEAD MATTER? (4 MARKS)
-- ==========================================================

SELECT

    CASE
        WHEN lead_days BETWEEN 1 AND 7 THEN '1-7'
        WHEN lead_days BETWEEN 8 AND 14 THEN '8-14'
        WHEN lead_days BETWEEN 15 AND 30 THEN '15-30'
        ELSE '31+'
    END AS lead_band,

    COUNT(*) AS appointments,

    SUM(no_show) AS no_shows,

    ROUND(
        100.0 * SUM(no_show) / COUNT(*), 1
    ) AS no_show_pct

FROM appointments

GROUP BY lead_band

ORDER BY MIN(lead_days);


-- ==========================================================
-- TASK 2.4: MONTH-BY-MONTH TREND (4 MARKS)
-- ==========================================================

WITH monthly AS (

    SELECT

        SUBSTR(appt_date, 1, 7) AS month,

        COUNT(*) AS appointments,

        ROUND(
            100.0 * SUM(no_show) / COUNT(*), 1
        ) AS no_show_pct

    FROM appointments

    GROUP BY SUBSTR(appt_date, 1, 7)

),

monthly_comparison AS (

    SELECT

        month,
        appointments,
        no_show_pct,

        LAG(no_show_pct) OVER (
            ORDER BY month
        ) AS previous_month_rate

    FROM monthly

)

SELECT

    month,
    appointments,
    no_show_pct,

    ROUND(
        no_show_pct - previous_month_rate, 1
    ) AS change_percentage_points

FROM monthly_comparison

ORDER BY month;


-- ==========================================================
-- TASK 2.5: RANK CLINICS INSIDE EACH CITY (5 MARKS)
-- ==========================================================

WITH clinic_rates AS (

    SELECT

        c.clinic_id,
        c.clinic_name,
        c.city,

        ROUND(
            100.0 * SUM(a.no_show) / COUNT(*), 1
        ) AS no_show_pct

    FROM clinics c

    JOIN appointments a
        ON c.clinic_id = a.clinic_id

    GROUP BY
        c.clinic_id,
        c.clinic_name,
        c.city

)

SELECT

    clinic_name,
    city,
    no_show_pct,

    RANK() OVER (
        PARTITION BY city
        ORDER BY no_show_pct DESC
    ) AS rank_in_city,

    CASE

        WHEN no_show_pct > (
            SELECT
                100.0 * SUM(no_show) / COUNT(*)
            FROM appointments
        )
        THEN 'above'

        WHEN no_show_pct < (
            SELECT
                100.0 * SUM(no_show) / COUNT(*)
            FROM appointments
        )
        THEN 'below'

        ELSE 'equal'

    END AS vs_overall

FROM clinic_rates

ORDER BY
    city,
    rank_in_city;

