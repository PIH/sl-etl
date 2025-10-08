SET @locale = GLOBAL_PROPERTY_VALUE('default_locale', 'en');
set @partition = '${partitionNum}';

select encounter_type_id into @checkInEncounterTypeId from encounter_type where uuid = '55a0d3ea-a4d7-4e88-8f01-5aceb2d3c61b';
select encounter_type_id into @maternalCheckInEncounterTypeId from encounter_type where uuid = '251c03fa-a9dc-4157-855f-b016f4fae9ab';

DROP temporary TABLE IF EXISTS temp_checkins;
create temporary table temp_checkins(
encounter_id       int,          
patient_id         int,           
visit_id           int,          
emr_id             varchar(50),  
encounter_type     varchar(50),  
encounter_type_id  int,          
provider           text,         
encounter_datetime datetime,     
location_id        int(11),      
encounter_location varchar(255), 
datetime_entered   datetime,     
creator            int(11),      
user_entered       text,         
type_of_visit      varchar(255), 
refer_to_mcoe      bit,          
index_asc          int,           
index_desc         int           
);

insert into temp_checkins(encounter_id, patient_id, visit_id, encounter_type_id, encounter_datetime, location_id,
		datetime_entered, creator)
select e.encounter_id,
	e.patient_id,
	e.visit_id,
	e.encounter_type,
	e.encounter_datetime,
	e.location_id,
	e.date_created,
	e.creator 
from encounter e
WHERE e.voided = 0
and e.encounter_type in (@checkInEncounterTypeId, @maternalCheckInEncounterTypeId);

create index temp_checkins_pi on temp_checkins(patient_id);
create index temp_checkins_ei on temp_checkins(encounter_id);

-- patient data
DROP TEMPORARY TABLE IF EXISTS temp_patient;
CREATE TEMPORARY TABLE temp_patient
(
patient_id      int(11),      
wellbody_emr_id varchar(50),  
kgh_emr_id      varchar(50),  
emr_id          varchar(50)
);
   
insert into temp_patient(patient_id)
select distinct patient_id from temp_checkins;

create index temp_patient_pi on temp_patient(patient_id);

UPDATE temp_patient SET emr_id = patient_identifier(patient_id, metadata_uuid('org.openmrs.module.emrapi', 'emr.primaryIdentifierType'));

update temp_checkins t
inner join temp_patient p on p.patient_id = t.patient_id
set t.emr_id = p.emr_id;
 		
UPDATE temp_checkins t 
SET t.provider=provider(t.encounter_id);

UPDATE temp_checkins t 
SET t.encounter_location = location_name(t.location_id);

UPDATE temp_checkins t 
SET t.user_entered = person_name_of_user(t.creator);

UPDATE temp_checkins t 
SET t.encounter_type = encounter_type_name_from_id(t.encounter_type_id);

-- obs data
DROP TEMPORARY TABLE IF EXISTS temp_obs;
create temporary table temp_obs
select o.obs_id, o.voided, o.obs_group_id, o.encounter_id, o.person_id, o.concept_id, o.value_coded, o.value_numeric,
       o.value_text,o.value_datetime, o.comments, o.date_created, o.obs_datetime
from obs o
inner join temp_checkins t on t.encounter_id = o.encounter_id
where o.voided = 0;

create index temp_obs_encs_ei on temp_obs(encounter_id);
create index temp_obs_encs_c1 on temp_obs(encounter_id, concept_id);

UPDATE temp_checkins t 
SET type_of_visit = obs_value_coded_list_from_temp(t.encounter_id, 'PIH','6189',@locale);

UPDATE temp_checkins t 
SET refer_to_mcoe =  answer_exists_in_encounter_temp(t.encounter_id, 'PIH', '1272','PIH', '14976');

select 
concat(@partition,"-",encounter_id) as encounter_id,
concat(@partition,"-",patient_id)  as patient_id,
concat(@partition,"-",visit_id)  as visit_id,
emr_id,
encounter_type,
encounter_location,
provider,
encounter_datetime,
datetime_entered,
user_entered,
type_of_visit,
refer_to_mcoe,
index_asc,
index_desc
from temp_checkins;
