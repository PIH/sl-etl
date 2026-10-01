set @partition = '${partitionNum}';

SELECT encounter_type_id INTO @labor_enc FROM encounter_type et WHERE uuid='fec2cc56-e35f-42e1-8ae3-017142c1ca59';
set @pregnancyProgramId = program('Pregnancy');

set @true  = concept_from_mapping('CIEL','1065');
set @false = concept_from_mapping('CIEL','1066');

-- ---------------------------------------------------------------
-- 0. Resolve every concept ONCE up front
--    (each obs_from_group_id_*_from_temp function called concept_from_mapping()
--     and filtered temp_obs on obs_group_id alone, which no index covered --
--     so every call was a full scan of temp_obs, ~14 times per baby)
-- ---------------------------------------------------------------
set @c_baby_construct    = concept_from_mapping('PIH','13555');
set @c_birthdate         = concept_from_mapping('PIH','5599');
set @c_outcome           = concept_from_mapping('PIH','13561');
set @c_pre_delivery_fhr  = concept_from_mapping('CIEL','165377');
set @c_sex               = concept_from_mapping('PIH','13055');
set @c_birth_weight      = concept_from_mapping('PIH','11067');
set @c_birth_length      = concept_from_mapping('PIH','6886');
set @c_head_circ         = concept_from_mapping('PIH','10896');
set @c_apgar_1           = concept_from_mapping('PIH','14419');
set @c_apgar_5           = concept_from_mapping('PIH','14417');
set @c_apgar_10          = concept_from_mapping('PIH','14785');
set @c_fetal_presentation= concept_from_mapping('PIH','13047');
set @c_delivery_method   = concept_from_mapping('PIH','11663');
set @c_baby_uuid         = concept_from_mapping('PIH','20150');
set @primary_emr_uuid    = metadata_uuid('org.openmrs.module.emrapi', 'emr.primaryIdentifierType');

-- ---------------------------------------------------------------
-- 1. Delivery encounters (same rows as before), with encounter-level
--    values computed once per encounter
-- ---------------------------------------------------------------
DROP TEMPORARY TABLE IF EXISTS temp_encs;
CREATE TEMPORARY TABLE temp_encs
(
    patient_id               int,
    obs_group_id             int,
    encounter_id             int,
    visit_id                 int,
    encounter_datetime       datetime,
    encounter_location       varchar(255),
    datetime_entered         datetime,
    user_entered             varchar(255),
    provider                 varchar(255),
    pregnancy_program_id     int(11),
    creator                  int(11),
    mother_age_at_encounter  double
);

insert into temp_encs (patient_id, encounter_id, visit_id, encounter_datetime, datetime_entered, creator)
select      patient_id, encounter_id, visit_id, encounter_datetime, date_created, creator
from        encounter e
where       e.voided = 0
AND         encounter_type IN (@labor_enc)
ORDER BY    encounter_datetime desc;

create index temp_labor_encs_ei on temp_encs(encounter_id);

-- user names, once per user
drop temporary table if exists temp_dl_users;
create temporary table temp_dl_users
(user_id int primary key, user_name text);
insert into temp_dl_users
select user_id, person_name_of_user(user_id) from users;

-- one pass: program, provider, location (encounter_location_name() inlined),
-- user name, mother's age (AGE_AT_ENC() inlined)
update temp_encs t
left join encounter e       on e.encounter_id  = t.encounter_id
left join location l        on l.location_id   = e.location_id
left join temp_dl_users u   on u.user_id       = t.creator
left join person p          on p.person_id     = t.patient_id
set t.pregnancy_program_id    = patient_program_id_from_encounter(t.patient_id, @pregnancyProgramId, t.encounter_id),
    t.provider                = provider(t.encounter_id),
    t.encounter_location      = l.name,
    t.user_entered            = u.user_name,
    t.mother_age_at_encounter = TIMESTAMPDIFF(YEAR, p.birthdate, e.encounter_datetime);

