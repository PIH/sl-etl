-- ---- MCOE High-Risk Form Changes (Sierra Leone) (SL-1521)
-- Every change made to high-risk MCOE forms after they were first saved:
--   which question, old answer, new answer, who changed it and when.
-- Forms included (inclusion_reason, first match wins):
--   1. delivery form                      Labour & Delivery Summary, MCH Delivery, Maternity Delivery Register
--   2. NICU form                          any form at the NICU location, plus the newborn / SCBU encounter types
--   3. patient died (disposition)         MCOE form with disposition Death -> all MCOE forms in that visit
--   4. patient died (admitted + dead)     MCOE admission + person.dead, death_date from admission to
--                                         visit end + @death_cutoff_days -> all MCOE forms in that visit
-- Change rules are the same as encounter_change_summary (UHM-9669). Keep the two in sync.
-- Grain: one row per changed answer, plus one row per form deletion / form-details change.
-- Contains patient identifiers (emr_id) and staff names. site and partition_num are added by PETL.

set @partition     = '${partitionNum}';
set @grace_minutes = 60;  -- changes within N minutes of first save = part of the original entry
                          -- (does not apply to form deletions, which are always included)
set @pair_seconds  = 5;   -- fallback pairing window (old obs voided / new obs created)
set @death_cutoff_days = 7;  -- (b): death_date allowed up to N days after the visit ended

set @primary_identifier = metadata_uuid('org.openmrs.module.emrapi', 'emr.primaryIdentifierType');
set @disposition_concept_id = concept_from_mapping('PIH', '8620');

select location_id into @nicu_location from location where uuid = '0ce2f6fb-6850-11ee-ab8d-0242ac120002';

-- MCOE locations (same list as all_encounters.sql / encounter_change_summary.sql)
drop temporary table if exists temp_hrc_mcoe_locations;
create temporary table temp_hrc_mcoe_locations (location_id int primary key);
insert into temp_hrc_mcoe_locations
select location_id from location where uuid in (
 '11f5c9f9-40b8-46ad-9e7e-59473ce43246','11377a5b-6850-11ee-ab8d-0242ac120002','0ce2f6fb-6850-11ee-ab8d-0242ac120002',
 '17596678-6850-11ee-ab8d-0242ac120002','ff0d5e73-3fe0-437f-90ba-7d605ac03dc0','28660b7f-3450-4b86-b840-9670ec68235f',
 '4d7e927d-6850-11ee-ab8d-0242ac120002','a39ec469-d1f9-11f0-9d46-169316be6a48','142de844-6850-11ee-ab8d-0242ac120002',
 '5981f962-6eec-453d-89ce-2f9ac48d096f','550e8400-e29b-41d4-a716-446655440000','07aa9943-d1fa-11f0-9d46-169316be6a48',
 'f85feffc-fe54-4648-aa14-01ed6d30b943','989a9b23-d1f9-11f0-9d46-169316be6a48','adde966c-d1f9-11f0-9d46-169316be6a48',
 '81080213-d1f9-11f0-9d46-169316be6a48');

-- System / admin accounts whose changes are excluded. Extend here (and in encounter_change_summary).
drop temporary table if exists temp_hrc_excluded_users;
create temporary table temp_hrc_excluded_users (user_id int primary key);
insert into temp_hrc_excluded_users
select user_id from users
where user_id = 1
   or username  in ('admin', 'daemon')
   or system_id in ('admin', 'daemon');

-- Encounter types
drop temporary table if exists temp_hrc_delivery_types;
create temporary table temp_hrc_delivery_types (encounter_type_id int primary key);
insert into temp_hrc_delivery_types
select encounter_type_id from encounter_type where uuid in (
 'fec2cc56-e35f-42e1-8ae3-017142c1ca59',   -- Labour & Delivery Summary
 '00e5ebb2-90ec-11e8-9eb6-529269fb1459',   -- MCH Delivery
 '9cc89b83-e32f-410a-947d-aeb3bda37571');  -- Maternity Delivery Register

