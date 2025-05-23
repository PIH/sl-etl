SET @locale = GLOBAL_PROPERTY_VALUE('default_locale', 'en');
SET sql_safe_updates = 0;

set @partition = '${partitionNum}';

SELECT order_type_id INTO @testOrder FROM order_type WHERE uuid = '52a447d3-a64a-11e3-9aeb-50e549534c5e';
SELECT encounter_type_id INTO @specimenCollEnc FROM encounter_type WHERE uuid = '39C09928-0CAB-4DBA-8E48-39C631FA4286';

DROP TEMPORARY TABLE IF EXISTS temp_report;
CREATE TEMPORARY TABLE temp_report
(
 patient_id                   INT,           
 emr_id                       varchar(50),   
 wellbody_emr_id              VARCHAR(255),  
 kgh_emr_id                   VARCHAR(255),  
 specimen_encounter_id        INT,           
 order_encounter_id           INT,           
 order_visit_id               INT,           
 loc_registered               VARCHAR(255), 
 creator                      INT(11),
 user_entered                 TEXT,
 unknown_patient              CHAR(1),       
 gender                       CHAR(1),       
 age_at_encounter             INT,           
 patient_address              VARCHAR(1000), 
 order_number                 VARCHAR(255),  
 accession_number             VARCHAR(255),  
 order_concept_id             INT,           
 orderable                    VARCHAR(255),  
 status                       VARCHAR(255),  
 orderer_provider_type        VARCHAR(255),  
 order_datetime               DATETIME,      
 date_stopped                 DATETIME,      
 auto_expire_date             DATETIME,      
 fulfiller_status             VARCHAR(255),  
 ordering_location            VARCHAR(255),  
 urgency                      VARCHAR(255),  
 specimen_collection_datetime DATETIME,      
 collection_date_estimated    VARCHAR(255),  
 test_location                VARCHAR(255),  
 results_date                 DATETIME,    
 index_asc                    INT,
 index_desc                   INT 
 );

-- load temporary table with all lab test orders within the date range 
INSERT INTO temp_report (
    patient_id,
    order_number,
    accession_number,
    order_concept_id,
    order_encounter_id,
    order_datetime,
    date_stopped,
    creator,
    auto_expire_date,
    fulfiller_status,
    urgency
)
SELECT
    o.patient_id,
    o.order_number,
    o.accession_number,
    o.concept_id,
    o.encounter_id,
    o.date_activated,
    o.date_stopped,
    o.creator,
    o.auto_expire_date,
    o.fulfiller_status,
     o.urgency
FROM
    orders o
WHERE o.order_type_id =@testOrder
      AND order_action = 'NEW';

-- REMOVE TEST PATIENTS
DELETE
FROM temp_report
WHERE patient_id IN
      (
          SELECT a.person_id
          FROM person_attribute a
          INNER JOIN person_attribute_type t ON a.person_attribute_type_id = t.person_attribute_type_id
          WHERE a.value = 'true'
          AND t.name = 'Test Patient'
      );

update temp_report r 
inner join encounter e on e.encounter_id = r.order_encounter_id
set r.order_visit_id = e.visit_id;
      
-- To join in the specimen encounters, a temporary table is created with all lab specimen encounters within the date range is loaded.
-- This table is indexed and then joined with the main report temp table
DROP TEMPORARY TABLE IF EXISTS temp_spec;
CREATE TEMPORARY TABLE temp_spec
(
    specimen_encounter_id INT,
    visit_id INT,
    order_number   VARCHAR(255) 
   );      

CREATE  INDEX order_number ON temp_spec(order_number);

INSERT INTO temp_spec (
    specimen_encounter_id,
    visit_id,
    order_number
)
SELECT
    e.encounter_id,
    e.visit_id, 
    o.value_text
FROM
    encounter e
    INNER JOIN obs o ON o.encounter_id = e.encounter_id AND o.voided = 0 AND o.concept_id =  CONCEPT_FROM_MAPPING('PIH','10781')
WHERE e.encounter_type = @specimenCollEnc
      AND e.voided = 0;

UPDATE temp_report t
  LEFT OUTER JOIN temp_spec ts ON ts.order_number = t.order_number 
  SET  t.specimen_encounter_id = ts.specimen_encounter_id;


DROP TABLE IF EXISTS dist_patients;
CREATE TEMPORARY TABLE dist_patients (
patient_id      int,           
emr_id          varchar(50),  
wellbody_emr_id VARCHAR(255), 
kgh_emr_id      VARCHAR(255), 
gender          varchar(20),  
loc_registered  VARCHAR(255), 
unknown_patient char(1),      
patient_address varchar(1000) 
);

