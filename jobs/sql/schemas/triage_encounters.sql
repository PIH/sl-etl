create table triage_encounters
(
wellbody_emr_id          varchar(50),  
kgh_emr_id               varchar(50),  
encounter_id             varchar(100), 
visit_id                 varchar(100), 
loc_registered           varchar(255), 
unknown_patient          varchar(255), 
ED_Visit_Start_Datetime  datetime,     
encounter_datetime       datetime,     
encounter_location       text,         
provider                 varchar(255), 
date_entered             date,         
created_by               varchar(255), 
Triage_queue_status      varchar(255), 
Triage_Color             varchar(255), 
Triage_Score             int,          
Chief_Complaint          text,         
Weight_KG                float,        
Emergency_signs          varchar(255), 
Mobility                 varchar(255), 
Respiratory_Rate         float,        
Blood_Oxygen_Saturation  float,        
Pulse                    float,        
Systolic_Blood_Pressure  float,        
Diastolic_Blood_Pressure float,        
Temperature_C            float,        
Response                 varchar(255), 
Trauma_Present           varchar(255), 
signs_of_shock           varchar(255), 
dehydration              varchar(255), 
Neurological             varchar(255), 
Burn                     varchar(255), 
Glucose                  varchar(255), 
Trauma_type              varchar(255), 
Digestive                varchar(255), 
Pregnancy                varchar(255), 
Respiratory              varchar(255), 
Pain                     varchar(255), 
Other_Symptom            varchar(255), 
Clinical_Impression      varchar(255), 
Pregnancy_Test           varchar(255), 
Glucose_Value            float,
Referral_Destination     varchar(255)
);