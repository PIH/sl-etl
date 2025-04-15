create table data_warnings
(
data_warning_id    int,          
warning_type       varchar(255), 
event_type         varchar(255), 
event_datetime     datetime,
patient_id         varchar(50),  
emr_id             varchar(50),  
visit_id           varchar(50),
encounter_id       varchar(50),  
patient_program_id varchar(50),  
encounter_datetime datetime,     
datetime_created   datetime,
visit_date_started datetime,
visit_date_stopped datetime,
user_entered       text,         
other_details      text         
);