drop temporary table if exists temp_hrc_newborn_types;
create temporary table temp_hrc_newborn_types (encounter_type_id int primary key);
insert into temp_hrc_newborn_types
select encounter_type_id from encounter_type where uuid in (
 '093b6ffc-e55a-461a-85cc-c6acf7714a23',   -- Newborn Admission
 '6444b8d4-407d-444d-aa15-d6dff204ed83',   -- Newborn Assessment
 '7e42e652-89e7-4559-80fd-41f42826c98c',   -- Newborn Progress
 '153d3182-c76f-4047-b7f2-d83cf967b206',   -- Newborn Discharge
 '3790ecc6-bc63-48f8-9104-f81dc90ee21c');  -- SCBU Register

select encounter_type_id into @adt_admission_type
from encounter_type where uuid = '260566e1-c909-4d61-a96f-c1019291a09d';

-- ---------------------------------------------------------------------
-- scope: which encounters (forms) are included, and why
-- ---------------------------------------------------------------------
drop temporary table if exists temp_hrc_scope;
create temporary table temp_hrc_scope (
 encounter_id     int primary key,
 inclusion_reason varchar(50)
);

-- 1. delivery forms (voided encounters included, so form deletions are listed)
insert ignore into temp_hrc_scope (encounter_id, inclusion_reason)
select e.encounter_id, 'delivery form'
from encounter e
inner join temp_hrc_delivery_types t   on t.encounter_type_id = e.encounter_type
inner join temp_hrc_mcoe_locations l   on l.location_id = e.location_id;

-- 2. NICU forms: anything at the NICU location, or a newborn / SCBU encounter type
insert ignore into temp_hrc_scope (encounter_id, inclusion_reason)
select e.encounter_id, 'NICU form'
from encounter e
inner join temp_hrc_mcoe_locations l   on l.location_id = e.location_id
where e.location_id = @nicu_location
   or e.encounter_type in (select encounter_type_id from temp_hrc_newborn_types);

-- 3. patients who died: visits to include (first reason per visit wins)
drop temporary table if exists temp_hrc_death_visits;
create temporary table temp_hrc_death_visits (
 visit_id         int primary key,
 inclusion_reason varchar(50)
);

-- (a) an MCOE form with disposition = Death
insert ignore into temp_hrc_death_visits (visit_id, inclusion_reason)
select distinct e.visit_id, 'patient died (disposition)'
from obs o
inner join encounter e                 on e.encounter_id = o.encounter_id and e.voided = 0
inner join temp_hrc_mcoe_locations l   on l.location_id = e.location_id
where o.concept_id = @disposition_concept_id
  and o.voided = 0
  and e.visit_id is not null
  and concept_name(o.value_coded, 'en') = 'Death';

-- (b) admitted at MCOE, patient marked dead, death_date from admission to visit end + cut-off.
--     death_date is often stored without a time, so compare dates.
--     Dead patients with no death_date are not included.
insert ignore into temp_hrc_death_visits (visit_id, inclusion_reason)
select distinct a.visit_id, 'patient died (admitted + dead)'
from encounter a
inner join temp_hrc_mcoe_locations l   on l.location_id = a.location_id
inner join person p                    on p.person_id = a.patient_id and p.dead = 1 and p.death_date is not null
inner join visit v                     on v.visit_id = a.visit_id
where a.voided = 0
  and a.encounter_type = @adt_admission_type
  and a.visit_id is not null
  and date(p.death_date) >= date(a.encounter_datetime)
  and date(p.death_date) <= date(coalesce(v.date_stopped, now())) + interval @death_cutoff_days day;

-- all MCOE forms in those visits (draft: MCOE locations only, not other KGH forms)
insert ignore into temp_hrc_scope (encounter_id, inclusion_reason)
select e.encounter_id, d.inclusion_reason
from temp_hrc_death_visits d
inner join encounter e                 on e.visit_id = d.visit_id
inner join temp_hrc_mcoe_locations l   on l.location_id = e.location_id;

-- in-scope encounters, including deleted ones
drop temporary table if exists temp_hrc_enc;
create temporary table temp_hrc_enc (
 encounter_id       int primary key,
 patient_id         int,
 visit_id           int,
 encounter_type     int,
 location_id        int,
 encounter_datetime datetime,
 creator            int,
 date_created       datetime,
 voided             tinyint,
 voided_by          int,
 date_voided        datetime,
 void_reason        varchar(255),
 changed_by         int,
 date_changed       datetime,
 inclusion_reason   varchar(50)
);
insert into temp_hrc_enc
select e.encounter_id, e.patient_id, e.visit_id, e.encounter_type, e.location_id, e.encounter_datetime,
       e.creator, e.date_created, e.voided, e.voided_by, e.date_voided, e.void_reason,
       e.changed_by, e.date_changed, s.inclusion_reason
