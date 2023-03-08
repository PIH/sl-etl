CREATE TABLE all_patients
(
wellbody_emr_id varchar(50),
kgh_emr_id varchar(50),
emr_id varchar(50),
patient_id varchar(100), 
reg_location varchar(50),
date_registration_entered date,
user_entered varchar(50),
fist_encounter_date date,
last_encounter_date date, 
name varchar(50),
family_name varchar(50),
dob date,
dob_estimated bit,
gender varchar(2),
dead bit,
death_date date,
cause_of_death varchar(100)
);