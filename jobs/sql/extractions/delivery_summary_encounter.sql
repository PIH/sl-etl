set @partition = '${partitionNum}';

SELECT encounter_type_id INTO @labor_enc FROM encounter_type et WHERE uuid='fec2cc56-e35f-42e1-8ae3-017142c1ca59';
set @pregnancyProgramId = program('Pregnancy');

drop temporary table if exists temp_labor_encs;
create temporary table temp_labor_encs
(
    patient_id               int(11),
    baby_patient_id          int(11),
    obs_group_id             int(11),
    baby_uuid                varchar(38),
    emr_id_mother            varchar(255),
    baby_emr_id              varchar(255),
    encounter_id             int,
    visit_id                 int,
    encounter_datetime       datetime,
    encounter_location       varchar(255),
    datetime_entered         datetime,
    user_entered             varchar(255),
    pregnancy_program_id     int(11),
    provider                 varchar(255),
    birthdate                datetime,
    outcome                  varchar(255),
    sex                      varchar(10),
    birth_weight             decimal(3, 2),
    birth_length             int,
    birth_head_circumference int,
    apgar_1_min              int,
    apgar_5_min              int,
    apgar_10_min             int,
    fetal_presentation       varchar(255),
    delivery_method          varchar(255),
    index_asc                INT,
    index_desc               INT
);

DROP TABLE IF EXISTS temp_encs;
CREATE TEMPORARY TABLE temp_encs
(
    patient_id         int,
    obs_group_id       int,
    encounter_id       int,
    visit_id           int,
    encounter_datetime datetime,
    encounter_location varchar(255),
    datetime_entered   datetime,
    user_entered       varchar(255),
    provider           varchar(255),
    pregnancy_program_id     int(11)
);

insert into temp_encs (patient_id, encounter_id, visit_id, encounter_datetime, datetime_entered, user_entered)
select      patient_id, encounter_id, visit_id, encounter_datetime, date_created, creator
from        encounter e
where       e.voided = 0
AND         encounter_type IN (@labor_enc)
ORDER BY    encounter_datetime desc;

create index temp_labor_encs_ei on temp_encs(encounter_id);

update temp_encs
set pregnancy_program_id = patient_program_id_from_encounter(patient_id, @pregnancyProgramId ,encounter_id);

DROP TEMPORARY TABLE IF EXISTS temp_obs;
create temporary table temp_obs
select o.obs_id, o.voided ,o.obs_group_id , o.encounter_id, o.person_id, o.concept_id, o.value_coded,
       o.value_numeric, o.value_text,o.value_datetime, o.comments, o.date_created, o.obs_datetime
from obs o
inner join temp_encs t on t.encounter_id = o.encounter_id
where o.voided = 0;

create index temp_obs_encs_ei on temp_obs(encounter_id);
create index temp_obs_encs_eobs on temp_obs(encounter_id, obs_group_id);

insert into temp_labor_encs(patient_id, encounter_id, visit_id, encounter_datetime, datetime_entered, user_entered, obs_group_id, pregnancy_program_id)
SELECT e.patient_id, e.encounter_id, e.visit_id, e.encounter_datetime, e.datetime_entered, e.user_entered, o.obs_id, e.pregnancy_program_id
FROM temp_encs e
INNER JOIN temp_obs o ON e.encounter_id=o.encounter_id
AND o.concept_id= concept_from_mapping('PIH','13555');

UPDATE temp_labor_encs
set user_entered = person_name_of_user(user_entered);

UPDATE temp_labor_encs
SET provider = provider(encounter_id);

UPDATE temp_labor_encs t
SET emr_id_mother = patient_identifier(patient_id, 'c09a1d24-7162-11eb-8aa6-0242ac110002');

UPDATE temp_labor_encs
SET encounter_location=encounter_location_name(encounter_id);

UPDATE temp_labor_encs
SET birthdate=obs_from_group_id_value_datetime_from_temp(obs_group_id, 'PIH', '5599');

UPDATE temp_labor_encs
SET outcome=obs_from_group_id_value_coded_list_from_temp(obs_group_id, 'PIH', '13561','en');

UPDATE temp_labor_encs
SET sex=obs_from_group_id_value_coded_list_from_temp(obs_group_id, 'PIH', '13055','en');

UPDATE temp_labor_encs
SET birth_weight=obs_from_group_id_value_numeric_from_temp(obs_group_id, 'PIH', '11067');

UPDATE temp_labor_encs
SET birth_length=obs_from_group_id_value_numeric_from_temp(obs_group_id, 'PIH', '6886');

UPDATE temp_labor_encs
SET birth_head_circumference=obs_from_group_id_value_numeric_from_temp(obs_group_id, 'PIH', '10896');

UPDATE temp_labor_encs
SET apgar_1_min=obs_from_group_id_value_numeric_from_temp(obs_group_id, 'PIH', '14419');

UPDATE temp_labor_encs
SET apgar_5_min=obs_from_group_id_value_numeric_from_temp(obs_group_id, 'PIH', '14417');

UPDATE temp_labor_encs
SET apgar_10_min=obs_from_group_id_value_numeric_from_temp(obs_group_id, 'PIH', '14785');

UPDATE temp_labor_encs
SET fetal_presentation=obs_from_group_id_value_coded_list_from_temp(obs_group_id, 'PIH', '13047','en');

UPDATE temp_labor_encs
SET delivery_method=obs_from_group_id_value_coded_list_from_temp(obs_group_id, 'PIH', '11663','en');

UPDATE temp_labor_encs
SET baby_uuid = obs_from_group_id_comment_from_temp(obs_group_id, 'PIH','20150');

update temp_labor_encs t 
inner join person p on p.uuid = t.baby_uuid
set baby_patient_id = p.person_id;

set @primary_emr_uuid = metadata_uuid('org.openmrs.module.emrapi', 'emr.primaryIdentifierType');
UPDATE temp_labor_encs SET baby_emr_id=patient_identifier(patient_id,@primary_emr_uuid );

SELECT
concat(@partition,"-",obs_group_id)  as baby_obs_id,
concat(@partition,"-",baby_patient_id)  as patient_id,
baby_emr_id as emr_id,
concat(@partition,"-",patient_id) as mother_patient_id,
emr_id_mother,
concat(@partition,"-",encounter_id) as encounter_id,
concat(@partition,"-",visit_id) as visit_id,
encounter_datetime,
encounter_location,
datetime_entered,
user_entered,
provider,
concat(@partition,"-",pregnancy_program_id) as pregnancy_program_id,
birthdate,
outcome,
sex,
birth_weight,
birth_length,
birth_head_circumference,
apgar_1_min,
apgar_5_min,
apgar_10_min,
fetal_presentation,
delivery_method,
index_asc,
index_desc
FROM temp_labor_encs;
