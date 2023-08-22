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
delivery_date date,
estimated_delivery_date date, 
gestational_age int, 
birth_weight float,
estimated_blood_loss float,
delivery_type boolean,
vaginal_delivery boolean,
breech boolean,
perineal_tear varchar(50),
apgar_score_onemin varchar(50),
apgar_score_5min int,
apgar_score_10min varchar(50),
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
med_name  varchar(100),
med_dose  varchar(10),
med_dose_unit  varchar(100),
med_route  varchar(100),
med_freq  varchar(100),
med_duration  varchar(100),
med_duration_unit  varchar(100),
med_admin_instructions  varchar(500)
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

DROP TEMPORARY TABLE if exists temp_order;
CREATE TEMPORARY TABLE temp_order
SELECT o.order_id, o.encounter_id, o.patient_id, drugName(do.drug_inventory_id) drug_name , do.dose , do.dose_units, do.quantity, do.quantity_units , 
	   do.route, do.duration , do.duration_units , do.frequency 
FROM orders o INNER JOIN temp_encounter t on o.encounter_id = t.encounter_id
INNER JOIN drug_order do ON do.order_id = o.order_id 
WHERE o.voided =0;

INSERT INTO mch_maternity_form(patient_id, emrid, encounter_id,location,provider,form_date)
SELECT e.patient_id,patient_identifier(e.patient_id,'1a2acce0-7426-11e5-a837-0800200c9a66'), e.encounter_id,
       encounter_location_name(e.encounter_id),provider(e.encounter_id), encounter_date
FROM temp_encounter e;

-- Diagnosis Attributes
UPDATE mch_maternity_form SET delivery_date=obs_value_datetime_from_temp(encounter_id,'PIH','5599');
UPDATE mch_maternity_form SET birth_weight=obs_value_numeric_from_temp(encounter_id,'PIH','11067');
UPDATE mch_maternity_form SET vaginal_delivery=CASE WHEN obs_value_coded_list_from_temp(encounter_id,'PIH','11663','en') IS NOT NULL THEN TRUE ELSE FALSE END;
UPDATE mch_maternity_form SET delivery_type=CASE WHEN obs_value_coded_list_from_temp(encounter_id,'PIH','11663','en') IS NOT NULL THEN TRUE ELSE FALSE END;
UPDATE mch_maternity_form SET breech=CASE WHEN obs_value_coded_list_from_temp(encounter_id,'PIH','10751','en') IS NOT NULL THEN TRUE ELSE FALSE END;
UPDATE mch_maternity_form SET perineal_tear=obs_value_coded_list_from_temp(encounter_id,'PIH','12369','en');
UPDATE mch_maternity_form SET apgar_score_onemin=obs_value_coded_list_from_temp(encounter_id,'PIH','12377','en');
UPDATE mch_maternity_form SET apgar_score_10min=obs_value_coded_list_from_temp(encounter_id,'PIH','12378','en');
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
       @row_number:=if((@person_id=person_id) AND (@encounter_id=encounter_id), @row_number + 1, 1) RANK,
       @person_id:=person_id person_id,
       @encounter_id:=encounter_id encounter_id
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

SET @row_number=0;
drop table if exists temp_drug_order;
create temporary table temp_drug_order
select
       @row_number:=if((@patient_id=patient_id) AND (@encounter_id=encounter_id), @row_number + 1, 1) RANK,
       @patient_id:=patient_id patient_id,
       @encounter_id:=encounter_id encounter_id,
       @order_id:=order_id order_id,
       drug_name , dose , dose_units, quantity, quantity_units , 
	   route, duration , duration_units , frequency 
from   temp_order
order by patient_id, encounter_id, order_id;
create index temp_drug_order_idx1 on temp_drug_order(patient_id,encounter_id,order_id,rank);

UPDATE mch_maternity_form t
INNER JOIN temp_drug_order o ON t.encounter_id=o.encounter_id
SET med_name=o.drug_name, 
med_dose=o.dose,
med_dose_unit=concept_name(o.dose_units,'en'),
med_route=concept_name(o.route,'en'),
med_freq=concept_name(o.frequency,'en'),
med_duration=o.duration,
med_duration_unit=concept_name(o.duration_units,'en');

UPDATE mch_maternity_form SET med_admin_instructions=obs_value_text_from_temp(encounter_id,'PIH','10637');


SELECT 
emrid,
provider,
location,
form_date,
delivery_date,
estimated_delivery_date,
gestational_age,
birth_weight,
estimated_blood_loss,
delivery_type,
vaginal_delivery,
breech,perineal_tear,
apgar_score_onemin,
apgar_score_5min,
apgar_score_10min,
GBV_victim,chorioamnionitis,
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
med_name,
med_dose,
med_dose_unit,
med_route,
med_freq,
med_duration,
med_duration_unit,
med_admin_instructions
FROM mch_maternity_form;