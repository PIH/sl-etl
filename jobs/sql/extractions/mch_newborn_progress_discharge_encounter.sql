set @partition = '${partitionNum}';

SELECT encounter_type_id INTO @newborn_progress_enc FROM encounter_type et WHERE uuid = '7e42e652-89e7-4559-80fd-41f42826c98c';
SELECT encounter_type_id INTO @newborn_discharge_enc FROM encounter_type et WHERE uuid = '153d3182-c76f-4047-b7f2-d83cf967b206';

drop temporary table if exists temp_enc;
create temporary table temp_enc
(
    encounter_id                  int,
    visit_id                      int,
    patient_id                    int,
    emr_id                        varchar(255),
    encounter_datetime            datetime,
    encounter_location            varchar(255),
    datetime_entered              datetime,
    user_entered                  varchar(255),
    provider                      varchar(255),
    visit_type                    varchar(255),
    rbg                           decimal(8, 3),
    umbilical_cord                varchar(255),
    eyes                          varchar(255),
    skin_color                    varchar(255),
    urination                     varchar(255),
    stool                         varchar(255),
    feeding_method                varchar(255),
    weight                        decimal(8, 3),
    temperature                   int,
    heart_rate                    int,
    eye_drops                     bit,
    umbilical_cord_care           bit,
    vitamin_k                     bit,
    disposition                   varchar(255),
    transfer_in_location_newborn  varchar(255),
    transfer_in_location          varchar(255),
    transfer_out_location_newborn varchar(255),
    transfer_out_location         varchar(255),
    transfer_location             varchar(255),
    death_date                    datetime,
    index_asc                     INT,
    index_desc                    INT
);

insert into temp_enc (patient_id, encounter_id, visit_id, encounter_datetime, datetime_entered, user_entered, visit_type)
select patient_id, encounter_id, visit_id, encounter_datetime, date_created, creator, if(encounter_type = @newborn_progress_enc, 'Daily assessment', 'Discharge')
from encounter e
where e.voided = 0
AND encounter_type IN (@newborn_progress_enc, @newborn_discharge_enc)
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

UPDATE temp_enc t SET rbg = obs_value_numeric_from_temp(encounter_id, 'CIEL','887');
UPDATE temp_enc t SET umbilical_cord = obs_value_coded_list_from_temp(encounter_id, 'CIEL','162121','en');
UPDATE temp_enc t SET eyes = obs_value_coded_list_from_temp(encounter_id, 'CIEL','163309','en');
UPDATE temp_enc t SET skin_color = obs_value_coded_list_from_temp(encounter_id, 'CIEL','168721','en');
UPDATE temp_enc t SET urination = obs_value_coded_list_from_temp(encounter_id, 'CIEL','166358','en');
UPDATE temp_enc t SET stool = obs_value_coded_list_from_temp(encounter_id, 'CIEL','163640','en');
UPDATE temp_enc t SET feeding_method = obs_value_coded_list_from_temp(encounter_id, 'CIEL','1151','en');
UPDATE temp_enc t SET weight = obs_value_numeric_from_temp(encounter_id, 'CIEL','5089');
UPDATE temp_enc t SET temperature = obs_value_numeric_from_temp(encounter_id, 'CIEL','5088');
UPDATE temp_enc t SET heart_rate = obs_value_numeric_from_temp(encounter_id, 'CIEL','5087');
UPDATE temp_enc t SET eye_drops = answer_exists_in_encounter(encounter_id, 'CIEL','1651','CIEL','168724');
UPDATE temp_enc t SET umbilical_cord_care = answer_exists_in_encounter(encounter_id, 'CIEL','1651','CIEL','168725');
UPDATE temp_enc t SET vitamin_k = answer_exists_in_encounter(encounter_id, 'PIH','SUPPLEMENT RECEIVED','CIEL','86352');
UPDATE temp_enc t SET disposition = obs_value_coded_list_from_temp(encounter_id, 'PIH','8620','en');
UPDATE temp_enc t SET transfer_in_location_newborn = obs_value_coded_list_from_temp(encounter_id, 'PIH','15175','en'); -- transferWithinHospitalNewborn
UPDATE temp_enc t SET transfer_in_location = obs_value_coded_list_from_temp(encounter_id, 'PIH','14973','en'); -- transferWithinHospital
UPDATE temp_enc t SET transfer_out_location_newborn = obs_value_coded_list_from_temp(encounter_id, 'PIH','15177','en'); -- transferOutOfHospitalNewborn
UPDATE temp_enc t SET transfer_out_location = obs_value_coded_list_from_temp(encounter_id, 'PIH','14424','en'); -- transferOutOfHospital
UPDATE temp_enc t SET transfer_location = COALESCE(transfer_in_location_newborn, transfer_out_location_newborn, transfer_in_location, transfer_out_location);
UPDATE temp_enc t SET death_date = obs_value_datetime_from_temp(encounter_id, 'PIH','14399');

SELECT
    concat(@partition, '-', encounter_id) as encounter_id,
    concat(@partition, '-', visit_id) as visit_id,
    concat(@partition, '-', patient_id) as patient_id,
    emr_id,
    encounter_datetime,
    encounter_location,
    datetime_entered,
    user_entered,
    provider,
    visit_type,
    rbg,
    umbilical_cord,
    eyes,
    skin_color,
    urination,
    stool,
    feeding_method,
    weight,
    temperature,
    heart_rate,
    eye_drops,
    umbilical_cord_care,
    vitamin_k,
    disposition,
    transfer_location,
    death_date,
    index_asc,
    index_desc
FROM temp_enc;
