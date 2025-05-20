set @partition = '${partitionNum}';

SELECT encounter_type_id  INTO @anc_init
FROM encounter_type et WHERE uuid='00e5e810-90ec-11e8-9eb6-529269fb1459';

SELECT encounter_type_id  INTO @anc_followup
FROM encounter_type et WHERE uuid='00e5e946-90ec-11e8-9eb6-529269fb1459';

set @pregnancyProgramId = program('Pregnancy');

drop temporary table if exists temp_anc_encs;
create temporary table temp_anc_encs
(
patient_id                 int,          
emr_id                     varchar(255), 
encounter_id               int,          
visit_id                   int,
pregnancy_program_id       int, 
encounter_datetime         datetime,     
encounter_location         varchar(255), 
datetime_entered           datetime,     
user_entered               varchar(255), 
provider                   varchar(255), 
visit_type                 varchar(255), 
age_at_encounter           int,
trimester_enrolled         varchar(255), 
number_anc_visit           int,          
birth_weight_other_babies  varchar(255), 
danger_signs               text, 
high_risk_factors          text, 
other_risk_factors         text,
prior_neonatal_deaths      int,          
prior_stillbirths          int,          
gravida                    int,          
parity                     int,          
abortus                    int,          
living                     int,          
last_menstruation_date     datetime,     
estimated_delivery_date    datetime,     
estimated_gestational_age  int,    
return_visit_date          datetime,     
height                     decimal(8,2), 
weight                     decimal(8,2), 
bp_systolic                int,          
bp_diastolic               int,          
fundal_height              numeric(8,2), 
fetal_heart_rate           int,          
blood_type                 varchar(255), 
urine_glucose              varchar(255), 
urine_protein              varchar(255), 
ferrous_sulfate_folic_acid boolean, 
hiv_syphilis_rapid_test    varchar(255),
iptp_sp_malaria            boolean,      
nutrition_counseling       boolean,      
hiv_counsel_and_test       boolean,      
insecticide_treated_net    boolean,      
smokes_tobacco             varchar(255), 
drinks_alcohol             varchar(255), 
drinks_per_day             int,          
uses_drugs                 varchar(255), 
drug_name                  varchar(255), 
albendazole                boolean,
malaria_rdt                varchar(255),
counseled_danger_signs     boolean,
llin                       boolean,
latest_entered_number_anc_visit INT,
actual_visit_number        INT,
index_asc                  INT,          
index_desc                 INT,
index_asc_patient_program  INT,
index_desc_patient_program INT
);

insert into temp_anc_encs(patient_id, encounter_id, visit_id, encounter_datetime,
datetime_entered, user_entered, visit_type)
select patient_id, encounter_id, visit_id, encounter_datetime, date_created, creator, encounter_type_name_from_id(encounter_type)
from encounter e
where e.voided = 0
AND encounter_type IN (@anc_followup, @anc_init)
ORDER BY encounter_datetime desc;

create index temp_labor_encs_ei on temp_anc_encs(encounter_id);
create index temp_anc_encs_c1 on temp_anc_encs(patient_id, pregnancy_program_id,encounter_datetime);


UPDATE temp_anc_encs
set user_entered = person_name_of_user(user_entered);

UPDATE temp_anc_encs
SET provider = provider(encounter_id);

UPDATE temp_anc_encs t
SET emr_id = patient_identifier(patient_id, metadata_uuid('org.openmrs.module.emrapi', 'emr.primaryIdentifierType'));

UPDATE temp_anc_encs
SET encounter_location=encounter_location_name(encounter_id);

update temp_anc_encs
set pregnancy_program_id = patient_program_id_from_encounter(patient_id, @pregnancyProgramId ,encounter_id);

update temp_anc_encs 
set age_at_encounter = age_at_enc(patient_id, encounter_id);

DROP TEMPORARY TABLE IF EXISTS temp_obs;
create temporary table temp_obs
select o.obs_id, o.voided ,o.obs_group_id , o.encounter_id, o.person_id, o.concept_id, o.value_coded, o.value_numeric,
o.value_text,o.value_datetime, o.comments, o.date_created, o.obs_datetime
from obs o
inner join temp_anc_encs t on t.encounter_id = o.encounter_id
where o.voided = 0;

