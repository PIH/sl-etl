set @partition = '${partitionNum}';

SELECT encounter_type_id INTO @admission_note FROM encounter_type et WHERE uuid = '260566e1-c909-4d61-a96f-c1019291a09d';
SELECT encounter_role_id INTO @consulting_clinician FROM encounter_role where uuid = '4f10ad1a-ec49-48df-98c7-1391c6ac7f05';

drop temporary table if exists temp_enc;
create temporary table temp_enc
(
    encounter_id             int,
    visit_id                 int,
    patient_id               int,
    emr_id                   varchar(255),
    encounter_datetime       datetime,
    encounter_location       varchar(255),
    datetime_entered         datetime,
    user_entered             varchar(255),
    provider                 varchar(255),
    admitting_clinician      varchar(255),
    admitted_to              varchar(255),
    admission_date           datetime,
    index_asc                INT,
    index_desc               INT
);

insert into temp_enc(patient_id, encounter_id, visit_id, encounter_datetime, datetime_entered, user_entered)
select patient_id, encounter_id, visit_id, encounter_datetime, date_created, creator
from encounter e
where e.voided = 0
AND encounter_type IN (@admission_note)
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

UPDATE temp_enc t SET admitting_clinician = provider_name_of_type(encounter_id, @consulting_clinician, 0);
UPDATE temp_enc t SET admitted_to = encounter_location;
UPDATE temp_enc t SET admission_date = encounter_datetime;

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
    admitting_clinician,
    admitted_to,
    admission_date,
    index_asc,
    index_desc
FROM temp_enc;
