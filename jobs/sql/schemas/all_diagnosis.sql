create table all_diagnosis
(
patient_id varchar(100),
emr_id varchar(50),
loc_registered varchar(255),
unknown_patient varchar(50),
gender varchar(50),
age_at_encounter int,
department varchar(255),
locality varchar(255),
encounter_id int,
encounter_location varchar(255),
obs_id int,
obs_datetime datetime,
user_entered varchar(255),
provider varchar(255),
diagnosis_entered text,
dx_order varchar(255),
certainty varchar(255),
coded varchar(255),
diagnosis_concept int,
diagnosis_coded_fr varchar(255),
icd10_code varchar(255),
notifiable int,
urgent int,
womens_health int,
psychological int,
pediatric int,
outpatient int,
ncd int,
non_diagnosis int,
ed int,
age_restricted int,
oncology int,
date_entered datetime,
retrospective int,
visit_id int,
birthdate datetime,
birthdate_estimated bit,
encounter_type varchar(255)
);
