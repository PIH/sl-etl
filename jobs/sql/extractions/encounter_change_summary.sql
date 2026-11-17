-- ---- Encounter Change Summary (Sierra Leone) (UHM-9669)
-- Counts of changes made to forms (encounters) after they were first saved:
-- form deleted / answer changed / answer removed / answer added later /
-- diagnosis changed / form details changed.
-- One row per change_date, form, provider type, lag group, location, MCOE and patient_died.
-- No patient or user identifiers are returned. site and partition_num are added by PETL.

set @grace_minutes = 60;  -- changes within N minutes of first save = part of the original entry
                          -- (does not apply to form deletions, which are always counted)
set @pair_seconds  = 5;   -- fallback pairing window (old obs voided / new obs created)

-- MCOE locations (same list as all_encounters.sql)
drop temporary table if exists temp_ecs_mcoe_locations;
create temporary table temp_ecs_mcoe_locations (location_id int primary key);
insert into temp_ecs_mcoe_locations
select location_id from location where uuid in (
 '11f5c9f9-40b8-46ad-9e7e-59473ce43246','11377a5b-6850-11ee-ab8d-0242ac120002','0ce2f6fb-6850-11ee-ab8d-0242ac120002',
 '17596678-6850-11ee-ab8d-0242ac120002','ff0d5e73-3fe0-437f-90ba-7d605ac03dc0','28660b7f-3450-4b86-b840-9670ec68235f',
 '4d7e927d-6850-11ee-ab8d-0242ac120002','a39ec469-d1f9-11f0-9d46-169316be6a48','142de844-6850-11ee-ab8d-0242ac120002',
 '5981f962-6eec-453d-89ce-2f9ac48d096f','550e8400-e29b-41d4-a716-446655440000','07aa9943-d1fa-11f0-9d46-169316be6a48',
 'f85feffc-fe54-4648-aa14-01ed6d30b943','989a9b23-d1f9-11f0-9d46-169316be6a48','adde966c-d1f9-11f0-9d46-169316be6a48',
 '81080213-d1f9-11f0-9d46-169316be6a48');

-- System / admin accounts whose changes are excluded. Extend here.
drop temporary table if exists temp_ecs_excluded_users;
create temporary table temp_ecs_excluded_users (user_id int primary key);
insert into temp_ecs_excluded_users
select user_id from users
where user_id = 1
   or username  in ('admin', 'daemon')
   or system_id in ('admin', 'daemon');

-- ------------------------- encounters --------------------------------
-- all encounters, including deleted ones (all_encounters excludes voided encounters)
drop temporary table if exists temp_ecs_enc;
create temporary table temp_ecs_enc (
 encounter_id       int primary key,
 patient_id         int,
 encounter_type     int,
 location_id        int,
 date_created       datetime,
 voided             tinyint,
 voided_by          int,
 date_voided        datetime,
 void_reason        varchar(255),
 changed_by         int,
 date_changed       datetime
);
insert into temp_ecs_enc
select encounter_id, patient_id, encounter_type, location_id, date_created,
       voided, voided_by, date_voided, void_reason, changed_by, date_changed
from encounter;

-- ---------------------------------------------------------------------
-- change events: one row per change
-- ---------------------------------------------------------------------
drop temporary table if exists temp_ecs_events;
create temporary table temp_ecs_events (
 event_id        int auto_increment primary key,
 encounter_id    int,
 change_type     varchar(30),
 user_id         int,
 change_datetime datetime,
 old_obs_id      int,
 new_obs_id      int,
 void_reason     varchar(255),
 index tecs_events_enc (encounter_id)
);

-- 1. form deleted (no grace period: deleting a form is always counted)
insert into temp_ecs_events (encounter_id, change_type, user_id, change_datetime, void_reason)
select e.encounter_id, 'form deleted', e.voided_by, e.date_voided, e.void_reason
from temp_ecs_enc e
where e.voided = 1
  and not exists (select 1 from temp_ecs_excluded_users x where x.user_id = e.voided_by)
  and (e.void_reason is null
       or (e.void_reason not like '%merg%' and e.void_reason not regexp 'SL-[0-9]+'));

