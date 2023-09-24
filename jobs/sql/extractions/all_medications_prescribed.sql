
SELECT patient_identifier_type_id INTO @identifier_type FROM patient_identifier_type pit WHERE uuid ='1a2acce0-7426-11e5-a837-0800200c9a66';
SELECT patient_identifier_type_id INTO @kgh_identifier_type FROM patient_identifier_type pit WHERE uuid ='c09a1d24-7162-11eb-8aa6-0242ac110002';
SELECT encounter_type_id INTO @anc_intake_enc FROM encounter_type et WHERE uuid ='00e5e810-90ec-11e8-9eb6-529269fb1459';
SELECT encounter_type_id INTO @anc_followup_enc FROM encounter_type et WHERE uuid ='00e5e946-90ec-11e8-9eb6-529269fb1459';
SELECT encounter_type_id INTO @outpat_init_enc FROM encounter_type et WHERE uuid ='7d5853d4-67b7-4742-8492-fcf860690ed5';
SELECT encounter_type_id INTO @outpat_followup_enc FROM encounter_type et WHERE uuid ='d8a038b5-90d2-43dc-b94b-8338b76674f3';
SELECT encounter_type_id INTO @mch_delivery_enc FROM encounter_type et WHERE uuid ='00e5ebb2-90ec-11e8-9eb6-529269fb1459';
SELECT encounter_type_id INTO @mh_consult_enc FROM encounter_type et WHERE uuid ='a8584ab8-cc2a-11e5-9956-625662870761';
SELECT encounter_type_id INTO @mh_followup_enc FROM encounter_type et WHERE uuid ='9d701a81-bb83-40ea-9efc-af50f05575f2';
SELECT encounter_type_id INTO @ncd_init_enc FROM encounter_type et WHERE uuid ='ae06d311-1866-455b-8a64-126a9bd74171';

DROP TABLE IF EXISTS all_medication_prescribed;
CREATE TABLE all_medication_prescribed
(
patient_id int, 
obs_group_id int,
kgh_emr_id varchar(25),
wellbody_emr_id varchar(25),
order_type varchar(30),
encounter_id int,
visit_id int,
order_id int,
order_location varchar(255),
order_created_date date,
order_date_activated date,
user_entered varchar(255),
prescriber varchar(255),
order_drug varchar(255),
order_formulation text,
order_formulation_non_coded text,
product_code varchar(50),
order_quantity int,
order_quantity_units varchar(50),
order_quantity_num_refills int,
order_dose int,
order_dose_unit varchar(50),
order_dosing_instructions text,
order_route varchar(50),
order_frequency varchar(50),
order_duration int,
order_duration_units varchar(50),
order_reason text,
order_comments text
); 

DROP TABLE IF EXISTS temp_encounter;
CREATE TEMPORARY TABLE temp_encounter AS 
SELECT patient_id, encounter_id, encounter_datetime, encounter_type 
FROM encounter e 
WHERE e.encounter_type IN (
@anc_intake_enc,
@anc_followup_enc,
@outpat_init_enc ,
@outpat_followup_enc,
@mch_delivery_enc,
@mh_consult_enc,
@mh_followup_enc,
@ncd_init_enc
)
AND e.voided =0;

create index temp_encounter_ci1 on temp_encounter(encounter_id);

DROP TABLE IF EXISTS temp_obs;
CREATE TEMPORARY TABLE temp_obs AS 
SELECT o.person_id, o.obs_id , o.obs_group_id , o.obs_datetime ,o.date_created , o.encounter_id, o.value_coded, o.concept_id, o.value_numeric , o.voided ,o.value_drug 
FROM temp_encounter te  INNER JOIN  obs o ON te.encounter_id=o.encounter_id 
WHERE o.voided =0;

create index temp_obs_ci1 on temp_obs(obs_group_id);
create index temp_obs_ci2 on temp_obs(obs_group_id,concept_id);

INSERT INTO all_medication_prescribed(order_type,patient_id,encounter_id,visit_id,obs_group_id,order_created_date)
SELECT 
DISTINCT
'Old Form' AS order_type,
patient_id,
e.encounter_id,
e.encounter_id AS visit_id, 
o.obs_id AS obs_group_id,
date(e.encounter_datetime) AS order_created_date
FROM temp_encounter e INNER JOIN temp_obs o ON e.encounter_id=o.encounter_id
WHERE o.concept_id=concept_from_mapping('PIH','10742');

UPDATE all_medication_prescribed SET user_entered=encounter_creator(encounter_id);

