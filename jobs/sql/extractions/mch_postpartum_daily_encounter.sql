set @partition = '${partitionNum}';

SELECT encounter_type_id INTO @postpartum_daily_enc FROM encounter_type et WHERE uuid = '37f04ddf-9653-4a02-98b4-1c23734c2f15';
set @pregnancyProgramId = program('Pregnancy');

drop temporary table if exists temp_enc;
create temporary table temp_enc
(
    encounter_id                  int,
    visit_id                      int,
    patient_id                    int,
    emr_id                        varchar(255),
    pregnancy_program_id          int,
    encounter_datetime            datetime,
    encounter_location            varchar(255),
    datetime_entered              datetime,
    user_entered                  varchar(255),
    age_at_encounter              int,
    provider                      varchar(255),
    temperature                   decimal(8, 3),
    heart_rate                    int,
    bp_systolic                   int,
    bp_diastolic                  int,
    respiratory_rate              int,
    o2_saturation                 int,
    hemoglobin                    decimal(8, 3),
    glucose                       decimal(8, 3),
    contact_doctor_vitals_alert   bit,
    days_since_delivery           int,
    lochia_color                  varchar(255),
    lochia_odor                   varchar(255),
    lochia_quantity               varchar(255),
    postpartum_hemorrhage         bit,
    oxytocin_for_hemorrhage       bit,
    misoprostol_for_hemorrhage    bit,
    bimanual_compression_for_hemorrhage  bit,
    aortic_compression_for_hemorrhage    bit,
    balloon_tamponade_for_hemorrhage     bit,
    tranexamic_acid_for_hemorrhage       bit,
    sepsis                        bit,
    postpartum_mental_disorder    bit,
    fever_over_38                 bit,
    mastitis                      bit,
    severe_headache               bit,
    malaria                       bit,
    postpartum_eclampsia          bit,
    other_postpartum_complication bit,
    other_postpartum_complication_specify text,
    pads_used_group_id            int,
    number_pads_used              int,
    pads_used_unit                varchar(255),
    involution_of_uterus          varchar(255),
    uterus_level_from_umbilicus   decimal(8, 3),
    palpation_of_uterus           varchar(255),
    exam_comments                 text,
    cesarean_wound                varchar(255),
    intact_perineum               varchar(255),
    perineum_wound_infection      varchar(255),
    breast_observations           varchar(255),
    mood                          varchar(255),
    bowels                        varchar(255),
    urination                     varchar(255),
    urination_comments            text,
    leg_pain_present              bit,
    leg_pain_absent               bit,
    leg_pain                      varchar(255),
    pain_level                    int,
    phq2_score                    int,
    family_planning_counselling   varchar(255),
    family_planning_accepted      varchar(255),
    family_planning_method        varchar(255),
    female_condoms                int,
    male_condoms                  int,
    iud_insertion_date            datetime,
    implant_type                  varchar(255),
    placement_date                datetime,
    breastfeeding_education       bit,
    danger_signs_education        bit,
    disposition                   varchar(255),
    summary_notes                 text,
    index_asc                     INT,
    index_desc                    INT
);

insert into temp_enc (patient_id, encounter_id, visit_id, encounter_datetime, datetime_entered, user_entered)
select patient_id, encounter_id, visit_id, encounter_datetime, date_created, creator
from encounter e
where e.voided = 0
AND encounter_type IN (@postpartum_daily_enc)
ORDER BY encounter_datetime desc;

create index temp_enc_ei on temp_enc (encounter_id);

UPDATE temp_enc set user_entered = person_name_of_user(user_entered);
UPDATE temp_enc SET provider = provider(encounter_id);
UPDATE temp_enc t SET emr_id = patient_identifier(patient_id, 'c09a1d24-7162-11eb-8aa6-0242ac110002');
UPDATE temp_enc SET encounter_location=encounter_location_name(encounter_id);

DROP TEMPORARY TABLE IF EXISTS temp_obs;
create temporary table temp_obs
select o.obs_id, o.voided, o.obs_group_id, o.encounter_id, o.person_id, o.concept_id, o.value_coded, o.value_numeric,
       o.value_text,o.value_datetime, o.comments, o.date_created, o.obs_datetime
from obs o
inner join temp_enc t on t.encounter_id = o.encounter_id
where o.voided = 0;

create index temp_obs_encs_ei on temp_obs(encounter_id);
create index temp_obs_encs_eobs on temp_obs(encounter_id, obs_group_id);

