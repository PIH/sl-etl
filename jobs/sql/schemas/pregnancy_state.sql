create table pregnancy_state
(
pregnancy_program_state_id varchar(30),
emr_id varchar(50),
patient_id varchar(30),
pregnancy_program_id varchar(30),
state varchar(255),
user_entered varchar(255),
date_entered datetime,
state_start_date datetime,
state_end_date datetime,
program_enrollment_date datetime,
program_completion_date datetime,
index_asc int,
index_desc int
);
