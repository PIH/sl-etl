 create table mother_child_relationship
(
 relationship_id                    varchar(100),           
 emr_id                             varchar(255),  
 patient_id                         varchar(100),           
 emr_id_mother                      varchar(255),  
 patient_id_mother                  varchar(100),           
 relationship_source                varchar(255),  
 user_entered                       text,          
 datetime_entered                   datetime,      
 child_age_at_relationship_creation float,         
 child_age_current                  float                 
); 