from encounter e
inner join temp_hrc_scope s on s.encounter_id = e.encounter_id;

-- ---------------------------------------------------------------------
-- change events: one row per change (same rules as encounter_change_summary)
-- ---------------------------------------------------------------------
drop temporary table if exists temp_hrc_events;
create temporary table temp_hrc_events (
 event_id        int auto_increment primary key,
 encounter_id    int,
 change_type     varchar(30),
 user_id         int,
 change_datetime datetime,
 old_obs_id      int,
 new_obs_id      int,
 void_reason     varchar(255),
 index thrc_events_enc (encounter_id)
);

-- 1. form deleted (no grace period: deleting a form is always included)
insert into temp_hrc_events (encounter_id, change_type, user_id, change_datetime, void_reason)
select e.encounter_id, 'form deleted', e.voided_by, e.date_voided, e.void_reason
from temp_hrc_enc e
where e.voided = 1
  and not exists (select 1 from temp_hrc_excluded_users x where x.user_id = e.voided_by)
  and (e.void_reason is null
       or (e.void_reason not like '%merg%' and e.void_reason not regexp 'SL-[0-9]+'));

-- 2. answers voided after the original entry (forms not deleted)
drop temporary table if exists temp_hrc_voided_obs;
create temporary table temp_hrc_voided_obs (
 obs_id           int primary key,
 encounter_id     int,
 concept_id       int,
 voided_by        int,
 date_voided      datetime,
 void_reason      varchar(255),
 successor_obs_id int,
 index thrc_vo_enc_concept (encounter_id, concept_id)
);
insert into temp_hrc_voided_obs (obs_id, encounter_id, concept_id, voided_by, date_voided, void_reason)
select o.obs_id, o.encounter_id, o.concept_id, o.voided_by, o.date_voided, o.void_reason
from obs o
inner join temp_hrc_enc e on e.encounter_id = o.encounter_id
where o.voided = 1
  and e.voided = 0
  and o.date_voided > e.date_created + interval @grace_minutes minute
  and not exists (select 1 from temp_hrc_excluded_users x where x.user_id = o.voided_by)
  and (o.void_reason is null
       or (o.void_reason not regexp 'SL-[0-9]+'
           and o.void_reason <> 'dangling diagnosis obs'
           and o.void_reason not like '%merg%'))
  and not exists (select 1 from obs c where c.obs_group_id = o.obs_id);   -- skip obs-group headers

-- 2a. replacement via previous_version
update temp_hrc_voided_obs v
inner join obs n on n.previous_version = v.obs_id
set v.successor_obs_id = n.obs_id;

-- 3. answers created after the original entry that are not linked replacements
drop temporary table if exists temp_hrc_late_obs;
create temporary table temp_hrc_late_obs (
 obs_id       int primary key,
 encounter_id int,
 concept_id   int,
 creator      int,
 date_created datetime,
 matched      tinyint default 0,
 index thrc_lo_enc_concept (encounter_id, concept_id)
);
insert into temp_hrc_late_obs (obs_id, encounter_id, concept_id, creator, date_created)
select o.obs_id, o.encounter_id, o.concept_id, o.creator, o.date_created
from obs o
inner join temp_hrc_enc e on e.encounter_id = o.encounter_id
where o.previous_version is null
  and e.voided = 0
  and o.date_created > e.date_created + interval @grace_minutes minute
  and not exists (select 1 from temp_hrc_excluded_users x where x.user_id = o.creator)
  and not exists (select 1 from obs c where c.obs_group_id = o.obs_id);   -- skip obs-group headers

-- 2b. fallback pairing for voided answers with no previous_version link:
--     same encounter + same question, new obs created within @pair_seconds.
--     Only one-to-one matches are paired; ambiguous ones (multi-select questions)
--     stay as "answer removed" + "answer added later".
drop temporary table if exists temp_hrc_fb;
create temporary table temp_hrc_fb (old_obs_id int, new_obs_id int, index (old_obs_id), index (new_obs_id));
insert into temp_hrc_fb
select v.obs_id, n.obs_id
from temp_hrc_voided_obs v
inner join temp_hrc_late_obs n
        on n.encounter_id = v.encounter_id
       and n.concept_id   = v.concept_id
       and abs(timestampdiff(second, v.date_voided, n.date_created)) <= @pair_seconds
