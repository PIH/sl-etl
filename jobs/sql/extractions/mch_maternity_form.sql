SELECT encounter_type_id  INTO @mch_delivery_enc_type FROM encounter_type et WHERE uuid='00e5ebb2-90ec-11e8-9eb6-529269fb1459';

DROP TABLE IF EXISTS mch_maternity_form;
CREATE TABLE mch_maternity_form
(
encounter_id int,
patient_id int,
emrid varchar(30),
provider varchar(30),
location varchar(30),
form_date date,
estimated_delivery_date date, 
birth_weight float,
estimated_blood_loss float,
perineal_tear varchar(50),
GBV_victim boolean,
chorioamnionitis boolean,
severe_preeclampsia boolean,
eclampsia boolean,
prolonged_labor boolean,
acute_pulmonary_edema boolean,
puerperal_sepsis boolean,
herpes_simplex boolean,
syphilis boolean,
other_STI boolean,
other boolean,
other_free_response varchar(100),
postpartum_hemorrhage boolean,
blood_loss varchar(10),
placental_abnormality boolean,
malpresentation_fetus boolean,
cephalopelvic_disproportion boolean,
lbw_1000_1249 boolean,
lbw_1250_1499 boolean,
lbw_1500_1749 boolean,
lbw_1750_1999 boolean,
lbw_2000_2499 boolean,
extreme_premature_less_28 boolean,
very_premature_28_32 boolean,
moderate_prematurity_33_36 boolean,
respiratory_distress boolean,
birth_asphyxia boolean,
fetal_distress boolean,
intrauterine_fetal_demise boolean,
intrauterine_growth_retardation boolean,
congenital_malformation boolean,
premature_rupture_membranes boolean,
meconium_aspiration boolean,
exit_date date,
presumed_or_confirmed_diagnosis varchar(100),
clinical_note varchar(500),
primary_diagnosis boolean,
confirmed_diagnoses boolean,
counselled_HIV_testing varchar(100),
admission_datetime datetime,
gravida int,
parity int,
labour_datetime datetime,
presentation_position varchar(100),
presentation_other varchar(250),
delivery_datetime datetime,
gestational_age float,
delivery_type varchar(100),
delivery_outcome varchar(100),
partograph varchar(3),
uterotonic varchar(50),
newborn_sex varchar(10),
apgar_score_onemin float,
apgar_score_5min float,
apgar_score_10min float,
breastfeeding varchar(3),
pac_type varchar(250),
fp_counselling varchar(10),
family_planning varchar(10),
maternal_outcome_date date,
maternal_disposition varchar(100),
hcw_delivery varchar(100),
hcw_type varchar(100)
);

DROP TABLE IF EXISTS temp_encounter;
CREATE TEMPORARY TABLE temp_encounter
SELECT patient_id,encounter_id, encounter_type ,date(encounter_datetime) encounter_date, date_created 
FROM encounter e 
WHERE e.encounter_type = @mch_delivery_enc_type
AND e.voided = 0;

create index temp_encounter_ci1 on temp_encounter(encounter_id);

DROP TEMPORARY TABLE if exists temp_obs;
CREATE TEMPORARY TABLE temp_obs
select o.obs_id, o.voided, o.obs_group_id, o.encounter_id, o.person_id, o.concept_id, o.value_coded, o.value_numeric, o.value_text, o.value_datetime, o.value_drug, o.comments, o.date_created, o.obs_datetime
from obs o inner join temp_encounter t on o.encounter_id = t.encounter_id
where o.voided = 0;

create index temp_obs_ci3 on temp_obs(encounter_id, concept_id,value_coded);

INSERT INTO mch_maternity_form(patient_id, emrid, encounter_id,location,provider,form_date)-- ,obs_id,obs_group_id,concept_id )
SELECT e.patient_id,patient_identifier(e.patient_id,'1a2acce0-7426-11e5-a837-0800200c9a66'), e.encounter_id,
       encounter_location_name(e.encounter_id),provider(e.encounter_id), encounter_date
      --  ,o.obs_id, o.obs_group_id,o.concept_id
FROM temp_encounter e;

