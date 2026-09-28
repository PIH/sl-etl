-- ---- All Encounters (Sierra Leone)
set @partition = '${partitionNum}';
set @locale = 'en';

-- ---------------------------------------------------------------
-- 0. Resolve every lookup ONCE up front
-- ---------------------------------------------------------------
SELECT patient_identifier_type_id INTO @identifier_type     FROM patient_identifier_type pit WHERE uuid = '1a2acce0-7426-11e5-a837-0800200c9a66';
SELECT patient_identifier_type_id INTO @kgh_identifier_type FROM patient_identifier_type pit WHERE uuid = 'c09a1d24-7162-11eb-8aa6-0242ac110002';
set @primary_id_uuid = metadata_uuid('org.openmrs.module.emrapi', 'emr.primaryIdentifierType');

select location_id into @anc               from location where uuid = '11f5c9f9-40b8-46ad-9e7e-59473ce43246';
select location_id into @labour            from location where uuid = '11377a5b-6850-11ee-ab8d-0242ac120002';
select location_id into @nicu              from location where uuid = '0ce2f6fb-6850-11ee-ab8d-0242ac120002';
select location_id into @pacu              from location where uuid = '17596678-6850-11ee-ab8d-0242ac120002';
select location_id into @pnc               from location where uuid = 'ff0d5e73-3fe0-437f-90ba-7d605ac03dc0';
select location_id into @quiet             from location where uuid = '28660b7f-3450-4b86-b840-9670ec68235f';
select location_id into @mccu              from location where uuid = '4d7e927d-6850-11ee-ab8d-0242ac120002';
select location_id into @postop            from location where uuid = 'a39ec469-d1f9-11f0-9d46-169316be6a48';
select location_id into @preop             from location where uuid = '142de844-6850-11ee-ab8d-0242ac120002';
select location_id into @kgh_mch           from location where uuid = '5981f962-6eec-453d-89ce-2f9ac48d096f';
select location_id into @mcoe_pharmacy     from location where uuid = '550e8400-e29b-41d4-a716-446655440000';
select location_id into @mcoe_registration from location where uuid = '07aa9943-d1fa-11f0-9d46-169316be6a48';
select location_id into @mcoe_triage       from location where uuid = 'f85feffc-fe54-4648-aa14-01ed6d30b943';
select location_id into @mothers_dorm      from location where uuid = '989a9b23-d1f9-11f0-9d46-169316be6a48';
select location_id into @staff             from location where uuid = 'adde966c-d1f9-11f0-9d46-169316be6a48';
select location_id into @kangaroo          from location where uuid = '81080213-d1f9-11f0-9d46-169316be6a48';

select location_tag_id into @admission_location from location_tag where uuid = 'f5b9737b-14d5-402b-8475-dd558808e172';

set @next_appt_date_concept_id = CONCEPT_FROM_MAPPING('PIH', 5096);
set @disposition_concept_id    = concept_from_mapping('PIH','8620');

-- ---------------------------------------------------------------
-- 1. Small lookup tables, each keyed by a primary key
--    (every function runs once per user / provider / location / patient,
--     instead of once per encounter)
-- ---------------------------------------------------------------

-- usernames: username() inlined (IFNULL(username, system_id))
drop temporary table if exists temp_ae_usernames;
create temporary table temp_ae_usernames
(user_id  int(11) primary key,
 username varchar(50));
insert into temp_ae_usernames
select user_id, IFNULL(username, system_id) from users;

-- location names (same location_name() function) + flags
drop temporary table if exists temp_ae_locations;
create temporary table temp_ae_locations
(location_id        int(11) primary key,
 location_name      varchar(255),
 mcoe_location      boolean,
 inpatient_location boolean);
insert into temp_ae_locations
select l.location_id,
       location_name(l.location_id),
       case when l.location_id in (@anc, @labour, @nicu, @pacu, @pnc, @quiet, @mccu, @postop, @preop, @kgh_mch,
                                   @mcoe_pharmacy, @mcoe_registration, @mcoe_triage, @mothers_dorm, @staff, @kangaroo)
            then 1 end,
       case when exists (select 1 from location_tag_map ltm
                         where ltm.location_id = l.location_id
                           and ltm.location_tag_id = @admission_location)
            then 1 end
from location l;

-- provider role names (once per role)
drop temporary table if exists temp_ae_roles;
create temporary table temp_ae_roles
(provider_role_id int(11) primary key,
 provider_role    varchar(255));
insert into temp_ae_roles
select r.provider_role_id, provider_role_name(r.provider_role_id)
from (select distinct provider_role_id from provider where provider_role_id is not null) r;

-- providers: name + role (once per provider)
drop temporary table if exists temp_ae_providers;
create temporary table temp_ae_providers
(provider_id      int(11) primary key,
 provider         text,
 provider_role_id int(11),
 provider_role    varchar(255));