where v.successor_obs_id is null;

drop temporary table if exists temp_hrc_fb_old;
create temporary table temp_hrc_fb_old (obs_id int primary key, n int);
insert into temp_hrc_fb_old select old_obs_id, count(*) from temp_hrc_fb group by old_obs_id;

drop temporary table if exists temp_hrc_fb_new;
create temporary table temp_hrc_fb_new (obs_id int primary key, n int);
insert into temp_hrc_fb_new select new_obs_id, count(*) from temp_hrc_fb group by new_obs_id;

update temp_hrc_voided_obs v
inner join temp_hrc_fb f      on f.old_obs_id = v.obs_id
inner join temp_hrc_fb_old fo on fo.obs_id = f.old_obs_id and fo.n = 1
inner join temp_hrc_fb_new fn on fn.obs_id = f.new_obs_id and fn.n = 1
set v.successor_obs_id = f.new_obs_id;

-- new obs that are fallback replacements are not "added later"
update temp_hrc_late_obs n
inner join temp_hrc_voided_obs v on v.successor_obs_id = n.obs_id
set n.matched = 1;

-- drop "changes" where the value did not actually change (obs groups being re-created)
delete v
from temp_hrc_voided_obs v
inner join obs o on o.obs_id = v.obs_id
inner join obs n on n.obs_id = v.successor_obs_id
where o.value_coded    <=> n.value_coded
  and o.value_drug     <=> n.value_drug
  and o.value_numeric  <=> n.value_numeric
  and o.value_datetime <=> n.value_datetime
  and o.value_text     <=> n.value_text;

insert into temp_hrc_events (encounter_id, change_type, user_id, change_datetime, old_obs_id, new_obs_id, void_reason)
select encounter_id,
       case when void_reason like 'DiagnosisMetadata%' then 'diagnosis changed'
            when successor_obs_id is not null           then 'answer changed'
            else 'answer removed' end,
       voided_by, date_voided, obs_id, successor_obs_id, void_reason
from temp_hrc_voided_obs;

insert into temp_hrc_events (encounter_id, change_type, user_id, change_datetime, new_obs_id)
select encounter_id, 'answer added later', creator, date_created, obs_id
from temp_hrc_late_obs
where matched = 0;

-- 4. form details changed (date / location / provider).
--    Saving an edited form also updates encounter.date_changed, so only include it
--    when there is no other change in the same encounter within 2 minutes.
--    OpenMRS only keeps the LATEST date_changed, so at most 1 per form.
drop temporary table if exists temp_hrc_details;
create temporary table temp_hrc_details (encounter_id int primary key, changed_by int, date_changed datetime);
insert into temp_hrc_details
select e.encounter_id, e.changed_by, e.date_changed
from temp_hrc_enc e
where e.voided = 0
  and e.changed_by is not null
  and e.date_changed > e.date_created + interval @grace_minutes minute
  and not exists (select 1 from temp_hrc_excluded_users x where x.user_id = e.changed_by);

delete d
from temp_hrc_details d
inner join temp_hrc_events c
        on c.encounter_id = d.encounter_id
       and abs(timestampdiff(second, c.change_datetime, d.date_changed)) <= 120;

insert into temp_hrc_events (encounter_id, change_type, user_id, change_datetime)
select encounter_id, 'form details changed', changed_by, date_changed
from temp_hrc_details;

-- lag in seconds from first save, so the 60-minute boundary matches the grace period exactly
alter table temp_hrc_events add column lag_seconds bigint;
update temp_hrc_events c
inner join temp_hrc_enc e on e.encounter_id = c.encounter_id
set c.lag_seconds = timestampdiff(second, e.date_created, c.change_datetime);

-- ---------------------------------------------------------------------
-- lookups
-- ---------------------------------------------------------------------
drop temporary table if exists temp_hrc_user;
create temporary table temp_hrc_user (user_id int primary key, user_name varchar(255), provider_type varchar(255));
insert into temp_hrc_user
select u.user_id,
       coalesce(nullif(trim(min(concat_ws(' ', pn.given_name, pn.family_name))), ''), min(u.username)),
       coalesce(min(provider_role_name(p.provider_role_id)), 'No provider role')
