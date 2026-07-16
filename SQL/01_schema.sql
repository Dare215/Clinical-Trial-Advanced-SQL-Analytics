-- Tables
CREATE TABLE sites(site_id SERIAL PRIMARY KEY, site_name TEXT);
CREATE TABLE patients(patient_id SERIAL PRIMARY KEY, site_id INT REFERENCES sites(site_id), treatment_arm TEXT, enrolled_date DATE);
CREATE TABLE visits(visit_id SERIAL PRIMARY KEY, patient_id INT REFERENCES patients(patient_id), visit_date DATE, visit_type TEXT);
CREATE TABLE adverse_events(ae_id SERIAL PRIMARY KEY, patient_id INT REFERENCES patients(patient_id), severity TEXT, event_date DATE);
