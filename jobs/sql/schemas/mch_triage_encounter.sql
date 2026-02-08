CREATE TABLE mch_triage_encounter
(
encounter_id                       varchar(50), 
patient_id                         varchar(50), 
visit_id                           varchar(50), 
emr_id                             varchar(50),  
encounter_datetime                 datetime,     
encounter_location                 varchar(255), 
datetime_entered                   datetime,     
user_entered                       text,         
provider                           text,         
age_at_encounter                   int,          
referral_form_received             bit,          
referral_from                      varchar(255), 
referral_datetime                  datetime,     
method_of_transport                varchar(255), 
disposition                        varchar(255), 
admission_location                 varchar(255)
);
