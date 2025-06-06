-- ---- All Encounters
set @partition = '${partitionNum}';
SELECT patient_identifier_type_id INTO @identifier_type FROM patient_identifier_type pit WHERE uuid ='1a2acce0-7426-11e5-a837-0800200c9a66';
SELECT patient_identifier_type_id INTO @kgh_identifier_type FROM patient_identifier_type pit WHERE uuid ='c09a1d24-7162-11eb-8aa6-0242ac110002';

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
encounter_year int,
encounter_month int,
datetime_entered datetime,
created_by varchar(30),
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
emr_id          varchar(50)
);
   
insert into temp_patient(patient_id)
select distinct patient_id from all_encounters;

create index temp_patient_pi on temp_patient(patient_id);

UPDATE temp_patient SET wellbody_emr_id= patient_identifier(patient_id,'1a2acce0-7426-11e5-a837-0800200c9a66');
UPDATE temp_patient SET kgh_emr_id= patient_identifier(patient_id,'c09a1d24-7162-11eb-8aa6-0242ac110002');
UPDATE temp_patient SET emr_id = patient_identifier(patient_id, metadata_uuid('org.openmrs.module.emrapi', 'emr.primaryIdentifierType'));

update all_encounters t
inner join temp_patient p on p.patient_id = t.patient_id
set t.wellbody_emr_id = p.wellbody_emr_id,
	t.kgh_emr_id = p.kgh_emr_id,
	t.emr_id = p.emr_id;
 	
UPDATE all_encounters ae 
SET ae.provider=provider(ae.encounter_id);

UPDATE all_encounters ae 
SET ae.encounter_location = location_name(ae.location_id);

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
provider,
encounter_datetime,
datetime_entered,
created_by AS user_entered,
index_asc,
index_desc
from all_encounters;