create index temp_obs_encs_ei on temp_obs(encounter_id);
create index temp_obs_encs_eobs on temp_obs(encounter_id, obs_group_id);

SET @abortus = concept_from_mapping('PIH','7012');
SET @albendazole = concept_from_mapping('PIH','10570');
SET @birth_weight_other_babies = concept_from_mapping('PIH','20072');
SET @blood_type = concept_from_mapping('PIH','300');
SET @bp_diastolic = concept_from_mapping('PIH','5086');
SET @bp_systolic = concept_from_mapping('PIH','5085');
SET @counseled_danger_signs = concept_from_mapping('PIH','12750');
SET @danger_signs = concept_from_mapping('PIH','3064');
SET @drinks_alcohol = concept_from_mapping('PIH','1552');
SET @drinks_per_day = concept_from_mapping('PIH','2246');
SET @drug_name = concept_from_mapping('PIH','6489');
SET @estimated_delivery_date = concept_from_mapping('PIH','5596');
SET @estimated_gestational_age = concept_from_mapping('PIH','1279');
SET @ferrous_sulfate_folic_acid = concept_from_mapping('PIH','20073');
SET @fetal_heart_rate = concept_from_mapping('PIH','13199');
SET @fundal_height = concept_from_mapping('PIH','13028');
SET @gravida = concept_from_mapping('PIH','5624');
SET @height = concept_from_mapping('PIH','5090');
SET @high_risk_factors = concept_from_mapping('PIH','11673');
SET @hiv_counsel_and_test = concept_from_mapping('PIH','11381');
SET @hiv_syphilis_rapid_test = concept_from_mapping('PIH','20762');
SET @insecticide_treated_net = concept_from_mapping('PIH','13053');
SET @iptp_sp_malaria = concept_from_mapping('PIH','20074');
SET @last_menstruation_date = concept_from_mapping('PIH','968');
SET @living = concept_from_mapping('PIH','11117');
SET @llin = concept_from_mapping('PIH','13053');
SET @malaria_rdt = concept_from_mapping('PIH','11464');
SET @number_anc_visit = concept_from_mapping('PIH','13321');
SET @nutrition_counseling = concept_from_mapping('PIH','12878');
SET @parity = concept_from_mapping('PIH','1053');
SET @prior_neonatal_deaths = concept_from_mapping('PIH','13241');
SET @prior_stillbirths = concept_from_mapping('PIH','13240');
SET @return_visit_date = concept_from_mapping('PIH','5096');
SET @smokes_tobacco = concept_from_mapping('PIH','2545');
SET @trimester_enrolled = concept_from_mapping('PIH','11661');
SET @urine_glucose = concept_from_mapping('PIH','12292');
SET @urine_protein = concept_from_mapping('PIH','12272');
SET @uses_drugs = concept_from_mapping('PIH','2546');
SET @weight = concept_from_mapping('PIH','5089');

  UPDATE temp_anc_encs t SET abortus = obs_value_numeric_from_temp_using_concept_id(encounter_id, @abortus);
