create table all_checkins (
encounter_id       varchar(50),  
patient_id         varchar(50),  
visit_id           varchar(50),  
emr_id             varchar(50),  
encounter_type     varchar(255), 
encounter_location varchar(255), 
provider           text,         
encounter_datetime datetime,     
datetime_entered   datetime,     
user_entered       text,         
type_of_visit      varchar(255), 
refer_to_mcoe      bit,          
index_asc          int,          
index_desc         int           
);
