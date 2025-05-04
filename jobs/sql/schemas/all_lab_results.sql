CREATE TABLE all_lab_results
(
 lab_results_id           VARCHAR(100),
 patient_id               VARCHAR(100), 
 emr_id                   VARCHAR(50),
 wellbody_emr_id          VARCHAR(255), 
 kgh_emr_id               VARCHAR(255), 
 loc_registered           VARCHAR(255), 
 encounter_location       VARCHAR(255),
 user_entered             TEXT,
 unknown_patient          VARCHAR(50),  
 gender                   VARCHAR(50),  
 age_at_encounter         INT,          
 encounter_id             VARCHAR(25), 
 visit_id                 VARCHAR(25),
 order_number             VARCHAR(50), 
 orderable                VARCHAR(255), 
 test                     VARCHAR(255), 
 lab_id                   VARCHAR(255),   
 LOINC                    VARCHAR(255),   
 specimen_collection_date DATETIME,     
 results_date             DATETIME,     
 results_entry_date       DATETIME,     
 result                   VARCHAR(255), 
 units                    VARCHAR(255), 
 reason_not_performed     TEXT          
);
 