-- 2. answers voided after the original entry (forms not deleted)
drop temporary table if exists temp_ecs_voided_obs;
create temporary table temp_ecs_voided_obs (
 obs_id           int primary key,
 encounter_id     int,
 concept_id       int,
 voided_by        int,
 date_voided      datetime,
 void_reason      varchar(255),
 successor_obs_id int,
 index tecs_vo_enc_concept (encounter_id, concept_id)
);
insert into temp_ecs_voided_obs (obs_id, encounter_id, concept_id, voided_by, date_voided, void_reason)
select o.obs_id, o.encounter_id, o.concept_id, o.voided_by, o.date_voided, o.void_reason
from obs o
inner join temp_ecs_enc e on e.encounter_id = o.encounter_id
where o.voided = 1
  and e.voided = 0
  and o.date_voided > e.date_created + interval @grace_minutes minute
  and not exists (select 1 from temp_ecs_excluded_users x where x.user_id = o.voided_by)
  and (o.void_reason is null
       or (o.void_reason not regexp 'SL-[0-9]+'
           and o.void_reason <> 'dangling diagnosis obs'
           and o.void_reason not like '%merg%'))
  and not exists (select 1 from obs c where c.obs_group_id = o.obs_id);   -- skip obs-group headers

-- 2a. replacement via previous_version
update temp_ecs_voided_obs v
inner join obs n on n.previous_version = v.obs_id
set v.successor_obs_id = n.obs_id;

-- 3. answers created after the original entry that are not linked replacements
drop temporary table if exists temp_ecs_late_obs;
create temporary table temp_ecs_late_obs (
 obs_id       int primary key,
 encounter_id int,
 concept_id   int,
 creator      int,
 date_created datetime,
 matched      tinyint default 0,
 index tecs_lo_enc_concept (encounter_id, concept_id)
);
insert into temp_ecs_late_obs (obs_id, encounter_id, concept_id, creator, date_created)
select o.obs_id, o.encounter_id, o.concept_id, o.creator, o.date_created
from obs o
inner join temp_ecs_enc e on e.encounter_id = o.encounter_id
where o.previous_version is null
  and e.voided = 0
  and o.date_created > e.date_created + interval @grace_minutes minute
  and not exists (select 1 from temp_ecs_excluded_users x where x.user_id = o.creator)
  and not exists (select 1 from obs c where c.obs_group_id = o.obs_id);   -- skip obs-group headers

-- 2b. fallback pairing for voided answers with no previous_version link:
--     same encounter + same question, new obs created within @pair_seconds.
--     Only one-to-one matches are paired; ambiguous ones (multi-select questions)
--     stay as "answer removed" + "answer added later".
drop temporary table if exists temp_ecs_fb;
create temporary table temp_ecs_fb (old_obs_id int, new_obs_id int, index (old_obs_id), index (new_obs_id));
insert into temp_ecs_fb
select v.obs_id, n.obs_id
from temp_ecs_voided_obs v
inner join temp_ecs_late_obs n
        on n.encounter_id = v.encounter_id
       and n.concept_id   = v.concept_id
       and abs(timestampdiff(second, v.date_voided, n.date_created)) <= @pair_seconds
where v.successor_obs_id is null;

drop temporary table if exists temp_ecs_fb_old;
create temporary table temp_ecs_fb_old (obs_id int primary key, n int);
insert into temp_ecs_fb_old select old_obs_id, count(*) from temp_ecs_fb group by old_obs_id;

drop temporary table if exists temp_ecs_fb_new;
create temporary table temp_ecs_fb_new (obs_id int primary key, n int);
insert into temp_ecs_fb_new select new_obs_id, count(*) from temp_ecs_fb group by new_obs_id;

update temp_ecs_voided_obs v
inner join temp_ecs_fb f      on f.old_obs_id = v.obs_id
inner join temp_ecs_fb_old fo on fo.obs_id = f.old_obs_id and fo.n = 1
inner join temp_ecs_fb_new fn on fn.obs_id = f.new_obs_id and fn.n = 1
set v.successor_obs_id = f.new_obs_id;

-- new obs that are fallback replacements are not "added later"
update temp_ecs_late_obs n
inner join temp_ecs_voided_obs v on v.successor_obs_id = n.obs_id
set n.matched = 1;

-- drop "changes" where the value did not actually change (obs groups being re-created)
delete v
from temp_ecs_voided_obs v
inner join obs o on o.obs_id = v.obs_id
inner join obs n on n.obs_id = v.successor_obs_id
where o.value_coded    <=> n.value_coded
  and o.value_drug     <=> n.value_drug
  and o.value_numeric  <=> n.value_numeric
  and o.value_datetime <=> n.value_datetime
  and o.value_text     <=> n.value_text;

insert into temp_ecs_events (encounter_id, change_type, user_id, change_datetime, old_obs_id, new_obs_id, void_reason)
select encounter_id,
       case when void_reason like 'DiagnosisMetadata%' then 'diagnosis changed'
            when successor_obs_id is not null           then 'answer changed'
            else 'answer removed' end,
       voided_by, date_voided, obs_id, successor_obs_id, void_reason
from temp_ecs_voided_obs;

insert into temp_ecs_events (encounter_id, change_type, user_id, change_datetime, new_obs_id)
select encounter_id, 'answer added later', creator, date_created, obs_id
from temp_ecs_late_obs
where matched = 0;

