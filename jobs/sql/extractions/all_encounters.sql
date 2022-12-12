-- ---- All Encounters
SELECT patient_identifier_type_id INTO @identifier_type FROM patient_identifier_type pit WHERE uuid ='1a2acce0-7426-11e5-a837-0800200c9a66';
SELECT patient_identifier_type_id INTO @kgh_identifier_type FROM patient_identifier_type pit WHERE uuid ='c09a1d24-7162-11eb-8aa6-0242ac110002';

DROP temporary TABLE IF EXISTS all_encounters;
create temporary table all_encounters(
encounter_id int,
patient_id int, 
wellbody_emr_id varchar(50),
kgh_emr_id varchar(50),
encounter_type varchar(50),
encounter_datetime datetime,
encounter_year int,
encounter_month int,
created_by varchar(30)
);

insert into all_encounters(encounter_id,patient_id, encounter_type, encounter_datetime, encounter_year, encounter_month, created_by)
select e.encounter_id,
	e.patient_id,
	et.name encounter_type,
	e.encounter_datetime,
	year(e.encounter_datetime) as encounter_year,
	month(e.encounter_datetime) as encounter_month,
	u.username as created_by
from encounter e
left outer join encounter_type et on e.encounter_type =et.encounter_type_id 
left outer join users u on e.creator =u.user_id;

UPDATE all_encounters ae
SET ae.wellbody_emr_id= (
 SELECT identifier
 FROM patient_identifier 
 WHERE identifier_type =@identifier_type
 AND patient_id=ae.patient_id
 AND voided=0
 ORDER BY preferred desc, date_created desc limit 1
);

UPDATE all_encounters ae 
SET ae.kgh_emr_id= (
 SELECT identifier
 FROM patient_identifier 
 WHERE identifier_type =@kgh_identifier_type
 AND patient_id=ae.patient_id
 AND voided=0
 ORDER BY preferred desc, date_created desc limit 1
);

delete from all_encounters 
where wellbody_emr_id is null and kgh_emr_id is null;

select 
encounter_id,
wellbody_emr_id,
kgh_emr_id,
encounter_type,
encounter_datetime,
encounter_year,
encounter_month,
created_by
from all_encounters;