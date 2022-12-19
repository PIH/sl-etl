CREATE TABLE all_patients
(
wellbody_emr_id varchar(50),
kgh_emr_id varchar(50),
patient_id int, 
reg_location varchar(50),
reg_date date,
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