create index dist_patients_pi on dist_patients(patient_id);

INSERT INTO dist_patients(patient_id)
SELECT DISTINCT patient_id FROM temp_report;

-- Individual columns are populated here:
UPDATE dist_patients dp
SET dp.emr_id = primary_emr_id(patient_id);

UPDATE dist_patients dp
SET dp.wellbody_emr_id= patient_identifier(patient_id,'1a2acce0-7426-11e5-a837-0800200c9a66');

UPDATE dist_patients dp
SET dp.kgh_emr_id= patient_identifier(patient_id,'c09a1d24-7162-11eb-8aa6-0242ac110002');

UPDATE dist_patients SET gender = GENDER(patient_id);
UPDATE dist_patients SET loc_registered = LOC_REGISTERED(patient_id);
UPDATE dist_patients SET unknown_patient = IF(UNKNOWN_PATIENT(patient_id) IS NULL,NULL,'1'); 
UPDATE dist_patients SET patient_address = PERSON_ADDRESS(patient_id);

UPDATE temp_report tr
LEFT OUTER JOIN dist_patients dp ON tr.patient_id=dp.patient_id
SET 
tr.emr_id = dp.emr_id,
tr.wellbody_emr_id=dp.wellbody_emr_id,
tr.kgh_emr_id=dp.kgh_emr_id,
tr.gender=dp.gender,
tr.loc_registered=dp.loc_registered,
tr.unknown_patient=dp.unknown_patient,
tr.patient_address=dp.patient_address;

UPDATE temp_report SET age_at_encounter = AGE_AT_ENC(patient_id,order_encounter_id);
UPDATE temp_report SET orderable = IFNULL(CONCEPT_NAME(order_concept_id, @locale),CONCEPT_NAME(order_concept_id, 'en'));
-- status is derived by the order fulfiller status and other fields
UPDATE temp_report t SET status =
    CASE
       WHEN t.date_stopped IS NOT NULL AND specimen_encounter_id IS NULL THEN 'Cancelled'
       WHEN t.auto_expire_date < CURDATE() AND specimen_encounter_id IS NULL THEN 'Expired'
       WHEN t.fulfiller_status = 'COMPLETED' THEN 'Reported'
       WHEN t.fulfiller_status = 'IN_PROGRESS' THEN 'Collected'
       WHEN t.fulfiller_status = 'EXCEPTION' THEN 'Not Performed'
       ELSE 'Ordered'
    END ;

UPDATE temp_report t SET orderer_provider_type = PROVIDER_TYPE(t.order_encounter_id);
UPDATE temp_report t SET ordering_location = ENCOUNTER_LOCATION_NAME(t.order_encounter_id);

update temp_report t
set user_entered = person_name_of_user(creator);

update temp_report t
  inner join encounter e on e.encounter_id = t.specimen_encounter_id
set t.specimen_collection_datetime = e.encounter_datetime;

update temp_report t 
  inner join obs o on o.encounter_id = t.specimen_encounter_id and o.voided  = 0 
    and o.concept_id = concept_from_mapping('PIH','11791')
set test_location = concept_name(o.value_coded, @locale);
 
update temp_report t 
  inner join obs o on o.encounter_id = t.specimen_encounter_id and o.voided  = 0 
    and o.concept_id = concept_from_mapping('PIH','Date of test results')
set results_date = o.value_datetime;

update temp_report t 
  inner join obs o on o.encounter_id = t.specimen_encounter_id and o.voided  = 0 
    and o.concept_id = concept_from_mapping('PIH','11781')
set collection_date_estimated = concept_name(o.value_coded, @locale);

-- final output
SELECT 
concat(@partition,"-",patient_id)  patient_id,
emr_id, 
wellbody_emr_id    ,
kgh_emr_id,
concat(@partition,"-",order_visit_id) order_visit_id,
concat(@partition,"-",order_encounter_id)  order_encounter_id,
loc_registered,
unknown_patient, 
gender, 
age_at_encounter,
patient_address,
order_number,
accession_number "Lab_ID",
orderable,
status,
user_entered,
orderer_provider_type,
order_datetime,
ordering_location,
urgency,
specimen_collection_datetime,
collection_date_estimated,
test_location,
results_date,
index_asc,
index_desc
FROM temp_report;
