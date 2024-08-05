set @partition = '${partitionNum}';

SELECT encounter_type_id  INTO @labor_enc
FROM encounter_type et WHERE uuid='fec2cc56-e35f-42e1-8ae3-017142c1ca59';

drop temporary table if exists temp_labor_encs;
create temporary table temp_labor_encs
(
    patient_id                              int,
    emr_id                                  varchar(255),
    encounter_id                            int,
    visit_id                                int,
    encounter_datetime                      datetime,
    encounter_location                      varchar(255),
    datetime_created                        datetime,
    user_entered                            varchar(255),
    provider                                varchar(255),
    labor_start                             datetime,
    induced_labor                           boolean,
    induction_time                          datetime,
    method_of_induction                     varchar(255),
    t_first_hour                            decimal(8, 3),
    t_first_minute                          decimal(8, 3),
    duration_first_stage                    decimal(8, 3),
    second_stage_start                      varchar(255),
    t_second_hour                           decimal(8, 3),
    t_second_minute                         decimal(8, 3),
    duration_second_stage                   decimal(8, 3),
    multiple_birth                          boolean,
    amtsl                                   boolean,
    visual_inspection_placenta_completeness varchar(255),
    birth_attendant                         varchar(255),
    perineal_tear                           varchar(255),
    perineal_tear_procedure                 varchar(255),
    t_third_hour                            decimal(8, 3),
    t_third_minute                          decimal(8, 3),
    duration_third_stage                    decimal(8, 3),
    total_duration_labor                    int,
    partogram_uploaded                      bit,
    index_asc                               INT,
    index_desc                              INT
);

insert into temp_labor_encs(patient_id, encounter_id, visit_id, encounter_datetime, datetime_created, user_entered)
select patient_id, encounter_id, visit_id, encounter_datetime, date_created, creator
from encounter e
where e.voided = 0
AND encounter_type IN (@labor_enc)
ORDER BY encounter_datetime desc;

create index temp_labor_encs_ei on temp_labor_encs (encounter_id);

UPDATE temp_labor_encs set user_entered = person_name_of_user(user_entered);
UPDATE temp_labor_encs SET provider = provider(encounter_id);
UPDATE temp_labor_encs t SET emr_id = patient_identifier(patient_id, 'c09a1d24-7162-11eb-8aa6-0242ac110002');
UPDATE temp_labor_encs SET encounter_location=encounter_location_name(encounter_id);

DROP TEMPORARY TABLE IF EXISTS temp_obs;
create temporary table temp_obs
select o.obs_id, o.voided ,o.obs_group_id , o.encounter_id, o.person_id, o.concept_id, o.value_coded, o.value_numeric,
o.value_text,o.value_datetime, o.comments, o.date_created, o.obs_datetime
from obs o
inner join temp_labor_encs t on t.encounter_id = o.encounter_id
where o.voided = 0;

create index temp_obs_encs_ei on temp_obs(encounter_id);
create index temp_obs_encs_eobs on temp_obs(encounter_id, obs_group_id);

UPDATE temp_labor_encs t SET labor_start = obs_value_datetime_from_temp(encounter_id, 'PIH','14377');
UPDATE temp_labor_encs t SET induced_labor = obs_value_coded_as_boolean_from_temp(encounter_id, 'PIH','15113');
UPDATE temp_labor_encs t SET induction_time = obs_value_datetime_from_temp(encounter_id, 'PIH','15116');
UPDATE temp_labor_encs t SET method_of_induction = obs_value_coded_list_from_temp(encounter_id, 'PIH','15114','en');
UPDATE temp_labor_encs t SET t_first_hour = obs_value_numeric_from_temp(encounter_id, 'PIH','20114');
UPDATE temp_labor_encs t SET t_first_minute = obs_value_numeric_from_temp(encounter_id, 'PIH','20115');
UPDATE temp_labor_encs t SET duration_first_stage = t_first_hour+(t_first_minute/60);
UPDATE temp_labor_encs t SET second_stage_start = obs_value_datetime_from_temp(encounter_id, 'PIH','20113');
UPDATE temp_labor_encs t SET t_second_hour = obs_value_numeric_from_temp(encounter_id, 'PIH','20116');
UPDATE temp_labor_encs t SET t_second_minute = obs_value_numeric_from_temp(encounter_id, 'PIH','20117');
UPDATE temp_labor_encs t SET duration_second_stage = t_second_hour+(t_second_minute/60);
UPDATE temp_labor_encs t SET multiple_birth = answerEverExists_from_temp(patient_id, 'PIH','3064','PIH','7225',null);
UPDATE temp_labor_encs t SET amtsl = obs_value_coded_as_boolean_from_temp(encounter_id, 'PIH','13533');
UPDATE temp_labor_encs t SET visual_inspection_placenta_completeness = obs_value_coded_list_from_temp(encounter_id, 'PIH','13537','en');
UPDATE temp_labor_encs t SET birth_attendant = obs_value_coded_list_from_temp(encounter_id, 'PIH','20118','en');
UPDATE temp_labor_encs t SET perineal_tear = obs_value_coded_list_from_temp(encounter_id, 'PIH','12369','en');
UPDATE temp_labor_encs t SET perineal_tear_procedure = obs_value_coded_list_from_temp(encounter_id, 'PIH','10484','en');
UPDATE temp_labor_encs t SET t_third_hour = obs_value_numeric_from_temp(encounter_id, 'PIH','20124');
UPDATE temp_labor_encs t SET t_third_minute = obs_value_numeric_from_temp(encounter_id, 'PIH','20125');
UPDATE temp_labor_encs t SET duration_third_stage = t_third_hour+(t_third_minute/60);
UPDATE temp_labor_encs t SET total_duration_labor = obs_value_numeric_from_temp(encounter_id, 'CIEL','159616');
UPDATE temp_labor_encs t SET partogram_uploaded = (select count(o.obs_id) > 0 from temp_obs o where o.encounter_id = t.encounter_id and o.concept_id = concept_from_mapping('PIH', '13756'));

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
    labor_start,
    induced_labor,
    induction_time,
    method_of_induction,
    duration_first_stage,
    second_stage_start,
    duration_second_stage,
    case when multiple_birth is null then false else multiple_birth end as multiple_birth,
    amtsl,
    visual_inspection_placenta_completeness,
    birth_attendant,
    perineal_tear,
    perineal_tear_procedure,
    duration_third_stage,
    total_duration_labor,
    partogram_uploaded,
    index_asc,
    index_desc
FROM temp_labor_encs;
