create table mh_program
(
emr_id varchar(255),
gender varchar(50),
age int,
assigned_chw text,
province varchar(500),
city_village varchar(500),
address3 varchar(500),
address1 varchar(500),
address2 varchar(500),
location_when_registered_in_program varchar(500),
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
six_months_since_latest_return_date varchar(50)
)
;