UPDATE  all_medication_prescribed tgt
INNER JOIN temp_obs o ON o.obs_group_id= tgt.obs_group_id   
and o.concept_id = concept_from_mapping('PIH','1282')
SET order_drug= concept_name(value_coded, 'en'),
product_code =  openboxesCode(o.value_drug) ;

UPDATE  all_medication_prescribed tgt  
INNER JOIN temp_obs o ON o.obs_group_id= tgt.obs_group_id   
and o.concept_id = concept_from_mapping('PIH','10744')
SET order_dose_unit= concept_name(value_coded, 'en'); -- 1 MINUTE

-- ------ Order Frequency (order_frequency)

UPDATE  all_medication_prescribed tgt  
INNER JOIN temp_obs o ON o.obs_group_id= tgt.obs_group_id   
and o.concept_id = concept_from_mapping('PIH','9363')
SET order_frequency= concept_name(value_coded, 'en');

-- ------ Order Duration (order_duration)

UPDATE  all_medication_prescribed tgt  
INNER JOIN temp_obs o ON o.obs_group_id= tgt.obs_group_id   
and o.concept_id = concept_from_mapping('PIH','9075')
SET order_duration= value_numeric;

-- ------ order_duration_units

UPDATE  all_medication_prescribed tgt  
INNER JOIN temp_obs o ON o.obs_group_id= tgt.obs_group_id   
and o.concept_id = concept_from_mapping('PIH','6412')
SET order_duration_units= concept_name(value_coded, 'en');

-- ------ order_quantity

UPDATE  all_medication_prescribed tgt  
INNER JOIN temp_obs o ON o.obs_group_id= tgt.obs_group_id   
and o.concept_id = concept_from_mapping('PIH','9073')
SET order_quantity = value_numeric;

-- ------ 
SELECT order_type_id INTO @order_type_id FROM order_type ot WHERE uuid ='131168f4-15f5-102d-96e4-000c29c2a5d7';


INSERT INTO all_medication_prescribed(order_type,patient_id,encounter_id,visit_id,order_id,order_created_date,order_date_activated,user_entered,prescriber,
									 order_drug,product_code,order_quantity,order_quantity_units,order_quantity_num_refills,
									 order_dose,order_dose_unit,order_dosing_instructions,order_route,order_frequency,
									 order_duration,order_duration_units,order_reason,order_comments)	
SELECT
'New Orders' AS order_type,
o.patient_id,
o.encounter_id,
o.encounter_id AS visit_id,
o.order_id,
o.date_created AS order_created_date,
o.date_activated AS order_date_activated, 
cu.username AS user_entered,
ou.username AS prescriber,
drugName(do.drug_inventory_id) AS order_drug,
-- order_formulation, -- 
-- order_formulation_non_coded, -- 
openboxesCode(do.drug_inventory_id) AS product_code,
do.quantity AS order_quantity,
concept_name(do.quantity_units,'en') AS order_quantity_units,
do.num_refills AS order_quantity_num_refills,
do.dose AS order_dose,
concept_name(do.dose_units,'en') AS order_dose_unit,
do.dosing_instructions AS order_dosing_instructions,
concept_name(do.route,'en') AS order_route, 
concept_name(of2.concept_id,'en') AS order_frequency,
do.duration  AS order_duration,
concept_name(do.duration_units,'en') AS order_duration_units,
concept_name(o.order_reason,'en') AS order_reason,
o.comment_to_fulfiller AS order_comments
FROM orders o
INNER JOIN drug_order do ON o.order_id = do.order_id 
LEFT OUTER JOIN users cu ON o.creator=cu.user_id
LEFT OUTER JOIN users ou ON o.orderer =ou.user_id
LEFT OUTER JOIN order_frequency of2 ON do.frequency = of2.order_frequency_id 
AND o.order_type_id = @order_type_id
;

UPDATE all_medication_prescribed SET order_location=encounter_location_name(encounter_id);

UPDATE all_medication_prescribed SET wellbody_emr_id=patient_identifier(patient_id,'1a2acce0-7426-11e5-a837-0800200c9a66');
UPDATE all_medication_prescribed SET kgh_emr_id=patient_identifier(patient_id,'c09a1d24-7162-11eb-8aa6-0242ac110002');


SELECT 
COALESCE(wellbody_emr_id,kgh_emr_id) AS emr_id,
order_type,
encounter_id,
visit_id,
order_id,
order_location,
order_created_date,
order_date_activated,
user_entered,
prescriber,
order_drug,
order_formulation,
order_formulation_non_coded,
product_code,
order_quantity,
order_quantity_units,
order_quantity_num_refills,
order_dose,
order_dose_unit,
order_dosing_instructions,
order_route,
order_frequency,
order_duration,
order_duration_units,
order_reason,
order_comments
FROM all_medication_prescribed;