-- ---------------------------------------------------------------
-- 2. Obs of these encounters: only the baby constructs and their members
-- ---------------------------------------------------------------
DROP TEMPORARY TABLE IF EXISTS temp_obs;
create temporary table temp_obs
select o.obs_id, o.obs_group_id, o.encounter_id, o.person_id, o.concept_id, o.value_coded,
       o.value_numeric, o.value_datetime, o.comments
from obs o
inner join temp_encs t on t.encounter_id = o.encounter_id
where o.voided = 0
  and o.concept_id in (@c_baby_construct, @c_birthdate, @c_outcome, @c_pre_delivery_fhr, @c_sex,
                       @c_birth_weight, @c_birth_length, @c_head_circ, @c_apgar_1, @c_apgar_5,
                       @c_apgar_10, @c_fetal_presentation, @c_delivery_method, @c_baby_uuid);

create index temp_obs_encs_ei on temp_obs(encounter_id);
create index temp_obs_grp on temp_obs(obs_group_id, concept_id);

-- ---------------------------------------------------------------
-- 3. One row per baby obs group, all members pivoted in ONE grouped pass.
--    Single-value fields use max(): the original functions did a plain
--    SELECT ... INTO, which only works when there is one such obs per group.
--    Coded lists use GROUP_CONCAT(DISTINCT ...), as obs_from_group_id_value_coded_list_from_temp.
-- ---------------------------------------------------------------
DROP TEMPORARY TABLE IF EXISTS temp_baby;
CREATE TEMPORARY TABLE temp_baby
(obs_group_id             int primary key,
 birthdate                datetime,
 outcome                  text,
 pre_delivery_fhr_id      int,
 sex                      text,
 birth_weight             double,
 birth_length             double,
 birth_head_circumference double,
 apgar_1_min              double,
 apgar_5_min              double,
 apgar_10_min             double,
 fetal_presentation       text,
 delivery_method          text,
 baby_uuid                text,
 baby_patient_id          int);
INSERT INTO temp_baby
(obs_group_id, birthdate, outcome, pre_delivery_fhr_id, sex, birth_weight, birth_length,
 birth_head_circumference, apgar_1_min, apgar_5_min, apgar_10_min, fetal_presentation,
 delivery_method, baby_uuid)
select o.obs_group_id,
       max(case when o.concept_id = @c_birthdate        then o.value_datetime end),
       group_concat(distinct case when o.concept_id = @c_outcome then concept_name(o.value_coded,'en') end separator ' | '),
       max(case when o.concept_id = @c_pre_delivery_fhr then o.value_coded end),
       group_concat(distinct case when o.concept_id = @c_sex then concept_name(o.value_coded,'en') end separator ' | '),
       max(case when o.concept_id = @c_birth_weight     then o.value_numeric end),
       max(case when o.concept_id = @c_birth_length     then o.value_numeric end),
       max(case when o.concept_id = @c_head_circ        then o.value_numeric end),
       max(case when o.concept_id = @c_apgar_1          then o.value_numeric end),
       max(case when o.concept_id = @c_apgar_5          then o.value_numeric end),
       max(case when o.concept_id = @c_apgar_10         then o.value_numeric end),
       group_concat(distinct case when o.concept_id = @c_fetal_presentation then concept_name(o.value_coded,'en') end separator ' | '),
       group_concat(distinct case when o.concept_id = @c_delivery_method    then concept_name(o.value_coded,'en') end separator ' | '),
       max(case when o.concept_id = @c_baby_uuid        then o.comments end)
from temp_obs o
where o.obs_group_id is not null
  and o.concept_id <> @c_baby_construct
group by o.obs_group_id;

-- baby's person record from the uuid stored in the comments
update temp_baby b
inner join person p on p.uuid = b.baby_uuid
set b.baby_patient_id = p.person_id;

