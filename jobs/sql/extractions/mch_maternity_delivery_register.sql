set @partition = '${partitionNum}';
SELECT encounter_type_id  INTO @mch_reg_enc_type FROM encounter_type et WHERE uuid='9cc89b83-e32f-410a-947d-aeb3bda37571';

DROP TABLE IF EXISTS mch_maternity_delivery_register;
CREATE TABLE mch_maternity_delivery_register
(
wellbody_emr_id varchar(50),
kgh_emr_id varchar(50),
encounter_id int,
obs_group_id int,
obs_id int,
concept_id int,
patient_id int,
emrid varchar(30),
provider varchar(30),
location varchar(30),
admission_datetime datetime,
gravida int,
parity int,
gestational_age float,
pac_type varchar(100),
labour_datetime datetime,
presentation_position varchar(100),
presentation_other varchar(500),
delivery_datetime datetime,
delivery_type varchar(100),
delivery_outcome varchar(100),
partograph varchar(10),
uterotonic varchar(100),
newborn_alive varchar(10),
newborn_sex varchar(10),
newborn_weight float,
newborn_apgar int,
breastfeeding varchar(10),
initial_diagnosis_1 varchar(100),
initial_diagnosis_2 varchar(100),
initial_diagnosis_3 varchar(100),
initial_diagnosis_other varchar(100),
final_diagnosis_1 varchar(100),
final_diagnosis_2 varchar(100),
final_diagnosis_3 varchar(100),
final_diagnosis_other varchar(100),
fp_counselling varchar(10),
family_planning varchar(10),
maternal_outcome_date date,
maternal_disposition varchar(100),
hcw_delivery varchar(100),
hcw_type varchar(100)
);

DROP TABLE IF EXISTS temp_encounter;
CREATE TEMPORARY TABLE temp_encounter
SELECT patient_id,encounter_id, encounter_type ,encounter_datetime, date_created 
FROM encounter e 
WHERE e.encounter_type = @mch_reg_enc_type
AND e.voided = 0;

create index temp_encounter_ci1 on temp_encounter(encounter_id);

DROP TEMPORARY TABLE if exists temp_obs;
CREATE TEMPORARY TABLE temp_obs
select o.obs_id, o.voided, o.obs_group_id, o.encounter_id, o.person_id, o.concept_id, o.value_coded, o.value_numeric, o.value_text, o.value_datetime, o.value_drug, o.comments, o.date_created, o.obs_datetime
from obs o inner join temp_encounter t on o.encounter_id = t.encounter_id
where o.voided = 0;

create index temp_obs_ci1 on temp_obs(obs_id, concept_id);
create index temp_obs_ci2 on temp_obs(obs_id);
create index temp_obs_ci3 on temp_obs(obs_group_id,concept_id);

DROP TEMPORARY TABLE if exists temp_obs_pac;
CREATE TEMPORARY TABLE temp_obs_pac
select o.obs_id, concept_name(value_coded,'en') pac_type, o.encounter_id, o.person_id 
from obs o inner join temp_encounter t on o.encounter_id = t.encounter_id
where o.voided = 0
AND o.concept_id = concept_from_mapping('PIH','14376');

INSERT INTO mch_maternity_delivery_register(patient_id, emrid, encounter_id,location,provider)
SELECT e.patient_id,patient_identifier(e.patient_id,'1a2acce0-7426-11e5-a837-0800200c9a66'), e.encounter_id,
       encounter_location_name(e.encounter_id),provider(e.encounter_id)
FROM temp_encounter e;

UPDATE mch_maternity_delivery_register SET admission_datetime=obs_value_datetime_from_temp(encounter_id,'PIH','12240');
UPDATE mch_maternity_delivery_register SET gravida=obs_value_numeric_from_temp(encounter_id,'PIH','5624');
UPDATE mch_maternity_delivery_register SET parity=obs_value_numeric_from_temp(encounter_id,'PIH','1053');
UPDATE mch_maternity_delivery_register SET gestational_age=obs_value_numeric_from_temp(encounter_id,'PIH','14390');

UPDATE mch_maternity_delivery_register m
SET wellbody_emr_id= patient_identifier(patient_id,'1a2acce0-7426-11e5-a837-0800200c9a66');

UPDATE mch_maternity_delivery_register m 
SET kgh_emr_id= patient_identifier(patient_id,'c09a1d24-7162-11eb-8aa6-0242ac110002');


-- Labor Attributes
UPDATE mch_maternity_delivery_register SET labour_datetime=obs_value_datetime_from_temp(encounter_id,'PIH','14377');
UPDATE mch_maternity_delivery_register SET presentation_position=obs_value_coded_list_from_temp(encounter_id,'PIH','13047','en');
UPDATE mch_maternity_delivery_register SET presentation_other=obs_value_text_from_temp(encounter_id,'PIH','14414');

-- Delivery Attributes
UPDATE mch_maternity_delivery_register SET delivery_datetime=obs_value_datetime_from_temp(encounter_id,'PIH','5599');
UPDATE mch_maternity_delivery_register SET delivery_type=obs_value_coded_list_from_temp(encounter_id,'PIH','11663','en');
UPDATE mch_maternity_delivery_register SET delivery_outcome=obs_value_coded_list_from_temp(encounter_id,'PIH','13561','en');
UPDATE mch_maternity_delivery_register SET partograph=obs_value_coded_list_from_temp(encounter_id,'PIH','13964','en');
UPDATE mch_maternity_delivery_register SET uterotonic=obs_value_coded_list_from_temp(encounter_id,'PIH','14373','en');

