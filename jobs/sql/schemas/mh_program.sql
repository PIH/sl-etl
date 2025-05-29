create table mh_program
(
patient_program_id varchar(50),
patient_id varchar(50),  
emr_id varchar(255),
gender varchar(50),
age int,
assigned_chw text,
date_enrolled date,
date_completed date,
number_of_days_in_care int,
program_status_outcome varchar(500),
latest_diagnosis varchar(500),
latest_seizure_number int, 
latest_seizure_date date,
previous_seizure_number int,
previous_seizure_date date,
baseline_seizure_number int,
baseline_seizure_date date,
latest_medication_given varchar(500),
latest_medication_date date,
last_visit_date date,
next_scheduled_visit_date date,
three_months_since_latest_return_date varchar(50),
six_months_since_latest_return_date varchar(50),
index_asc int,
index_desc int
)
;