-- ---------------------------------------------------------------
-- 4. EMR ids (patient_identifier() inlined): mother and baby
-- ---------------------------------------------------------------
drop temporary table if exists temp_dl_mother_emr;
create temporary table temp_dl_mother_emr
(patient_id int primary key, emr_id varchar(50));
insert into temp_dl_mother_emr
select p.patient_id,
       (select i.identifier from patient_identifier i
         inner join patient_identifier_type it on it.patient_identifier_type_id = i.identifier_type
         where (it.name = 'c09a1d24-7162-11eb-8aa6-0242ac110002' or it.uuid = 'c09a1d24-7162-11eb-8aa6-0242ac110002')
           and i.voided = 0 and i.patient_id = p.patient_id
         order by i.preferred desc, i.date_created desc limit 1)
from (select distinct patient_id from temp_encs) p;

drop temporary table if exists temp_dl_baby_emr;
create temporary table temp_dl_baby_emr
(patient_id int primary key, emr_id varchar(50));
insert into temp_dl_baby_emr
select p.baby_patient_id,
       (select i.identifier from patient_identifier i
         inner join patient_identifier_type it on it.patient_identifier_type_id = i.identifier_type
         where (it.name = @primary_emr_uuid or it.uuid = @primary_emr_uuid)
           and i.voided = 0 and i.patient_id = p.baby_patient_id
         order by i.preferred desc, i.date_created desc limit 1)
from (select distinct baby_patient_id from temp_baby where baby_patient_id is not null) p;

-- ---------------------------------------------------------------
-- 5. Main table (same column types), one row per baby construct, ONE insert
--    (replaces ~20 UPDATEs)
-- ---------------------------------------------------------------
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
    mother_age_at_encounter  int,
    birthdate                datetime,
    outcome                  varchar(255),
    pre_delivery_fhr_id      int,
    pre_delivery_fhr         boolean,
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

insert into temp_labor_encs
(patient_id, encounter_id, visit_id, encounter_datetime, datetime_entered, user_entered,
 obs_group_id, pregnancy_program_id, provider, emr_id_mother, encounter_location,
 birthdate, outcome, pre_delivery_fhr_id, pre_delivery_fhr, sex, birth_weight, birth_length,
 birth_head_circumference, apgar_1_min, apgar_5_min, apgar_10_min, fetal_presentation,
 delivery_method, baby_uuid, baby_patient_id, baby_emr_id, mother_age_at_encounter)
SELECT e.patient_id, e.encounter_id, e.visit_id, e.encounter_datetime, e.datetime_entered, e.user_entered,
       o.obs_id, e.pregnancy_program_id, e.provider, me.emr_id, e.encounter_location,
       b.birthdate,
       b.outcome,
       b.pre_delivery_fhr_id,
       if(b.pre_delivery_fhr_id = @true, 1, if(b.pre_delivery_fhr_id = @false, 0, null)),
       b.sex,
       b.birth_weight,
       b.birth_length,
       b.birth_head_circumference,
       b.apgar_1_min,
       b.apgar_5_min,
       b.apgar_10_min,
       b.fetal_presentation,
       b.delivery_method,
       b.baby_uuid,
       b.baby_patient_id,
       be.emr_id,
       e.mother_age_at_encounter
FROM temp_encs e
INNER JOIN temp_obs o              ON e.encounter_id = o.encounter_id
                                  AND o.concept_id = @c_baby_construct
LEFT JOIN temp_baby b              ON b.obs_group_id = o.obs_id
LEFT JOIN temp_dl_mother_emr me    ON me.patient_id  = e.patient_id
LEFT JOIN temp_dl_baby_emr be      ON be.patient_id  = b.baby_patient_id;

-- ---------------------------------------------------------------
-- 6. Final output (unchanged)
-- ---------------------------------------------------------------
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
mother_age_at_encounter,
concat(@partition,"-",pregnancy_program_id) as pregnancy_program_id,
birthdate,
outcome,
pre_delivery_fhr,
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
