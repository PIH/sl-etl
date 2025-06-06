create table all_encounters
(
encounter_id varchar(100),
patient_id varchar(100),
visit_id varchar(100),
wellbody_emr_id varchar(50),
kgh_emr_id varchar(50),
emr_id varchar(50),
encounter_type varchar(50),
encounter_type_id int,
encounter_location varchar(255),
provider varchar(50),
encounter_datetime datetime,
datetime_entered datetime,
user_entered varchar(30),
index_asc int, 
index_desc int
);
