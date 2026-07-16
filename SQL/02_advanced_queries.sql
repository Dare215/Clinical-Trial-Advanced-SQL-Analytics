-- Site ranking
SELECT site_id,
COUNT(*) patients,
RANK() OVER(ORDER BY COUNT(*) DESC) site_rank
FROM patients
GROUP BY site_id;

-- Rolling enrollment
SELECT enrolled_date,
COUNT(*) enrollments,
SUM(COUNT(*)) OVER(ORDER BY enrolled_date) cumulative_enrollment
FROM patients
GROUP BY enrolled_date;

-- Patient retention
WITH visits_per_patient AS(
SELECT patient_id, COUNT(*) visit_count
FROM visits
GROUP BY patient_id)
SELECT * FROM visits_per_patient;

-- Adverse event frequency
SELECT severity,
COUNT(*) events,
DENSE_RANK() OVER(ORDER BY COUNT(*) DESC) severity_rank
FROM adverse_events
GROUP BY severity;

-- Site quartiles
SELECT site_id,
COUNT(*) patient_count,
NTILE(4) OVER(ORDER BY COUNT(*) DESC) performance_quartile
FROM patients
GROUP BY site_id;
