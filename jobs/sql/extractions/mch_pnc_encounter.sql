set @partition = '${partitionNum}';

SELECT encounter_type_id  INTO @pnc_followup
FROM encounter_type et WHERE uuid='b7a7c300-f7e5-4d38-a388-fc178ab02e78';

set @pregnancyProgramId = program('Pregnancy');

DROP TEMPORARY TABLE IF EXISTS temp_anc_encs;
CREATE TEMPORARY TABLE temp_anc_encs (
  patient_id                  INT,
  emr_id                      VARCHAR(255),
  encounter_id                INT,
  visit_id                    INT,
  pregnancy_program_id        INT,
  encounter_datetime          DATETIME,
  encounter_location          VARCHAR(255),
  datetime_entered            DATETIME,
  user_entered                VARCHAR(255),
  provider                    VARCHAR(255),
  visit_type                  VARCHAR(255),
  age_at_encounter            INT,
  delivery_datetime           DATETIME,
  danger_signs                TEXT,
  high_risk_factors           TEXT,
  other_risk_factors          TEXT,
  return_visit_date           DATE,
  bp_systolic                 INT,
  bp_diastolic                INT,
  heart_rate                  DOUBLE,
  respiratory_rate            DOUBLE,
  o2_saturation               DOUBLE,
  temperature                 DOUBLE,
  urine_glucose               VARCHAR(255),
  urine_protein               VARCHAR(255),
  ferrous_sulfate_folic_acid  BOOLEAN,
  hiv_syphilis_rapid_test     VARCHAR(255),
  hep_b                       VARCHAR(255),                
  sickling                    VARCHAR(255),
  urine_hcg                   VARCHAR(255),
  iptp_sp_malaria             BOOLEAN,
  nutrition_counseling        BOOLEAN,
  hiv_counsel_and_test        BOOLEAN,
  albendazole                 BOOLEAN,
  malaria_rdt                 VARCHAR(255),
  counseled_danger_signs      BOOLEAN,
  llin                        BOOLEAN,
  family_planning_counselling VARCHAR(255),
  family_planning_accepted    VARCHAR(255),
  family_planning_method      VARCHAR(255),
  disposition                 VARCHAR(255),
  disposition_location        VARCHAR(255),
  index_asc                   INT,
  index_desc                  INT,
  index_asc_patient_program   INT,
  index_desc_patient_program  INT
);

insert into temp_anc_encs(patient_id, encounter_id, visit_id, encounter_datetime,
datetime_entered, user_entered, visit_type)
select patient_id, encounter_id, visit_id, encounter_datetime, date_created, creator, encounter_type_name_from_id(encounter_type)
from encounter e
where e.voided = 0
AND encounter_type IN (@pnc_followup)
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

SET @albendazole = concept_from_mapping('PIH','10570');
SET @bp_diastolic = concept_from_mapping('PIH','5086');
SET @bp_systolic = concept_from_mapping('PIH','5085');
SET @counseled_danger_signs = concept_from_mapping('PIH','12750');
SET @danger_signs = concept_from_mapping('PIH','3064');
SET @ferrous_sulfate_folic_acid = concept_from_mapping('PIH','20073');
SET @high_risk_factors = concept_from_mapping('PIH','11673');
SET @hiv_counsel_and_test = concept_from_mapping('PIH','11381');
SET @hiv_syphilis_rapid_test = concept_from_mapping('PIH','20762');
SET @iptp_sp_malaria = concept_from_mapping('PIH','20074');
SET @llin = concept_from_mapping('PIH','13053');
SET @malaria_rdt = concept_from_mapping('PIH','11464');
SET @nutrition_counseling = concept_from_mapping('PIH','12878');
SET @return_visit_date = concept_from_mapping('PIH','5096');
SET @urine_glucose = concept_from_mapping('PIH','12292');
SET @urine_protein = concept_from_mapping('PIH','12272');
SET @family_planning_counselling = concept_from_mapping('CIEL','1382');
SET @family_planning_accepted = concept_from_mapping('CIEL','166421');
SET @family_planning_method = concept_from_mapping('CIEL','374');
SET @delivery_datetime = concept_from_mapping('CIEL','5599');
SET @temp =  concept_from_mapping('PIH', '5088');
SET @hr =  concept_from_mapping('PIH', '5087');
SET @rr =  concept_from_mapping('PIH', '5242');
SET @o2 =  concept_from_mapping('PIH', '5092');
SET @hep_b =  concept_from_mapping('PIH', '2439');
SET @sickling =  concept_from_mapping('PIH', '11420');
SET @urine_hcg =  concept_from_mapping('PIH', '45');
SET @disposition = concept_from_mapping('PIH', '8620');
SET @disposition_location = concept_from_mapping('PIH', '14424');