insert into temp_ae_providers
select p.provider_id, provider_name_from_provider_id(p.provider_id), p.provider_role_id, r.provider_role
from provider p
left join temp_ae_roles r on r.provider_role_id = p.provider_role_id;

-- one provider per encounter (lowest encounter_provider_id)
drop temporary table if exists temp_ae_enc_provider;
create temporary table temp_ae_enc_provider
(encounter_id int(11) primary key,
 provider_id  int(11));
insert into temp_ae_enc_provider
select ep.encounter_id, ep.provider_id
from (select encounter_id, min(encounter_provider_id) as encounter_provider_id
      from encounter_provider
      group by encounter_id) f
inner join encounter_provider ep on ep.encounter_provider_id = f.encounter_provider_id;

-- next appointment + disposition, one row per encounter
DROP TEMPORARY TABLE IF EXISTS temp_obs_collated;
CREATE TEMPORARY TABLE temp_obs_collated
(encounter_id   int(11) primary key,
 next_appt_date datetime,
 disposition    varchar(255));
insert into temp_obs_collated
select encounter_id,
       max(case when concept_id = @next_appt_date_concept_id then value_datetime end),
       max(case when concept_id = @disposition_concept_id then concept_name(value_coded, @locale) end)
from obs
where concept_id in (@next_appt_date_concept_id, @disposition_concept_id)
  and voided = 0
  and encounter_id is not null
group by encounter_id;

-- other modifiers: distinct (encounter, creator, date) first, then usernames
drop temporary table if exists temp_obs_modifiers;
create temporary table temp_obs_modifiers
(encounter_id  int(11),
 creator       int(11),
 date_modified date,
 index temp_obs_modifiers_ei (encounter_id));
insert into temp_obs_modifiers
select distinct o.encounter_id, o.creator, date(o.date_created)
from obs o
straight_join encounter e on e.encounter_id = o.encounter_id
where e.voided = 0
  and o.creator <> e.creator;

drop temporary table if exists temp_other_modifiers;
create temporary table temp_other_modifiers
(encounter_id   int(11) primary key,
 users_modified text,
 dates_modified text);
insert into temp_other_modifiers
select m.encounter_id,
       group_concat(distinct u.username order by u.username separator ', '),
       group_concat(distinct m.date_modified order by m.date_modified separator ', ')
from temp_obs_modifiers m
left join temp_ae_usernames u on u.user_id = m.creator
group by m.encounter_id;

-- ---------------------------------------------------------------
-- 2. Patient-level lookup: identifiers, birthdate, and what's needed for new_patient
-- ---------------------------------------------------------------

-- earliest encounter per (patient, visit); encounters with no visit share key -1
drop temporary table if exists temp_ae_visit_min;
create temporary table temp_ae_visit_min
(patient_id int(11),
 visit_key  int(11),
 min_dt     datetime,
 primary key (patient_id, visit_key));
insert into temp_ae_visit_min
select patient_id, ifnull(visit_id, -1), min(encounter_datetime)
from encounter
where voided = 0
group by patient_id, ifnull(visit_id, -1);

DROP TEMPORARY TABLE IF EXISTS temp_patient;
CREATE TEMPORARY TABLE temp_patient
(
patient_id      int(11) primary key,
wellbody_emr_id varchar(50),
kgh_emr_id      varchar(50),
emr_id          varchar(50),
birthdate       date,
min1            datetime,   -- earliest encounter of the patient
key1            int(11),    -- visit key that earliest encounter belongs to
min2            datetime    -- earliest encounter outside visit key1
);

-- patient_identifier() inlined (same filters and ORDER BY ... LIMIT 1)
insert into temp_patient (patient_id, wellbody_emr_id, kgh_emr_id, emr_id, birthdate, min1)
select x.patient_id,
       (select i.identifier from patient_identifier i
         where i.identifier_type = @identifier_type and i.voided = 0 and i.patient_id = x.patient_id
         order by i.preferred desc, i.date_created desc limit 1),
       (select i.identifier from patient_identifier i
         where i.identifier_type = @kgh_identifier_type and i.voided = 0 and i.patient_id = x.patient_id
         order by i.preferred desc, i.date_created desc limit 1),
       (select i.identifier from patient_identifier i
         inner join patient_identifier_type it on it.patient_identifier_type_id = i.identifier_type
         where (it.name = @primary_id_uuid or it.uuid = @primary_id_uuid)
           and i.voided = 0 and i.patient_id = x.patient_id
         order by i.preferred desc, i.date_created desc limit 1),
       p.birthdate,
       x.min1
from (select patient_id, min(min_dt) as min1 from temp_ae_visit_min group by patient_id) x
left join person p on p.person_id = x.patient_id;

update temp_patient p
inner join temp_ae_visit_min v on v.patient_id = p.patient_id and v.min_dt = p.min1
set p.key1 = v.visit_key;

