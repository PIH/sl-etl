 create table mother_newborn_relationship
(
 relationship_id     int,          
 emr_id              varchar(255), 
 patient_id          int,          
 emr_id_mother       varchar(255),  
 patient_id_mother   int,          
 relationship_source varchar(255),  
 user_entered        text,          
 date_created        datetime,      
 index_asc           int,           
 index_desc          int           
); 