-- Diagnosis Attributes
UPDATE mch_maternity_form SET birth_weight=obs_value_numeric_from_temp(encounter_id,'PIH','11067');
UPDATE mch_maternity_form SET perineal_tear=obs_value_coded_list_from_temp(encounter_id,'PIH','12369','en');
UPDATE mch_maternity_form SET apgar_score_onemin=obs_value_numeric_from_temp(encounter_id,'PIH','14419');
UPDATE mch_maternity_form SET apgar_score_10min=obs_value_numeric_from_temp(encounter_id,'PIH','14785');
UPDATE mch_maternity_form SET apgar_score_5min=obs_value_numeric_from_temp(encounter_id,'PIH','14417');


-- Findings Mother
UPDATE mch_maternity_form SET GBV_victim=answer_exists_in_encounter_temp(encounter_id,'PIH','3064','PIH','11550');
UPDATE mch_maternity_form SET chorioamnionitis=answer_exists_in_encounter_temp(encounter_id,'PIH','3064','PIH','11818');
UPDATE mch_maternity_form SET severe_preeclampsia=answer_exists_in_encounter_temp(encounter_id,'PIH','3064','PIH','9344');
UPDATE mch_maternity_form SET eclampsia=answer_exists_in_encounter_temp(encounter_id,'PIH','3064','PIH','7696');
UPDATE mch_maternity_form SET prolonged_labor=answer_exists_in_encounter_temp(encounter_id,'PIH','3064','PIH','8417');
UPDATE mch_maternity_form SET acute_pulmonary_edema=answer_exists_in_encounter_temp(encounter_id,'PIH','3064','PIH','11819');
UPDATE mch_maternity_form SET puerperal_sepsis=answer_exists_in_encounter_temp(encounter_id,'PIH','3064','PIH','130');
UPDATE mch_maternity_form SET herpes_simplex=answer_exists_in_encounter_temp(encounter_id,'PIH','3064','PIH','3728');
UPDATE mch_maternity_form SET syphilis=answer_exists_in_encounter_temp(encounter_id,'PIH','3064','PIH','223');
UPDATE mch_maternity_form SET other_STI=answer_exists_in_encounter_temp(encounter_id,'PIH','3064','PIH','174');
UPDATE mch_maternity_form SET other=answer_exists_in_encounter_temp(encounter_id,'PIH','6644','PIH','5622');
UPDATE mch_maternity_form SET other_free_response=obs_comments_from_temp(encounter_id,'PIH','6644','PIH','5622');
UPDATE mch_maternity_form SET postpartum_hemorrhage=answer_exists_in_encounter_temp(encounter_id,'PIH','3064','PIH','49');
UPDATE mch_maternity_form SET blood_loss=obs_value_numeric_from_temp(encounter_id,'PIH','12555');