UPDATE temp_anc_encs t SET heart_rate = obs_value_numeric_from_temp_using_concept_id(encounter_id, @hr);
UPDATE temp_anc_encs t SET respiratory_rate = obs_value_numeric_from_temp_using_concept_id(encounter_id, @rr);
UPDATE temp_anc_encs t SET o2_saturation = obs_value_numeric_from_temp_using_concept_id(encounter_id, @o2);
UPDATE temp_anc_encs t SET temperature = obs_value_numeric_from_temp_using_concept_id(encounter_id, @temp);
UPDATE temp_anc_encs t SET delivery_datetime = obs_value_datetime_from_temp_using_concept_id(encounter_id, @delivery_datetime);
UPDATE temp_anc_encs t SET albendazole = obs_value_coded_as_boolean_from_temp_using_concept_id(encounter_id, @albendazole);
UPDATE temp_anc_encs t SET bp_diastolic = obs_value_numeric_from_temp_using_concept_id(encounter_id, @bp_diastolic);
UPDATE temp_anc_encs t SET bp_systolic = obs_value_numeric_from_temp_using_concept_id(encounter_id, @bp_systolic);
UPDATE temp_anc_encs t SET counseled_danger_signs = obs_value_coded_as_boolean_from_temp_using_concept_id(encounter_id, @counseled_danger_signs);
UPDATE temp_anc_encs t SET danger_signs = obs_value_coded_list_from_temp_using_concept_id(encounter_id, @danger_signs,'en');
UPDATE temp_anc_encs t SET ferrous_sulfate_folic_acid = obs_value_coded_as_boolean_from_temp_using_concept_id(encounter_id, @ferrous_sulfate_folic_acid);
UPDATE temp_anc_encs t SET high_risk_factors = obs_value_coded_list_from_temp_using_concept_id(encounter_id, @high_risk_factors,'en');
UPDATE temp_anc_encs t SET hiv_counsel_and_test = obs_value_coded_as_boolean_from_temp_using_concept_id(encounter_id, @hiv_counsel_and_test);
UPDATE temp_anc_encs t SET hiv_syphilis_rapid_test = obs_value_coded_list_from_temp_using_concept_id(encounter_id, @hiv_syphilis_rapid_test,'en');
UPDATE temp_anc_encs t SET iptp_sp_malaria = obs_value_coded_as_boolean_from_temp_using_concept_id(encounter_id, @iptp_sp_malaria);
UPDATE temp_anc_encs t SET llin = obs_value_coded_as_boolean_from_temp_using_concept_id(encounter_id, @llin);
UPDATE temp_anc_encs t SET malaria_rdt = obs_value_coded_list_from_temp_using_concept_id(encounter_id, @malaria_rdt,'en');
UPDATE temp_anc_encs t SET nutrition_counseling = obs_value_coded_as_boolean_from_temp_using_concept_id(encounter_id, @nutrition_counseling);
UPDATE temp_anc_encs t SET return_visit_date = obs_value_datetime_from_temp_using_concept_id(encounter_id, @return_visit_date);
UPDATE temp_anc_encs t SET urine_glucose = obs_value_coded_list_from_temp_using_concept_id(encounter_id, @urine_glucose,'en');
UPDATE temp_anc_encs t SET urine_protein = obs_value_coded_list_from_temp_using_concept_id(encounter_id, @urine_protein,'en');
UPDATE temp_anc_encs t SET urine_hcg = obs_value_coded_list_from_temp_using_concept_id(encounter_id, @urine_hcg,'en');
UPDATE temp_anc_encs t SET sickling = obs_value_coded_list_from_temp_using_concept_id(encounter_id, @sickling,'en');
UPDATE temp_anc_encs t SET hep_b = obs_value_coded_list_from_temp_using_concept_id(encounter_id, @hep_b,'en');
UPDATE temp_anc_encs t SET other_risk_factors = obs_comments_from_temp(encounter_id, 'PIH','11673','PIH','5622');
UPDATE temp_anc_encs t SET family_planning_counselling = obs_value_coded_list_from_temp_using_concept_id(encounter_id, @family_planning_counselling,'en');
UPDATE temp_anc_encs t SET family_planning_accepted = obs_value_coded_list_from_temp_using_concept_id(encounter_id, @family_planning_accepted,'en');
UPDATE temp_anc_encs t SET family_planning_method = obs_value_coded_list_from_temp_using_concept_id(encounter_id, @family_planning_method,'en');
UPDATE temp_anc_encs t SET disposition = obs_value_coded_list_from_temp_using_concept_id(encounter_id, @disposition,'en');
UPDATE temp_anc_encs t SET disposition_location = obs_value_coded_list_from_temp_using_concept_id(encounter_id, @disposition_location,'en');

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
delivery_datetime,
bp_systolic,
bp_diastolic,
temperature,
heart_rate,
respiratory_rate,
o2_saturation,
danger_signs,
high_risk_factors,
other_risk_factors,
urine_glucose,
urine_protein,
urine_hcg,
hep_b,
sickling,
ferrous_sulfate_folic_acid,
iptp_sp_malaria,
hiv_syphilis_rapid_test,
nutrition_counseling,
hiv_counsel_and_test,
albendazole,
malaria_rdt,
counseled_danger_signs,
llin,
family_planning_counselling,
family_planning_accepted,
family_planning_method,
disposition,
disposition_location,
return_visit_date,
index_asc,
index_desc,
index_asc_patient_program,
index_desc_patient_program
FROM temp_anc_encs;
