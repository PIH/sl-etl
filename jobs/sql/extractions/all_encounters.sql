-- ---- All Encounters
set @partition = '${partitionNum}';
SELECT patient_identifier_type_id INTO @identifier_type FROM patient_identifier_type pit WHERE uuid ='1a2acce0-7426-11e5-a837-0800200c9a66';
SELECT patient_identifier_type_id INTO @kgh_identifier_type FROM patient_identifier_type pit WHERE uuid ='c09a1d24-7162-11eb-8aa6-0242ac110002';

select location_id into @anc from location where uuid = '11f5c9f9-40b8-46ad-9e7e-59473ce43246';
select location_id into @labour from location where uuid = '11377a5b-6850-11ee-ab8d-0242ac120002';
select location_id into @nicu from location where uuid = '0ce2f6fb-6850-11ee-ab8d-0242ac120002';
select location_id into @pacu from location where uuid = '17596678-6850-11ee-ab8d-0242ac120002';
select location_id into @pnc from location where uuid = 'ff0d5e73-3fe0-437f-90ba-7d605ac03dc0';
select location_id into @quiet from location where uuid = '28660b7f-3450-4b86-b840-9670ec68235f';
select location_id into @mccu from location where uuid = '4d7e927d-6850-11ee-ab8d-0242ac120002';
select location_id into @postop from location where uuid = 'a39ec469-d1f9-11f0-9d46-169316be6a48';
select location_id into @preop from location where uuid = '142de844-6850-11ee-ab8d-0242ac120002';
select location_id into @kgh_mch from location where uuid = '5981f962-6eec-453d-89ce-2f9ac48d096f';
select location_id into @mcoe_pharmacy from location where uuid = '550e8400-e29b-41d4-a716-446655440000';
select location_id into @mcoe_registration from location where uuid = '07aa9943-d1fa-11f0-9d46-169316be6a48';
select location_id into @mcoe_triage from location where uuid = 'f85feffc-fe54-4648-aa14-01ed6d30b943';
select location_id into @mothers_dorm from location where uuid = '989a9b23-d1f9-11f0-9d46-169316be6a48';
select location_id into @staff from location where uuid = 'adde966c-d1f9-11f0-9d46-169316be6a48';
select location_id into @kangaroo from location where uuid = '81080213-d1f9-11f0-9d46-169316be6a48';

set @next_appt_date_concept_id = CONCEPT_FROM_MAPPING('PIH', 5096);
set @disposition_concept_id = concept_from_mapping('PIH','8620');

DROP temporary TABLE IF EXISTS all_encounters;
create temporary table all_encounters(
encounter_id int,
patient_id int, 
visit_id int,
emr_id varchar(50),
wellbody_emr_id varchar(50),
kgh_emr_id varchar(50),
encounter_type varchar(50),
encounter_type_id int,
provider varchar(50),
encounter_datetime datetime,
location_id int(11),
encounter_location varchar(255),
mcoe_location boolean,
encounter_year int,
encounter_month int,
birthdate date,
datetime_entered datetime,
age_at_encounter int,
created_by varchar(30),
next_appt_date       date,
disposition          varchar(255),
index_asc int, 
index_desc int
);

insert into all_encounters(encounter_id,patient_id, visit_id, encounter_type,encounter_type_id, encounter_datetime, location_id,
		encounter_year, encounter_month, datetime_entered, created_by)
select e.encounter_id,
	e.patient_id,
	e.visit_id,
	et.name encounter_type,
	e.encounter_type encounter_type_id,
	e.encounter_datetime,
	e.location_id,
	year(e.encounter_datetime) as encounter_year,
	month(e.encounter_datetime) as encounter_month,
	e.date_created,
	u.username as created_by
from encounter e
left outer join encounter_type et on e.encounter_type =et.encounter_type_id 
left outer join users u on e.creator =u.user_id
WHERE e.voided =0;

create index all_encounters_pi on all_encounters(patient_id);
create index all_encounters_ei on all_encounters(encounter_id);

DROP TEMPORARY TABLE IF EXISTS temp_patient;
CREATE TEMPORARY TABLE temp_patient
(
patient_id      int(11),      
wellbody_emr_id varchar(50),  
kgh_emr_id      varchar(50),  
emr_id          varchar(50),
birthdate       date       
);
   
insert into temp_patient(patient_id)
select distinct patient_id from all_encounters;

create index temp_patient_pi on temp_patient(patient_id);

UPDATE temp_patient SET wellbody_emr_id= patient_identifier(patient_id,'1a2acce0-7426-11e5-a837-0800200c9a66');
UPDATE temp_patient SET kgh_emr_id= patient_identifier(patient_id,'c09a1d24-7162-11eb-8aa6-0242ac110002');
UPDATE temp_patient SET emr_id = patient_identifier(patient_id, metadata_uuid('org.openmrs.module.emrapi', 'emr.primaryIdentifierType'));

UPDATE temp_patient t 
inner join person p on p.person_id = t.patient_id
set t.birthdate = p.birthdate;

update all_encounters t
inner join temp_patient p on p.patient_id = t.patient_id
set t.wellbody_emr_id = p.wellbody_emr_id,
	t.kgh_emr_id = p.kgh_emr_id,
	t.emr_id = p.emr_id,
	t.birthdate = p.birthdate;
 	
UPDATE all_encounters ae 
SET ae.provider=provider(ae.encounter_id);

UPDATE all_encounters ae 
SET ae.encounter_location = location_name(ae.location_id);

UPDATE all_encounters ae 
SET ae.mcoe_location = 1
where ae.location_id in (@anc, @labour, @nicu, @pacu, @pnc, @quiet, @mccu, @postop, @preop, @kgh_mch,
  @mcoe_pharmacy, @mcoe_registration, @mcoe_triage, @mothers_dorm, @staff, @kangaroo);

UPDATE all_encounters ae 
SET age_at_encounter = TIMESTAMPDIFF(YEAR, birthdate, encounter_datetime);

-- get next appointment, disposition
set @disposition_concept_id = concept_from_mapping('PIH','8620');
DROP TEMPORARY TABLE IF EXISTS temp_obs;
CREATE TEMPORARY TABLE temp_obs
select encounter_id, concept_id, value_coded, value_datetime
from obs
where concept_id in (@next_appt_date_concept_id, @disposition_concept_id)
  and voided = 0
group by encounter_id;

DROP TEMPORARY TABLE IF EXISTS temp_obs_collated;
CREATE TEMPORARY TABLE temp_obs_collated
select encounter_id,
max(case when concept_id = @next_appt_date_concept_id then value_datetime end) "next_appt_date",
max(case when concept_id = @disposition_concept_id then concept_name(value_coded, @locale) end) "disposition"
from temp_obs
group by encounter_id;

create index temp_obs_collated_ei on temp_obs_collated(encounter_id);

UPDATE all_encounters t
inner join temp_obs_collated o on o.encounter_id = t.encounter_id
set t.next_appt_date = o.next_appt_date,
    t.disposition = o.disposition;

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
provider,
encounter_datetime,
datetime_entered,
created_by AS user_entered,
age_at_encounter,
disposition,
next_appt_date,
index_asc,
index_desc
from all_encounters;