-- Baby Findings
UPDATE mch_maternity_form SET placental_abnormality=answer_exists_in_encounter_temp(encounter_id,'PIH','12564','PIH','8395');
UPDATE mch_maternity_form SET malpresentation_fetus=answer_exists_in_encounter_temp(encounter_id,'PIH','12564','PIH','11688');
UPDATE mch_maternity_form SET cephalopelvic_disproportion=answer_exists_in_encounter_temp(encounter_id,'PIH','12564','PIH','8030');
UPDATE mch_maternity_form SET lbw_1000_1249=answer_exists_in_encounter_temp(encounter_id,'PIH','12564','PIH','9436');
UPDATE mch_maternity_form SET lbw_1250_1499=answer_exists_in_encounter_temp(encounter_id,'PIH','12564','PIH','9477');
UPDATE mch_maternity_form SET lbw_1500_1749=answer_exists_in_encounter_temp(encounter_id,'PIH','12564','PIH','9478');
UPDATE mch_maternity_form SET lbw_1750_1999=answer_exists_in_encounter_temp(encounter_id,'PIH','12564','PIH','9443');
UPDATE mch_maternity_form SET lbw_2000_2499=answer_exists_in_encounter_temp(encounter_id,'PIH','12564','PIH','9415');
UPDATE mch_maternity_form SET extreme_premature_less_28=answer_exists_in_encounter_temp(encounter_id,'PIH','12564','PIH','9414');
UPDATE mch_maternity_form SET very_premature_28_32=answer_exists_in_encounter_temp(encounter_id,'PIH','12564','PIH','11789');
UPDATE mch_maternity_form SET moderate_prematurity_33_36=answer_exists_in_encounter_temp(encounter_id,'PIH','12564','PIH','11790');
UPDATE mch_maternity_form SET respiratory_distress=answer_exists_in_encounter_temp(encounter_id,'PIH','12564','PIH','11726');
UPDATE mch_maternity_form SET birth_asphyxia=answer_exists_in_encounter_temp(encounter_id,'PIH','12564','PIH','7557');
UPDATE mch_maternity_form SET fetal_distress=answer_exists_in_encounter_temp(encounter_id,'PIH','12564','PIH','7567');
UPDATE mch_maternity_form SET intrauterine_fetal_demise=answer_exists_in_encounter_temp(encounter_id,'PIH','12564','PIH','7991');
UPDATE mch_maternity_form SET intrauterine_growth_retardation=answer_exists_in_encounter_temp(encounter_id,'PIH','12564','PIH','9465');
UPDATE mch_maternity_form SET congenital_malformation=answer_exists_in_encounter_temp(encounter_id,'PIH','12564','PIH','10135');
UPDATE mch_maternity_form SET premature_rupture_membranes=answer_exists_in_encounter_temp(encounter_id,'PIH','12564','PIH','7227');
UPDATE mch_maternity_form SET meconium_aspiration=answer_exists_in_encounter_temp(encounter_id,'PIH','12564','PIH','9411');
UPDATE mch_maternity_form SET exit_date=obs_value_datetime_from_temp(encounter_id,'PIH','3800');

SET @row_number=0;
drop table if exists temp_mh_diagnosis;
create temporary table temp_mh_diagnosis
select
       concept_name(value_coded,'en') AS diagnosis,
       obs_group_id,
       @row_number:=if((@person_id=person_id) AND (@encounter_id=encounter_id) /*AND (@obs_group_id=obs_group_id)*/, @row_number + 1, 1) RANK,
       @person_id:=person_id person_id,
       @encounter_id:=encounter_id encounter_id
       -- ,@obs_group_id:=obs_group_id
from   temp_obs 
where  concept_id = concept_from_mapping('PIH','3064')--  AND person_id=114910
order by person_id, encounter_id, obs_group_id, date_created asc;
create index temp_mh_diagnosis_idx1 on temp_mh_diagnosis(encounter_id,rank);


update mch_maternity_form e
    inner join temp_mh_diagnosis o on e.encounter_id = o.encounter_id
set e.presumed_or_confirmed_diagnosis = o.diagnosis
where o.rank = 1;

update mch_maternity_form e
    inner join temp_mh_diagnosis o on e.encounter_id = o.encounter_id
set e.primary_diagnosis = CASE WHEN obs_from_group_id_value_coded_list_from_temp(o.obs_group_id, 'PIH', '7537', 'en') IS NOT NULL THEN TRUE ELSE FALSE END 
where o.rank = 1;

update mch_maternity_form e
    inner join temp_mh_diagnosis o on e.encounter_id = o.encounter_id
set e.confirmed_diagnoses = CASE WHEN obs_from_group_id_value_coded_list_from_temp(o.obs_group_id, 'PIH', '1379', 'en') IS NOT NULL THEN TRUE ELSE FALSE END 
where o.rank = 1;

UPDATE mch_maternity_form SET clinical_note=obs_value_text_from_temp(encounter_id,'PIH','1364');
UPDATE mch_maternity_form SET counselled_HIV_testing=obs_value_coded_list_from_temp(encounter_id,'PIH','11381','en');

UPDATE mch_maternity_form SET admission_datetime=obs_value_datetime_from_temp(encounter_id,'PIH','12240');
UPDATE mch_maternity_form SET gravida=obs_value_numeric_from_temp(encounter_id,'PIH','5624');
UPDATE mch_maternity_form SET parity=obs_value_numeric_from_temp(encounter_id,'PIH','1053');

