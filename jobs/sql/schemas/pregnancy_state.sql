create table pregnancy_state
(
pregnancy_program_state_id varchar(30),  
emr_id                     varchar(50),  
patient_id                 varchar(30),  
pregnancy_program_id       varchar(30),  
state                      varchar(255), 
user_entered               varchar(255), 
date_entered               datetime,     
state_start_date           date,         
state_end_date             date,         
program_enrollment_date    datetime,     
program_completion_date    datetime,     
index_asc_patient          int,           
index_desc_patient         int,           
index_asc_patient_program  int,           
index_desc_patient_program int           
);
