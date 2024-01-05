-- ---- All Encounters
set @partition = '${partitionNum}';
SELECT patient_identifier_type_id INTO @identifier_type FROM patient_identifier_type pit WHERE uuid ='1a2acce0-7426-11e5-a837-0800200c9a66';
SELECT patient_identifier_type_id INTO @kgh_identifier_type FROM patient_identifier_type pit WHERE uuid ='c09a1d24-7162-11eb-8aa6-0242ac110002';

DROP temporary TABLE IF EXISTS all_encounters;
create temporary table all_encounters(
encounter_id int,
patient_id int, 
visit_id int,
wellbody_emr_id varchar(50),
kgh_emr_id varchar(50),
encounter_type varchar(50),
encounter_type_id int,
encounter_provider varchar(50),
encounter_datetime datetime,
encounter_year int,
encounter_month int,
date_entered date,
created_by varchar(30),
index_asc int, 
index_desc int
);


insert into all_encounters(encounter_id,patient_id, visit_id, encounter_type,encounter_type_id, encounter_datetime, 
		encounter_year, encounter_month, date_entered, created_by)
select e.encounter_id,
	e.patient_id,
	e.visit_id,
	et.name encounter_type,
	e.encounter_type encounter_type_id,
	e.encounter_datetime,
	year(e.encounter_datetime) as encounter_year,
	month(e.encounter_datetime) as encounter_month,
	e.date_created,
	u.username as created_by
from encounter e
left outer join encounter_type et on e.encounter_type =et.encounter_type_id 
left outer join users u on e.creator =u.user_id
WHERE e.voided =0;

UPDATE all_encounters ae
SET ae.wellbody_emr_id= patient_identifier(ae.patient_id,'1a2acce0-7426-11e5-a837-0800200c9a66');

UPDATE all_encounters ae 
SET ae.kgh_emr_id= patient_identifier(ae.patient_id,'c09a1d24-7162-11eb-8aa6-0242ac110002');

UPDATE all_encounters ae 
SET ae.encounter_provider=provider(ae.encounter_id);

select 
encounter_id,
concat(@partition,"-",patient_id) patient_id,
visit_id,
wellbody_emr_id,
kgh_emr_id,
COALESCE(wellbody_emr_id, kgh_emr_id) emr_id,
encounter_type,
encounter_type_id,
encounter_provider,
encounter_datetime,
date_entered,
created_by AS user_entered,
index_asc,
index_desc
from all_encounters;