UPDATE temp_anc_encs t SET albendazole = obs_value_coded_as_boolean_from_temp_using_concept_id(encounter_id, @albendazole);
UPDATE temp_anc_encs t SET birth_weight_other_babies = obs_value_coded_list_from_temp_using_concept_id(encounter_id, @birth_weight_other_babies,'en');
UPDATE temp_anc_encs t SET blood_type = obs_value_coded_list_from_temp_using_concept_id(encounter_id, @blood_type,'en');
UPDATE temp_anc_encs t SET bp_diastolic = obs_value_numeric_from_temp_using_concept_id(encounter_id, @bp_diastolic);
UPDATE temp_anc_encs t SET bp_systolic = obs_value_numeric_from_temp_using_concept_id(encounter_id, @bp_systolic);
UPDATE temp_anc_encs t SET counseled_danger_signs = obs_value_coded_as_boolean_from_temp_using_concept_id(encounter_id, @counseled_danger_signs);
UPDATE temp_anc_encs t SET danger_signs = obs_value_coded_list_from_temp_using_concept_id(encounter_id, @danger_signs,'en');
UPDATE temp_anc_encs t SET drinks_alcohol = obs_value_coded_list_from_temp_using_concept_id(encounter_id, @drinks_alcohol,'en');
UPDATE temp_anc_encs t SET drinks_per_day = obs_value_numeric_from_temp_using_concept_id(encounter_id, @drinks_per_day);
UPDATE temp_anc_encs t SET drug_name = obs_value_text_from_temp_using_concept_id(encounter_id, @drug_name);
UPDATE temp_anc_encs t SET estimated_delivery_date = obs_value_datetime_from_temp_using_concept_id(encounter_id, @estimated_delivery_date);
UPDATE temp_anc_encs t SET estimated_gestational_age = obs_value_numeric_from_temp_using_concept_id(encounter_id, @estimated_gestational_age);
UPDATE temp_anc_encs t SET ferrous_sulfate_folic_acid = obs_value_coded_as_boolean_from_temp_using_concept_id(encounter_id, @ferrous_sulfate_folic_acid);
UPDATE temp_anc_encs t SET fetal_heart_rate = obs_value_numeric_from_temp_using_concept_id(encounter_id, @fetal_heart_rate);
UPDATE temp_anc_encs t SET fundal_height = obs_value_numeric_from_temp_using_concept_id(encounter_id, @fundal_height);
UPDATE temp_anc_encs t SET gravida = obs_value_numeric_from_temp_using_concept_id(encounter_id, @gravida);
UPDATE temp_anc_encs t SET height = obs_value_numeric_from_temp_using_concept_id(encounter_id, @height);
UPDATE temp_anc_encs t SET high_risk_factors = obs_value_coded_list_from_temp_using_concept_id(encounter_id, @high_risk_factors,'en');
UPDATE temp_anc_encs t SET hiv_counsel_and_test = obs_value_coded_as_boolean_from_temp_using_concept_id(encounter_id, @hiv_counsel_and_test);
UPDATE temp_anc_encs t SET hiv_syphilis_rapid_test = obs_value_coded_list_from_temp_using_concept_id(encounter_id, @hiv_syphilis_rapid_test,'en');
UPDATE temp_anc_encs t SET insecticide_treated_net = obs_value_coded_as_boolean_from_temp_using_concept_id(encounter_id, @insecticide_treated_net);
UPDATE temp_anc_encs t SET iptp_sp_malaria = obs_value_coded_as_boolean_from_temp_using_concept_id(encounter_id, @iptp_sp_malaria);
UPDATE temp_anc_encs t SET last_menstruation_date = obs_value_datetime_from_temp_using_concept_id(encounter_id, @last_menstruation_date);
UPDATE temp_anc_encs t SET living = obs_value_numeric_from_temp_using_concept_id(encounter_id, @living);
UPDATE temp_anc_encs t SET llin = obs_value_coded_as_boolean_from_temp_using_concept_id(encounter_id, @llin);
UPDATE temp_anc_encs t SET malaria_rdt = obs_value_coded_list_from_temp_using_concept_id(encounter_id, @malaria_rdt,'en');
UPDATE temp_anc_encs t SET number_anc_visit = obs_value_numeric_from_temp_using_concept_id(encounter_id, @number_anc_visit);
UPDATE temp_anc_encs t SET nutrition_counseling = obs_value_coded_as_boolean_from_temp_using_concept_id(encounter_id, @nutrition_counseling);
UPDATE temp_anc_encs t SET parity = obs_value_numeric_from_temp_using_concept_id(encounter_id, @parity);
UPDATE temp_anc_encs t SET prior_neonatal_deaths = obs_value_numeric_from_temp_using_concept_id(encounter_id, @prior_neonatal_deaths);
UPDATE temp_anc_encs t SET prior_stillbirths = obs_value_numeric_from_temp_using_concept_id(encounter_id, @prior_stillbirths);
UPDATE temp_anc_encs t SET return_visit_date = obs_value_datetime_from_temp_using_concept_id(encounter_id, @return_visit_date);
UPDATE temp_anc_encs t SET smokes_tobacco = obs_value_coded_list_from_temp_using_concept_id(encounter_id, @smokes_tobacco,'en');
UPDATE temp_anc_encs t SET trimester_enrolled = obs_value_coded_list_from_temp_using_concept_id(encounter_id, @trimester_enrolled,'en');
UPDATE temp_anc_encs t SET urine_glucose = obs_value_coded_list_from_temp_using_concept_id(encounter_id, @urine_glucose,'en');
UPDATE temp_anc_encs t SET urine_protein = obs_value_coded_list_from_temp_using_concept_id(encounter_id, @urine_protein,'en');
UPDATE temp_anc_encs t SET uses_drugs = obs_value_coded_list_from_temp_using_concept_id(encounter_id, @uses_drugs,'en');
UPDATE temp_anc_encs t SET weight = obs_value_numeric_from_temp_using_concept_id(encounter_id, @weight);
UPDATE temp_anc_encs t
SET other_risk_factors = obs_comments_from_temp(encounter_id, 'PIH','11673','PIH','5622');

