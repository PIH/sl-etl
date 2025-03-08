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
datetime_created           datetime,     
user_entered               varchar(255), 
provider                   varchar(255), 
visit_type                 varchar(255), 
trimester_enrollment       varchar(255), 
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
index_asc                  INT,          
index_desc                 INT,
index_asc_patient_program  INT,
index_desc_patient_program INT
);

insert into temp_anc_encs(patient_id, encounter_id, visit_id, encounter_datetime,
datetime_created, user_entered, visit_type)
select patient_id, encounter_id, visit_id, encounter_datetime, date_created, creator, encounter_type_name_from_id(encounter_type)
from encounter e
where e.voided = 0
AND encounter_type IN (@anc_followup, @anc_init)
ORDER BY encounter_datetime desc;

create index temp_labor_encs_ei on temp_anc_encs(encounter_id);

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

DROP TEMPORARY TABLE IF EXISTS temp_obs;
create temporary table temp_obs
select o.obs_id, o.voided ,o.obs_group_id , o.encounter_id, o.person_id, o.concept_id, o.value_coded, o.value_numeric,
o.value_text,o.value_datetime, o.comments, o.date_created, o.obs_datetime
from obs o
inner join temp_anc_encs t on t.encounter_id = o.encounter_id
where o.voided = 0;

create index temp_obs_encs_ei on temp_obs(encounter_id);
create index temp_obs_encs_eobs on temp_obs(encounter_id, obs_group_id);


UPDATE temp_anc_encs t
SET trimester_enrollment = obs_value_coded_list_from_temp(encounter_id, 'PIH','11661','en');

UPDATE temp_anc_encs t
SET danger_signs = obs_value_coded_list_from_temp(encounter_id, 'PIH','3064','en');

UPDATE temp_anc_encs t
SET number_anc_visit = obs_value_numeric_from_temp(encounter_id, 'PIH','13321');

UPDATE temp_anc_encs t
SET birth_weight_other_babies = obs_value_coded_list_from_temp(encounter_id, 'PIH','20072','en');

UPDATE temp_anc_encs t
SET high_risk_factors = obs_value_coded_list_from_temp(encounter_id, 'PIH','11673','en');

UPDATE temp_anc_encs t
SET other_risk_factors = obs_comments_from_temp(encounter_id, 'PIH','11673','PIH','5622');

UPDATE temp_anc_encs t
SET prior_neonatal_deaths = obs_value_numeric_from_temp(encounter_id, 'PIH','13241');

UPDATE temp_anc_encs t
SET prior_stillbirths = obs_value_numeric_from_temp(encounter_id, 'PIH','13240');

UPDATE temp_anc_encs t
SET gravida = obs_value_numeric_from_temp(encounter_id, 'PIH','5624');

UPDATE temp_anc_encs t
SET parity = obs_value_numeric_from_temp(encounter_id, 'PIH','1053');

UPDATE temp_anc_encs t
SET abortus = obs_value_numeric_from_temp(encounter_id, 'PIH','7012');

UPDATE temp_anc_encs t
SET living = obs_value_numeric_from_temp(encounter_id, 'PIH','11117');

UPDATE temp_anc_encs t
SET last_menstruation_date = obs_value_datetime_from_temp(encounter_id, 'PIH','968');

UPDATE temp_anc_encs t
SET estimated_delivery_date = obs_value_datetime_from_temp(encounter_id, 'PIH','5596');

UPDATE temp_anc_encs t
SET return_visit_date = obs_value_datetime_from_temp(encounter_id, 'PIH','5096');

UPDATE temp_anc_encs t
SET estimated_gestational_age = obs_value_numeric_from_temp(encounter_id, 'PIH','1279');

UPDATE temp_anc_encs t
SET height = obs_value_numeric_from_temp(encounter_id, 'PIH','5090');

UPDATE temp_anc_encs t
SET weight = obs_value_numeric_from_temp(encounter_id, 'PIH','5089');

UPDATE temp_anc_encs t
SET bp_systolic = obs_value_numeric_from_temp(encounter_id, 'PIH','5085');

UPDATE temp_anc_encs t
SET bp_diastolic = obs_value_numeric_from_temp(encounter_id, 'PIH','5086');

UPDATE temp_anc_encs t
SET fundal_height = obs_value_numeric_from_temp(encounter_id, 'PIH','13028');

UPDATE temp_anc_encs t
SET fetal_heart_rate = obs_value_numeric_from_temp(encounter_id, 'PIH','13199');

UPDATE temp_anc_encs t
SET blood_type = obs_value_coded_list_from_temp(encounter_id, 'PIH','300','en');

UPDATE temp_anc_encs t
SET urine_glucose = obs_value_coded_list_from_temp(encounter_id, 'PIH','12292','en');

UPDATE temp_anc_encs t
SET urine_protein = obs_value_coded_list_from_temp(encounter_id, 'PIH','12272','en');

UPDATE temp_anc_encs t
SET ferrous_sulfate_folic_acid = obs_value_coded_as_boolean_from_temp(encounter_id, 'PIH','20073');

UPDATE temp_anc_encs t
SET iptp_sp_malaria = obs_value_coded_as_boolean_from_temp(encounter_id, 'PIH','20074');

UPDATE temp_anc_encs t
SET nutrition_counseling = obs_value_coded_as_boolean_from_temp(encounter_id, 'PIH','12878');

UPDATE temp_anc_encs t
SET insecticide_treated_net = obs_value_coded_as_boolean_from_temp(encounter_id, 'PIH','13053');

UPDATE temp_anc_encs t
SET hiv_counsel_and_test = obs_value_coded_as_boolean_from_temp(encounter_id, 'PIH','11381');

UPDATE temp_anc_encs t
SET smokes_tobacco = obs_value_coded_list_from_temp(encounter_id, 'PIH','2545','en');

UPDATE temp_anc_encs t
SET drinks_alcohol = obs_value_coded_list_from_temp(encounter_id, 'PIH','1552','en');

UPDATE temp_anc_encs t
SET uses_drugs = obs_value_coded_list_from_temp(encounter_id, 'PIH','2546','en');

UPDATE temp_anc_encs t
SET drinks_per_day = obs_value_numeric_from_temp(encounter_id, 'PIH','2246');

UPDATE temp_anc_encs t
SET drug_name = obs_value_text_from_temp(encounter_id, 'PIH','6489');

UPDATE temp_anc_encs t
SET albendazole = obs_value_coded_as_boolean_from_temp(encounter_id, 'PIH','10570');

UPDATE temp_anc_encs t
SET malaria_rdt = obs_value_coded_list_from_temp(encounter_id, 'PIH','11464','en');

UPDATE temp_anc_encs t
SET counseled_danger_signs = obs_value_coded_as_boolean_from_temp(encounter_id, 'PIH','12750');

UPDATE temp_anc_encs t
SET llin = obs_value_coded_as_boolean_from_temp(encounter_id, 'PIH','13053');

SELECT
concat(@partition,"-",patient_id) as patient_id,
emr_id,
concat(@partition,"-",encounter_id) as encounter_id,
concat(@partition,"-",visit_id)  as visit_id,
concat(@partition,"-",pregnancy_program_id)  as pregnancy_program_id,
encounter_datetime,
encounter_location,
datetime_created,
user_entered,
provider,
visit_type,
trimester_enrollment,
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
index_asc,
index_desc,
index_asc_patient_program,
index_desc_patient_program
FROM temp_anc_encs;
