set @partition = '${partitionNum}';

DROP temporary TABLE IF EXISTS temp_appointments;
create temporary table temp_appointments
(
    appointment_id       int,
    patient_id           int,
    emr_id               varchar(50),
    date_issued          date,
    location             varchar(255),
    service              varchar(50),
    type                 varchar(45),
    recurring            bit,
    appointment_datetime datetime,
    duration             int,
    provider             varchar(255),
    status               varchar(45),
    note                 varchar(255),
    datetime_created     datetime,
    user_entered         varchar(255),
    index_asc            int,
    index_desc           int
);

insert into temp_appointments(
      appointment_id,
      patient_id,
 --     date_issued,
      location,
      service,
      type,
      recurring,
      appointment_datetime,
      duration,
      provider,
      status,
      note,
      datetime_created,
      user_entered
)
select
    a.patient_appointment_id as appointment_id,
    a.patient_id,
--    date(a.date_appointment_scheduled) as date_issued,
    location_name(a.location_id) as location,
    s.name as service,
    a.appointment_kind as type,
    0 as recurring,
    a.start_date_time as appointment_datetime,
    TIMESTAMPDIFF(MINUTE, a.start_date_time, a.end_date_time) as duration,
    provider_name_from_provider_id(a.provider_id) as provider,
    a.status,
    a.comments as note,
    a.date_created as datetime_created,  
    person_name_of_user(a.creator) as user_entered
from patient_appointment a
inner join patient p on a.patient_id = p.patient_id
left join appointment_service s on a.appointment_service_id = s.appointment_service_id
WHERE a.voided = 0 and p.voided = 0;

-- note the date_appointment_scheduled function will return the date appointement scheduled only if that column exists on the patient_appointment table
-- otherwise it will return null
-- the update statement can be moved into the insert statement above at some point after that column is added in all databases
update temp_appointments t
set date_issued = date(date_appointment_scheduled(t.appointment_id));

update temp_appointments set emr_id = patient_identifier(patient_id, metadata_uuid('org.openmrs.module.emrapi', 'emr.primaryIdentifierType'));
update temp_appointments a inner join patient_appointment_occurrence o on a.appointment_id = o.patient_appointment_id set a.recurring = 1;

update temp_appointments a
set a.provider = (
    select group_concat(distinct provider_name_from_provider_id(p.provider_id) separator ' | ')
    from patient_appointment_provider p
    where p.patient_appointment_id = a.appointment_id
    and p.response in ('AWAITING', 'ACCEPTED', 'TENTATIVE')
)
where a.provider is null;

select 
concat(@partition,'-',appointment_id) as appointment_id,
concat(@partition,'-',patient_id) as patient_id,
emr_id,
date_issued,
location,
service,
type,
recurring,
appointment_datetime,
duration,
provider,
status,
note,
datetime_created,
user_entered,
index_asc,
index_desc
from temp_appointments;