-- calculate actual visit count
DROP temporary table if exists temp_visit_counts;
CREATE temporary table temp_visit_counts
SELECT encounter_id, patient_id, pregnancy_program_id, number_anc_visit, encounter_datetime, visit_type
from temp_anc_encs t;

DROP temporary table if exists temp_visit_counts_dup;
CREATE temporary table temp_visit_counts_dup
select * from temp_visit_counts
where visit_type = 'ANC Intake';

create index temp_visit_counts_dup_c1 on temp_visit_counts_dup(patient_id, pregnancy_program_id,encounter_datetime);

UPDATE temp_anc_encs t
inner join temp_visit_counts vc on vc.encounter_id =
	(select encounter_id from temp_visit_counts_dup vc2
	where vc2.patient_id = t.patient_id
	and ifnull(vc2.pregnancy_program_id, 9999999) = ifnull(t.pregnancy_program_id, 9999999)
	and (number_anc_visit is not null and number_anc_visit > 0) 
	and vc2.encounter_datetime <= t.encounter_datetime
	order by encounter_datetime desc, encounter_id desc
	limit 1)
SET latest_entered_number_anc_visit = vc.number_anc_visit;	

UPDATE temp_anc_encs t
set t.actual_visit_number = 
	ifnull(latest_entered_number_anc_visit,1) -1  + 
	(select count(*) from temp_visit_counts vc
	where vc.patient_id = t.patient_id
	and ((vc.pregnancy_program_id = t.pregnancy_program_id)
		or (vc.pregnancy_program_id is null and  t.pregnancy_program_id is null))
	and vc.encounter_datetime <= t.encounter_datetime);

SELECT
concat(@partition,"-",patient_id) as patient_id,
emr_id,
concat(@partition,"-",encounter_id) as encounter_id,
concat(@partition,"-",visit_id)  as visit_id,
concat(@partition,"-",pregnancy_program_id)  as pregnancy_program_id,
encounter_datetime,
encounter_location,
datetime_entered,
user_entered,
provider,
age_at_encounter,
visit_type,
trimester_enrolled,
number_anc_visit,
birth_weight_other_babies,
danger_signs,
high_risk_factors,
other_risk_factors,
prior_neonatal_deaths,
prior_stillbirths,
gravida,
parity,
abortus,
living,
last_menstruation_date,
estimated_delivery_date,
estimated_gestational_age,
return_visit_date,
height,
weight,
bp_systolic,
bp_diastolic,
fundal_height,
fetal_heart_rate,
blood_type,
urine_glucose,
urine_protein,
ferrous_sulfate_folic_acid,
iptp_sp_malaria,
hiv_syphilis_rapid_test,
nutrition_counseling,
hiv_counsel_and_test,
insecticide_treated_net,
smokes_tobacco,
drinks_alcohol,
drinks_per_day,
uses_drugs,
drug_name,
albendazole,
malaria_rdt,
counseled_danger_signs,
llin,
actual_visit_number,
index_asc,
index_desc,
index_asc_patient_program,
index_desc_patient_program
FROM temp_anc_encs;