update temp_patient p
set p.min2 = (select min(v.min_dt) from temp_ae_visit_min v
              where v.patient_id = p.patient_id and v.visit_key <> p.key1);

-- ---------------------------------------------------------------
-- 3. Main table (same column types as before), filled in ONE pass
-- ---------------------------------------------------------------
DROP temporary TABLE IF EXISTS temp_all_encounters;
create temporary table temp_all_encounters(
encounter_id       int primary key,
patient_id         int,
visit_id           int,
emr_id             varchar(50),
wellbody_emr_id    varchar(50),
kgh_emr_id         varchar(50),
encounter_type     varchar(50),
encounter_type_id  int,
provider_id        int(11),
provider           text,
provider_role_id   int(11),
provider_role      varchar(255),
encounter_datetime datetime,
location_id        int(11),
encounter_location varchar(255),
mcoe_location      boolean,
inpatient_location boolean,
encounter_year     int,
encounter_month    int,
birthdate          date,
datetime_entered   datetime,
age_at_encounter   int,
creator            int(11),
user_entered       varchar(50),
next_appt_date     date,
disposition        varchar(255),
retrospective      boolean,
entry_lag_hours    int,
new_patient        boolean,
users_modified     text,
dates_modified     text,
index_asc          int,
index_desc         int
);

insert into temp_all_encounters
(encounter_id, patient_id, visit_id, emr_id, wellbody_emr_id, kgh_emr_id,
 encounter_type, encounter_type_id, provider_id, provider, provider_role_id, provider_role,
 encounter_datetime, location_id, encounter_location, mcoe_location, inpatient_location,
 encounter_year, encounter_month, birthdate, datetime_entered, age_at_encounter,
 creator, user_entered, next_appt_date, disposition, retrospective, entry_lag_hours,
 new_patient, users_modified, dates_modified)
select
 e.encounter_id,
 e.patient_id,
 e.visit_id,
 p.emr_id,
 p.wellbody_emr_id,
 p.kgh_emr_id,
 et.name,
 e.encounter_type,
 ep.provider_id,
 pr.provider,
 pr.provider_role_id,
 pr.provider_role,
 e.encounter_datetime,
 e.location_id,
 l.location_name,
 l.mcoe_location,
 l.inpatient_location,
 year(e.encounter_datetime),
 month(e.encounter_datetime),
 p.birthdate,
 e.date_created,
 TIMESTAMPDIFF(YEAR, p.birthdate, e.encounter_datetime),
 e.creator,
 u.username,
 o.next_appt_date,
 o.disposition,
 -- retrospective: entered more than 30 minutes after the encounter datetime
 -- (full datetime difference, so entries on a later day are counted)
 IF(TIMESTAMPDIFF(SECOND, e.encounter_datetime, e.date_created) > 1800, 1, 0),
 case when TIMESTAMPDIFF(SECOND, e.encounter_datetime, e.date_created) > 1800
      then TIMESTAMPDIFF(HOUR, e.encounter_datetime, e.date_created) end,
 -- new_patient (same rules as the two NOT EXISTS updates):
 --   no visit:   no earlier encounter at all
 --   with visit: no earlier encounter outside this visit
 case
   when e.visit_id is null then
        case when e.encounter_datetime <= p.min1 then 1 end
   else case when (case when e.visit_id = p.key1 then p.min2 else p.min1 end) is null
               or (case when e.visit_id = p.key1 then p.min2 else p.min1 end) >= e.encounter_datetime
             then 1 end
 end,
 m.users_modified,
 m.dates_modified
from encounter e
left join encounter_type et          on et.encounter_type_id = e.encounter_type
left join temp_patient p             on p.patient_id         = e.patient_id
left join temp_ae_enc_provider ep    on ep.encounter_id      = e.encounter_id
left join temp_ae_providers pr       on pr.provider_id       = ep.provider_id
left join temp_ae_locations l        on l.location_id        = e.location_id
left join temp_ae_usernames u        on u.user_id            = e.creator
left join temp_obs_collated o        on o.encounter_id       = e.encounter_id
left join temp_other_modifiers m     on m.encounter_id       = e.encounter_id
where e.voided = 0;

-- ---------------------------------------------------------------
-- 4. Final output (unchanged)
-- ---------------------------------------------------------------
select
concat(@partition,"-",encounter_id) as encounter_id,
concat(@partition,"-",patient_id)  as patient_id,
concat(@partition,"-",visit_id)  as visit_id,
wellbody_emr_id,
kgh_emr_id,
emr_id,
encounter_type,
encounter_type_id,
encounter_location,
mcoe_location,
inpatient_location,
provider,
provider_role,
encounter_datetime,
datetime_entered,
user_entered,
users_modified,
dates_modified,
age_at_encounter,
disposition,
next_appt_date,
retrospective,
entry_lag_hours,
new_patient,
index_asc,
index_desc
from temp_all_encounters;