UPDATE temp_enc t SET temperature = obs_value_numeric_from_temp(encounter_id, 'CIEL','5088');
UPDATE temp_enc t SET heart_rate = obs_value_numeric_from_temp(encounter_id, 'CIEL','5087');
UPDATE temp_enc t SET bp_systolic = obs_value_numeric_from_temp(encounter_id, 'CIEL','5085');
UPDATE temp_enc t SET bp_diastolic = obs_value_numeric_from_temp(encounter_id, 'CIEL','5086');
UPDATE temp_enc t SET respiratory_rate = obs_value_numeric_from_temp(encounter_id, 'CIEL','5242');
UPDATE temp_enc t SET o2_saturation = obs_value_numeric_from_temp(encounter_id, 'CIEL','5092');
UPDATE temp_enc t SET hemoglobin = obs_value_numeric_from_temp(encounter_id, 'CIEL','21');
UPDATE temp_enc t SET glucose = obs_value_numeric_from_temp(encounter_id, 'CIEL','1458');
UPDATE temp_enc t SET contact_doctor_vitals_alert = answer_exists_in_encounter_temp(encounter_id, 'PIH','20925','CIEL','1065');
UPDATE temp_enc t SET days_since_delivery = obs_value_numeric_from_temp(encounter_id, 'CIEL','1879');
UPDATE temp_enc t SET lochia_color = obs_value_coded_list_from_temp(encounter_id, 'CIEL','159721','en');
UPDATE temp_enc t SET lochia_odor = obs_value_coded_list_from_temp(encounter_id, 'PIH','14062','en');
UPDATE temp_enc t SET lochia_quantity = obs_value_coded_list_from_temp(encounter_id, 'CIEL','167042','en');
UPDATE temp_enc t SET postpartum_hemorrhage = answer_exists_in_encounter(encounter_id, 'CIEL','163208','CIEL','230');
-- postpartum complications (CIEL:163208)
UPDATE temp_enc t SET sepsis = answer_exists_in_encounter_temp(encounter_id, 'CIEL','163208','CIEL','126721');
UPDATE temp_enc t SET postpartum_mental_disorder = answer_exists_in_encounter_temp(encounter_id, 'CIEL','163208','CIEL','115812');
UPDATE temp_enc t SET fever_over_38 = answer_exists_in_encounter_temp(encounter_id, 'CIEL','163208','CIEL','140238');
UPDATE temp_enc t SET mastitis = answer_exists_in_encounter_temp(encounter_id, 'CIEL','163208','CIEL','115914');
UPDATE temp_enc t SET severe_headache = answer_exists_in_encounter_temp(encounter_id, 'CIEL','163208','CIEL','139081');
UPDATE temp_enc t SET malaria = answer_exists_in_encounter_temp(encounter_id, 'CIEL','163208','CIEL','134592');
UPDATE temp_enc t SET postpartum_eclampsia = answer_exists_in_encounter_temp(encounter_id, 'CIEL','163208','CIEL','141540');
UPDATE temp_enc t SET other_postpartum_complication = answer_exists_in_encounter_temp(encounter_id, 'CIEL','163208','CIEL','5622');
UPDATE temp_enc t SET other_postpartum_complication_specify = obs_value_text_from_temp(encounter_id, 'PIH','13094');
-- postpartum haemorrhage treatment (PIH:20865) - answer concepts match the form
UPDATE temp_enc t SET oxytocin_for_hemorrhage = answer_exists_in_encounter_temp(encounter_id, 'PIH','20865','CIEL','81369');
UPDATE temp_enc t SET misoprostol_for_hemorrhage = answer_exists_in_encounter_temp(encounter_id, 'PIH','20865','CIEL','79984');
UPDATE temp_enc t SET bimanual_compression_for_hemorrhage = answer_exists_in_encounter_temp(encounter_id, 'PIH','20865','CIEL','169674');
UPDATE temp_enc t SET aortic_compression_for_hemorrhage = answer_exists_in_encounter_temp(encounter_id, 'PIH','20865','CIEL','169675');
UPDATE temp_enc t SET balloon_tamponade_for_hemorrhage = answer_exists_in_encounter_temp(encounter_id, 'PIH','20865','CIEL','164162');
UPDATE temp_enc t SET tranexamic_acid_for_hemorrhage = answer_exists_in_encounter_temp(encounter_id, 'PIH','20865','CIEL','85286');
UPDATE temp_enc t SET pads_used_group_id = obs_group_id_from_temp(encounter_id, 'CIEL','166895', 0);
UPDATE temp_enc t SET number_pads_used = obs_from_group_id_value_numeric_from_temp(pads_used_group_id, 'CIEL','166895');
UPDATE temp_enc t SET pads_used_unit = obs_from_group_id_value_coded_list_from_temp(pads_used_group_id, 'PIH','TIME UNITS','en');
UPDATE temp_enc t SET involution_of_uterus = obs_value_coded_list_from_temp(encounter_id, 'CIEL','167038','en');
UPDATE temp_enc t SET uterus_level_from_umbilicus = obs_value_numeric_from_temp(encounter_id, 'PIH','14063');
UPDATE temp_enc t SET palpation_of_uterus = obs_value_coded_list_from_temp(encounter_id, 'CIEL','167035','en');
UPDATE temp_enc t SET exam_comments = obs_value_text_from_temp(encounter_id, 'PIH','14053');
UPDATE temp_enc t SET cesarean_wound = obs_value_coded_list_from_temp(encounter_id, 'CIEL','162128','en');
UPDATE temp_enc t SET intact_perineum = obs_value_coded_list_from_temp(encounter_id, 'CIEL','160089','en');
UPDATE temp_enc t SET perineum_wound_infection = obs_value_coded_list_from_temp(encounter_id, 'PIH','14065','en');
UPDATE temp_enc t SET breast_observations = obs_value_coded_list_from_temp(encounter_id, 'CIEL','159780','en');
UPDATE temp_enc t SET mood = obs_value_coded_list_from_temp(encounter_id, 'CIEL','167099','en');
UPDATE temp_enc t SET bowels = obs_value_coded_list_from_temp(encounter_id, 'CIEL','163188','en');
UPDATE temp_enc t SET urination = obs_value_coded_list_from_temp(encounter_id, 'CIEL','166358','en');
UPDATE temp_enc t SET urination_comments = obs_value_text_from_temp(encounter_id, 'CIEL','166363');
UPDATE temp_enc t SET leg_pain_present = answer_exists_in_encounter(encounter_id, 'PIH','SYMPTOM PRESENT','CIEL','114395');
UPDATE temp_enc t SET leg_pain_absent = answer_exists_in_encounter(encounter_id, 'PIH','SYMPTOM ABSENT','CIEL','114395');
UPDATE temp_enc t SET leg_pain = if(leg_pain_present, 'Yes', if(leg_pain_absent, 'No', null));
UPDATE temp_enc t SET pain_level = obs_value_numeric_from_temp(encounter_id, 'PIH','Pain Score');
UPDATE temp_enc t SET phq2_score = obs_value_numeric_from_temp(encounter_id, 'PIH','PHQ-2');
UPDATE temp_enc t SET family_planning_counselling = obs_value_coded_list_from_temp(encounter_id, 'CIEL','1382','en');
UPDATE temp_enc t SET family_planning_accepted = obs_value_coded_list_from_temp(encounter_id, 'CIEL','166421','en');
UPDATE temp_enc t SET family_planning_method = obs_value_coded_list_from_temp(encounter_id, 'CIEL','374','en');
UPDATE temp_enc t SET female_condoms = obs_value_numeric_from_temp(encounter_id, 'PIH','21758');
UPDATE temp_enc t SET male_condoms = obs_value_numeric_from_temp(encounter_id, 'PIH','21757');
UPDATE temp_enc t SET iud_insertion_date = obs_value_datetime_from_temp(encounter_id, 'PIH','21759');
UPDATE temp_enc t SET implant_type = obs_value_coded_list_from_temp(encounter_id, 'CIEL','163401','en');
UPDATE temp_enc t SET placement_date = obs_value_datetime_from_temp(encounter_id, 'PIH','3203');
UPDATE temp_enc t SET breastfeeding_education = obs_value_coded_as_boolean_from_temp(encounter_id, 'CIEL','1910');
UPDATE temp_enc t SET danger_signs_education = obs_value_coded_as_boolean_from_temp(encounter_id, 'CIEL','161541');
UPDATE temp_enc t SET disposition = obs_value_coded_list_from_temp(encounter_id, 'CIEL','160116','en');
UPDATE temp_enc t SET summary_notes = obs_value_text_from_temp(encounter_id, 'CIEL','161011');