-- 4. form details changed (date / location / provider).
--    Saving an edited form also updates encounter.date_changed, so only count it
--    when there is no other change in the same encounter within 2 minutes.
--    OpenMRS only keeps the LATEST date_changed, so at most 1 per form.
drop temporary table if exists temp_ecs_details;
create temporary table temp_ecs_details (encounter_id int primary key, changed_by int, date_changed datetime);
insert into temp_ecs_details
select e.encounter_id, e.changed_by, e.date_changed
from temp_ecs_enc e
where e.voided = 0
  and e.changed_by is not null
  and e.date_changed > e.date_created + interval @grace_minutes minute
  and not exists (select 1 from temp_ecs_excluded_users x where x.user_id = e.changed_by);

delete d
from temp_ecs_details d
inner join temp_ecs_events c
        on c.encounter_id = d.encounter_id
       and abs(timestampdiff(second, c.change_datetime, d.date_changed)) <= 120;

insert into temp_ecs_events (encounter_id, change_type, user_id, change_datetime)
select encounter_id, 'form details changed', changed_by, date_changed
from temp_ecs_details;

-- ---------------------------------------------------------------------
-- lookups
-- ---------------------------------------------------------------------
drop temporary table if exists temp_ecs_user_role;
create temporary table temp_ecs_user_role (user_id int primary key, provider_type varchar(255));
insert into temp_ecs_user_role
select u.user_id, coalesce(min(provider_role_name(p.provider_role_id)), 'No provider role')
from users u
left join provider p on p.person_id = u.person_id and p.retired = 0
group by u.user_id;

drop temporary table if exists temp_ecs_loc;
create temporary table temp_ecs_loc (location_id int primary key, location_name varchar(255), mcoe_location tinyint);
insert into temp_ecs_loc
select l.location_id, location_name(l.location_id),
       if(exists (select 1 from temp_ecs_mcoe_locations m where m.location_id = l.location_id), 1, 0)
from location l;

-- lag in seconds from first save, so the 60-minute boundary matches the grace period exactly
-- (timestampdiff(minute) rounds down, which put changes at 60-61 minutes into "within 1 hour")
alter table temp_ecs_events add column lag_seconds bigint;
update temp_ecs_events c
inner join temp_ecs_enc e on e.encounter_id = c.encounter_id
set c.lag_seconds = timestampdiff(second, e.date_created, c.change_datetime);

-- ---------------------------------------------------------------------
-- summary
-- ---------------------------------------------------------------------
select
    date(c.change_datetime)                                   as change_date,
    et.name                                                   as encounter_type,
    coalesce(r.provider_type, 'No provider role')             as provider_type,
    -- lag groups use elapsed time (not calendar days); "within 1 hour" only holds form deletions
    case when c.lag_seconds <= 3600          then 'within 1 hour'
         when c.lag_seconds <= 4 * 3600      then '1-4 hours'
         when c.lag_seconds <= 24 * 3600     then '4-24 hours'
         when c.lag_seconds <= 7 * 86400     then '1-7 days'
         when c.lag_seconds <= 30 * 86400    then '8-30 days'
         else 'more than 30 days' end                         as change_lag_group,
    -- sort order for the lag group in Power BI
    case when c.lag_seconds <= 3600          then 1
         when c.lag_seconds <= 4 * 3600      then 2
         when c.lag_seconds <= 24 * 3600     then 3
         when c.lag_seconds <= 7 * 86400     then 4
         when c.lag_seconds <= 30 * 86400    then 5
         else 6 end                                           as change_lag_group_order,
    l.location_name                                           as encounter_location,
    l.mcoe_location,
    coalesce(p.dead, 0)                                       as patient_died,
    count(distinct c.encounter_id)                            as encounters_changed,
    sum(c.change_type = 'form deleted')                       as encounters_deleted,
    sum(c.change_type = 'answer changed')                     as answers_changed,
    sum(c.change_type = 'answer removed')                     as answers_removed,
    sum(c.change_type = 'answer added later')                 as answers_added_later,
    sum(c.change_type = 'diagnosis changed')                  as diagnoses_changed,
    sum(c.change_type = 'form details changed')               as details_changed,
    count(*)                                                  as total_changes,
    count(distinct c.user_id)                                 as distinct_users
from temp_ecs_events c
inner join temp_ecs_enc e          on e.encounter_id = c.encounter_id
inner join encounter_type et       on et.encounter_type_id = e.encounter_type
left join  temp_ecs_user_role r    on r.user_id = c.user_id
left join  temp_ecs_loc l          on l.location_id = e.location_id
left join  person p                on p.person_id = e.patient_id
group by 1, 2, 3, 4, 5, 6, 7, 8;