UPDATE mch_maternity_form SET gestational_age=obs_value_numeric_from_temp(encounter_id,'PIH','14390');
UPDATE mch_maternity_form SET labour_datetime=obs_value_datetime_from_temp(encounter_id,'PIH','14377');
UPDATE mch_maternity_form SET presentation_position=obs_value_coded_list_from_temp(encounter_id,'PIH','13047','en');
UPDATE mch_maternity_form SET presentation_other=obs_value_text_from_temp(encounter_id,'PIH','14414');

-- Delivery Attributes
UPDATE mch_maternity_form SET delivery_datetime=obs_value_datetime_from_temp(encounter_id,'PIH','5599');
UPDATE mch_maternity_form SET delivery_type=obs_value_coded_list_from_temp(encounter_id,'PIH','11663','en');
UPDATE mch_maternity_form SET delivery_outcome=obs_value_coded_list_from_temp(encounter_id,'PIH','13561','en');
UPDATE mch_maternity_form SET partograph=obs_value_coded_list_from_temp(encounter_id,'PIH','13964','en');
UPDATE mch_maternity_form SET uterotonic=obs_value_coded_list_from_temp(encounter_id,'PIH','14373','en');

-- New Born Condition Attributes
UPDATE mch_maternity_form SET newborn_sex=obs_value_coded_list_from_temp(encounter_id,'PIH','13055','en');
UPDATE mch_maternity_form SET breastfeeding=obs_value_coded_list_from_temp(encounter_id,'PIH','14372','en');

UPDATE mch_maternity_form SET fp_counselling=obs_value_coded_list_from_temp(encounter_id,'PIH','12241','en');
UPDATE mch_maternity_form SET family_planning=obs_value_coded_list_from_temp(encounter_id,'PIH','13564','en');

UPDATE mch_maternity_form SET maternal_outcome_date=obs_value_datetime_from_temp(encounter_id,'PIH','3800') ;
UPDATE mch_maternity_form SET maternal_disposition=obs_value_coded_list_from_temp(encounter_id,'PIH','8620','en');

UPDATE mch_maternity_form SET hcw_delivery=obs_value_text_from_temp(encounter_id,'PIH','6592');
UPDATE mch_maternity_form SET hcw_type=obs_value_coded_list_from_temp(encounter_id,'PIH','14411','en');

DROP TABLE IF EXISTS pac_type_values;
CREATE TEMPORARY TABLE pac_type_values
SELECT encounter_id,value_coded_name(obs_id,'en') name FROM temp_obs
WHERE concept_id=concept_from_mapping('PIH','14376');

SELECT 
emrid,
provider,
location,
form_date,
estimated_delivery_date, -- NULL 
birth_weight,
estimated_blood_loss,
perineal_tear,
GBV_victim,
chorioamnionitis,
severe_preeclampsia,
eclampsia,
prolonged_labor,
acute_pulmonary_edema,
puerperal_sepsis,
herpes_simplex,
syphilis,
other_STI,
other,
other_free_response,
postpartum_hemorrhage,
blood_loss,
placental_abnormality,
malpresentation_fetus,
cephalopelvic_disproportion,
lbw_1000_1249,
lbw_1250_1499,
lbw_1500_1749,
lbw_1750_1999,
lbw_2000_2499,
extreme_premature_less_28,
very_premature_28_32,
moderate_prematurity_33_36,
respiratory_distress,
birth_asphyxia,
fetal_distress,
intrauterine_fetal_demise,
intrauterine_growth_retardation,
congenital_malformation,
premature_rupture_membranes,
meconium_aspiration,
exit_date,
presumed_or_confirmed_diagnosis,
clinical_note,
primary_diagnosis,
confirmed_diagnoses,
counselled_HIV_testing,
admission_datetime,
gravida,
parity,
labour_datetime,
presentation_position,
presentation_other,
delivery_datetime,
gestational_age,
delivery_type,
delivery_outcome,
partograph,
uterotonic,
newborn_sex,
apgar_score_onemin,
apgar_score_5min,
apgar_score_10min,
breastfeeding,
p.name AS pac_type,
fp_counselling,
family_planning,
maternal_outcome_date,
maternal_disposition,
hcw_delivery,
hcw_type
FROM mch_maternity_form t
INNER JOIN pac_type_values p
ON t.encounter_id =p.encounter_id;