from users u
left join person_name pn on pn.person_id = u.person_id and pn.voided = 0
left join provider p     on p.person_id = u.person_id and p.retired = 0
group by u.user_id;

-- ---------------------------------------------------------------------
-- output: one row per change
-- ---------------------------------------------------------------------
select
    concat(@partition, '-', e.patient_id)                        as patient_id,
    patient_identifier(e.patient_id, @primary_identifier)        as emr_id,
    concat(@partition, '-', e.encounter_id)                      as encounter_id,
    concat(@partition, '-', e.visit_id)                          as visit_id,
    e.inclusion_reason,
    et.name                                                      as encounter_type,
    location_name(e.location_id)                                 as encounter_location,
    e.encounter_datetime,
    e.date_created                                               as datetime_entered,
    cu.user_name                                                 as user_entered,
    c.change_type,
    concept_name(coalesce(o.concept_id, n.concept_id), 'en')     as question,
    concept_name(g.concept_id, 'en')                             as question_group,
    case when o.obs_id is null then null
         else coalesce(concept_name(o.value_coded, 'en'),
                       (select d.name from drug d where d.drug_id = o.value_drug),
                       cast(o.value_numeric as char),
                       o.value_text,
                       if(time(o.value_datetime) = '00:00:00',
                          date_format(o.value_datetime, '%Y-%m-%d'),
                          date_format(o.value_datetime, '%Y-%m-%d %H:%i'))) end   as old_value,
    case when n.obs_id is null then null
         else coalesce(concept_name(n.value_coded, 'en'),
                       (select d.name from drug d where d.drug_id = n.value_drug),
                       cast(n.value_numeric as char),
                       n.value_text,
                       if(time(n.value_datetime) = '00:00:00',
                          date_format(n.value_datetime, '%Y-%m-%d'),
                          date_format(n.value_datetime, '%Y-%m-%d %H:%i'))) end   as new_value,
    xu.user_name                                                 as changed_by_user,
    xu.provider_type                                             as changed_by_role,
    if(c.user_id = e.creator, 1, 0)                              as editor_is_creator,
    c.change_datetime                                            as changed_datetime,
    round(c.lag_seconds / 3600, 1)                               as hours_after_entry,
    -- lag groups use elapsed time (not calendar days); "within 1 hour" only holds form deletions
    case when c.lag_seconds <= 3600          then 'within 1 hour'
         when c.lag_seconds <= 4 * 3600      then '1-4 hours'
         when c.lag_seconds <= 24 * 3600     then '4-24 hours'
         when c.lag_seconds <= 7 * 86400     then '1-7 days'
         when c.lag_seconds <= 30 * 86400    then '8-30 days'
         else 'more than 30 days' end                            as change_lag_group,
    -- sort order for the lag group in Power BI
    case when c.lag_seconds <= 3600          then 1
         when c.lag_seconds <= 4 * 3600      then 2
         when c.lag_seconds <= 24 * 3600     then 3
         when c.lag_seconds <= 7 * 86400     then 4
         when c.lag_seconds <= 30 * 86400    then 5
         else 6 end                                              as change_lag_group_order,
    if(p.dead = 1, p.death_date, null)                           as death_date,
    -- death_date is often stored without a time: then only a later calendar day counts as after death
    case when p.dead <> 1 or p.death_date is null                then 0
         when time(p.death_date) = '00:00:00'
              then if(date(c.change_datetime) > date(p.death_date), 1, 0)
         else if(c.change_datetime > p.death_date, 1, 0) end     as changed_after_death,
    c.void_reason
from temp_hrc_events c
inner join temp_hrc_enc e          on e.encounter_id = c.encounter_id
inner join encounter_type et       on et.encounter_type_id = e.encounter_type
left join  obs o                   on o.obs_id = c.old_obs_id
left join  obs n                   on n.obs_id = c.new_obs_id
left join  obs g                   on g.obs_id = coalesce(o.obs_group_id, n.obs_group_id)
left join  person p                on p.person_id = e.patient_id
left join  temp_hrc_user cu        on cu.user_id = e.creator
left join  temp_hrc_user xu        on xu.user_id = c.user_id;