UPDATE temp_enc SET pregnancy_program_id = patient_program_id_from_encounter(patient_id, @pregnancyProgramId ,encounter_id);
UPDATE temp_enc SET age_at_encounter = AGE_AT_ENC(patient_id, encounter_id);
SELECT
    concat(@partition, '-', encounter_id) as encounter_id,
    concat(@partition, '-', visit_id) as visit_id,
    concat(@partition, '-', patient_id) as patient_id,
    concat(@partition, '-', pregnancy_program_id) as pregnancy_program_id,    
    emr_id,
    encounter_datetime,
    encounter_location,
    datetime_entered,
    user_entered,
    provider,
    age_at_encounter,
    temperature,
    heart_rate,
    bp_systolic,
    bp_diastolic,
    respiratory_rate,
    o2_saturation,
    hemoglobin,
    glucose,
    contact_doctor_vitals_alert,
    days_since_delivery,
    lochia_color,
    lochia_odor,
    lochia_quantity,
    postpartum_hemorrhage,
    oxytocin_for_hemorrhage,
    misoprostol_for_hemorrhage,
    bimanual_compression_for_hemorrhage,
    aortic_compression_for_hemorrhage,
    balloon_tamponade_for_hemorrhage,
    tranexamic_acid_for_hemorrhage,
    sepsis,
    postpartum_mental_disorder,
    fever_over_38,
    mastitis,
    severe_headache,
    malaria,
    postpartum_eclampsia,
    other_postpartum_complication,
    other_postpartum_complication_specify,
    number_pads_used,
    pads_used_unit,
    involution_of_uterus,
    uterus_level_from_umbilicus,
    palpation_of_uterus,
    exam_comments,
    cesarean_wound,
    intact_perineum,
    perineum_wound_infection,
    breast_observations,
    mood,
    bowels,
    urination,
    urination_comments,
    leg_pain,
    pain_level,
    phq2_score,
    family_planning_counselling,
    family_planning_accepted,
    family_planning_method,
    female_condoms,
    male_condoms,
    iud_insertion_date,
    implant_type,
    placement_date,
    breastfeeding_education,
    danger_signs_education,
    disposition,
    summary_notes,
    index_asc,
    index_desc
FROM temp_enc;