-- New Born Condition Attributes
UPDATE mch_maternity_delivery_register SET newborn_alive=obs_value_coded_list_from_temp(encounter_id,'PIH','1571','en');
UPDATE mch_maternity_delivery_register SET newborn_sex=obs_value_coded_list_from_temp(encounter_id,'PIH','13055','en');
UPDATE mch_maternity_delivery_register SET newborn_weight=obs_value_numeric_from_temp(encounter_id,'PIH','11067');
UPDATE mch_maternity_delivery_register SET newborn_apgar=obs_value_numeric_from_temp(encounter_id,'PIH','13558');
UPDATE mch_maternity_delivery_register SET breastfeeding=obs_value_coded_list_from_temp(encounter_id,'PIH','14372','en');

-- Diagnosis
SELECT concept_from_mapping('PIH','14391') INTO @prior_visit_diagnosis;

SET @row_number=0;
drop table if exists temp_mh_initial_diagnosis;
create temporary table temp_mh_initial_diagnosis
select
       concept_name(value_coded,'en') diagnosis,
       @row_number:=if((@person_id=person_id) AND (@encounter_id=encounter_id), @row_number + 1, 1) RANK,
       @person_id:=person_id person_id,
       @encounter_id:=encounter_id encounter_id   
from   temp_obs 
where  concept_id = concept_from_mapping('PIH','3064') -- @prior_visit_diagnosis 
order by person_id, encounter_id, obs_group_id, date_created asc;
create index temp_mh_initial_diagnosis_idx1 on temp_mh_initial_diagnosis(encounter_id,rank);

update mch_maternity_delivery_register e
    inner join temp_mh_initial_diagnosis o on e.encounter_id = o.encounter_id
set e.initial_diagnosis_1 = o.diagnosis
where o.rank = 1;

update mch_maternity_delivery_register e
    inner join temp_mh_initial_diagnosis o on e.encounter_id = o.encounter_id
set e.initial_diagnosis_2 = o.diagnosis
where o.rank = 2;

update mch_maternity_delivery_register e
    inner join temp_mh_initial_diagnosis o on e.encounter_id = o.encounter_id
set e.initial_diagnosis_3 = o.diagnosis
where o.rank = 3;

update mch_maternity_delivery_register e
    inner join temp_mh_initial_diagnosis o on e.encounter_id = o.encounter_id
set e.final_diagnosis_1 = o.diagnosis
where o.rank = 4;

update mch_maternity_delivery_register e
    inner join temp_mh_initial_diagnosis o on e.encounter_id = o.encounter_id
set e.final_diagnosis_2 = o.diagnosis
where o.rank = 5;

update mch_maternity_delivery_register e
    inner join temp_mh_initial_diagnosis o on e.encounter_id = o.encounter_id
set e.final_diagnosis_3 = o.diagnosis
where o.rank = 6;

SET @row_number=0;
drop table if exists temp_mh_other_diagnosis;
create temporary table temp_mh_other_diagnosis
select
       value_text diagnosis,
       @row_number:=if((@person_id=person_id) AND (@encounter_id=encounter_id), @row_number + 1, 1) RANK,
       @person_id:=person_id person_id,
       @encounter_id:=encounter_id encounter_id   
from   temp_obs 
where  concept_id = concept_from_mapping('PIH','7416')
order by person_id, encounter_id, obs_group_id, date_created asc;
create index temp_mh_other_diagnosis_idx1 on temp_mh_other_diagnosis(encounter_id,rank);

update mch_maternity_delivery_register e
    inner join temp_mh_other_diagnosis o on e.encounter_id = o.encounter_id
set e.initial_diagnosis_other = o.diagnosis
where o.rank = 1;

update mch_maternity_delivery_register e
    inner join temp_mh_other_diagnosis o on e.encounter_id = o.encounter_id
set e.final_diagnosis_other = o.diagnosis
where o.rank = 2;

-- New Born Condition Attributes
UPDATE mch_maternity_delivery_register SET fp_counselling=obs_value_coded_list_from_temp(encounter_id,'PIH','12241','en');
UPDATE mch_maternity_delivery_register SET family_planning=obs_value_coded_list_from_temp(encounter_id,'PIH','13564','en');


UPDATE mch_maternity_delivery_register SET maternal_outcome_date=CURRENT_DATE() ;
UPDATE mch_maternity_delivery_register SET maternal_disposition=obs_value_coded_list_from_temp(encounter_id,'PIH','8620','en');

UPDATE mch_maternity_delivery_register SET hcw_delivery=obs_value_text_from_temp(encounter_id,'PIH','6592');
UPDATE mch_maternity_delivery_register SET hcw_type=obs_value_coded_list_from_temp(encounter_id,'PIH','14411','en');

SELECT
concat(@partition,"-",patient_id)  as patient_id,
wellbody_emr_id,
kgh_emr_id,
provider,
location,
admission_datetime,
gravida,
parity,
gestational_age,
o.pac_type,
labour_datetime,
presentation_position,
presentation_other,
delivery_datetime,
delivery_type,
delivery_outcome,
partograph,
uterotonic,
newborn_alive,
newborn_sex,
newborn_weight,
newborn_apgar,
breastfeeding,
initial_diagnosis_1,
initial_diagnosis_2,
initial_diagnosis_3,
initial_diagnosis_other,
final_diagnosis_1,
final_diagnosis_2,
final_diagnosis_3,
final_diagnosis_other,
fp_counselling,
family_planning,
maternal_outcome_date,
maternal_disposition,
hcw_delivery,
hcw_type
FROM mch_maternity_delivery_register t
INNER JOIN temp_obs_pac o ON t.encounter_id=o.encounter_id AND t.patient_id=o.person_id;
