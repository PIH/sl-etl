set @partition = '${partitionNum}';

SELECT encounter_type_id  INTO @newborn_assessment FROM encounter_type et WHERE uuid = '6444b8d4-407d-444d-aa15-d6dff204ed83';

drop temporary table if exists temp_enc;
create temporary table temp_enc
(
    encounter_id             int,
    visit_id                 int,
    patient_id               int,
    emr_id                   varchar(255),
    encounter_datetime       datetime,
    encounter_location       varchar(255),
    datetime_created         datetime,
    user_entered             varchar(255),
    provider                 varchar(255),
    pregnancy_complications  varchar(5000),
    delivery_datetime        datetime,
    gestation_age            decimal(8, 3),
    delivery_type            varchar(255),
    delivery_outcome         varchar(255),
    sex                      varchar(255),
    birth_weight             decimal(8, 3),
    birth_length             decimal(8, 3),
    birth_head_circumference decimal(8, 3),
    apgar_1_min              int,
    apgar_5_min              int,
    apgar_10_min             int,
    multiple_birth           bit,
    temperature              int,
    heart_rate               int,
    bp_systolic              int,
    bp_diastolic             int,
    respiratory_rate         int,
    o2_saturation            int,
    neonatal_resuscitation   bit,
    resuscitation_type       varchar(255),
    diagnosis_at_birth       varchar(255),
    birth_injury             bit,
    overall_condition        varchar(255),
    disposition              varchar(255),
    transfer_in_location     varchar(255),
    transfer_out_location    varchar(255),
    transfer_location        varchar(255),
    death_date               datetime,
    index_asc                INT,
    index_desc               INT
);

insert into temp_enc(patient_id, encounter_id, visit_id, encounter_datetime, datetime_created, user_entered)
select patient_id, encounter_id, visit_id, encounter_datetime, date_created, creator
from encounter e
where e.voided = 0
AND encounter_type IN (@newborn_assessment)
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

UPDATE temp_enc t SET pregnancy_complications = obs_value_coded_list_from_temp(encounter_id, 'PIH','3334','en');
UPDATE temp_enc t SET delivery_datetime = obs_value_datetime_from_temp(encounter_id, 'CIEL','5599');
UPDATE temp_enc t SET gestation_age = obs_value_numeric_from_temp(encounter_id, 'CIEL','165425');
UPDATE temp_enc t SET delivery_type = obs_value_coded_list_from_temp(encounter_id, 'PIH','11663','en');
UPDATE temp_enc t SET delivery_outcome = obs_value_coded_list_from_temp(encounter_id, 'CIEL','159917','en');
UPDATE temp_enc t SET sex = obs_value_coded_list_from_temp(encounter_id, 'CIEL','1587','en');
UPDATE temp_enc t SET birth_weight = obs_value_numeric_from_temp(encounter_id, 'CIEL','5916');
UPDATE temp_enc t SET birth_length = obs_value_numeric_from_temp(encounter_id, 'CIEL','163554');
UPDATE temp_enc t SET birth_head_circumference = obs_value_numeric_from_temp(encounter_id, 'CIEL','163555');
UPDATE temp_enc t SET apgar_1_min = obs_value_numeric_from_temp(encounter_id, 'PIH','14419');
UPDATE temp_enc t SET apgar_5_min = obs_value_numeric_from_temp(encounter_id, 'CIEL','159604');
UPDATE temp_enc t SET apgar_10_min = obs_value_numeric_from_temp(encounter_id, 'PIH','14785');
UPDATE temp_enc t SET multiple_birth = answer_exists_in_encounter(encounter_id, 'PIH','DIAGNOSIS','CIEL','115491');
UPDATE temp_enc t SET temperature = obs_value_numeric_from_temp(encounter_id, 'CIEL','5088');
UPDATE temp_enc t SET heart_rate = obs_value_numeric_from_temp(encounter_id, 'CIEL','5087');
UPDATE temp_enc t SET bp_systolic = obs_value_numeric_from_temp(encounter_id, 'CIEL','5085');
UPDATE temp_enc t SET bp_diastolic = obs_value_numeric_from_temp(encounter_id, 'CIEL','5086');
UPDATE temp_enc t SET respiratory_rate = obs_value_numeric_from_temp(encounter_id, 'CIEL','5242');
UPDATE temp_enc t SET o2_saturation = obs_value_numeric_from_temp(encounter_id, 'CIEL','5092');
UPDATE temp_enc t SET neonatal_resuscitation = obs_value_coded_as_boolean_from_temp(encounter_id, 'CIEL','162131');
UPDATE temp_enc t SET resuscitation_type = obs_value_coded_list_from_temp(encounter_id, 'CIEL','165995','en');
UPDATE temp_enc t SET diagnosis_at_birth = obs_value_coded_list_from_temp(encounter_id, 'PIH','DIAGNOSIS','en');
UPDATE temp_enc t SET birth_injury = obs_value_coded_as_boolean_from_temp(encounter_id, 'CIEL','147277');
UPDATE temp_enc t SET overall_condition = obs_value_coded_list_from_temp(encounter_id, 'CIEL','160116','en');
UPDATE temp_enc t SET disposition = obs_value_coded_list_from_temp(encounter_id, 'PIH','8620','en');
UPDATE temp_enc t SET transfer_in_location = obs_value_coded_list_from_temp(encounter_id, 'PIH','15175','en'); -- Newborn internal transfer or referral location
UPDATE temp_enc t SET transfer_out_location = obs_value_coded_list_from_temp(encounter_id, 'PIH','15177','en'); -- Newborn transfer out locations
UPDATE temp_enc t SET transfer_location = COALESCE(transfer_in_location, transfer_out_location);
UPDATE temp_enc t SET death_date = obs_value_datetime_from_temp(encounter_id, 'PIH','14399');

SELECT
    concat(@partition, '-', encounter_id) as encounter_id,
    concat(@partition, '-', visit_id) as visit_id,
    concat(@partition, '-', patient_id) as patient_id,
    emr_id,
    encounter_datetime,
    encounter_location,
    datetime_created,
    user_entered,
    provider,
    pregnancy_complications,
    delivery_datetime,
    gestation_age,
    delivery_type,
    delivery_outcome,
    sex,
    birth_weight,
    birth_length,
    birth_head_circumference,
    apgar_1_min,
    apgar_5_min,
    apgar_10_min,
    multiple_birth,
    temperature,
    heart_rate,
    bp_systolic,
    bp_diastolic,
    respiratory_rate,
    o2_saturation,
    neonatal_resuscitation,
    resuscitation_type,
    diagnosis_at_birth,
    birth_injury,
    overall_condition,
    disposition,
    transfer_location,
    death_date,
    index_asc,
    index_desc
FROM temp_enc;
