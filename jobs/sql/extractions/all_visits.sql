set @partition = '${partitionNum}';
SELECT patient_identifier_type_id INTO @identifier_type
FROM patient_identifier_type pit WHERE uuid ='1a2acce0-7426-11e5-a837-0800200c9a66';
SELECT patient_identifier_type_id INTO @kgh_identifier_type 
FROM patient_identifier_type pit WHERE uuid ='c09a1d24-7162-11eb-8aa6-0242ac110002';
select visit_attribute_type_id into @inbornAttributeType from visit_attribute_type vat where uuid =  '86f716fc-5e26-4eb1-9484-46370cff28f0';


drop temporary table if exists temp_visits;
create temporary table temp_visits
(
patient_id			int,
emr_id				varchar(50),
visit_id			int,
visit_date_started	datetime,
visit_date_stopped	datetime,
datetime_entered	datetime,
visit_creator		int,
user_entered	    varchar(255),
visit_type_id		int,
visit_type			varchar(255),
checkin_encounter_id int,	
location_id			int,
visit_location		varchar(255),
inborn              bit,
index_asc			int,
index_desc			int
);

insert into temp_visits(patient_id, visit_id, visit_date_started, visit_date_stopped, datetime_entered, visit_type_id, visit_creator, location_id)
select patient_id, visit_id, date_started, date_stopped, date_created, visit_type_id, creator, location_id  
from visit v 
where v.voided = 0
and patient_id in (select patient_id from patient where voided=0);

create index temp_visits_vi on temp_visits(visit_id);

-- emr_id
DROP TEMPORARY TABLE IF EXISTS temp_identifiers;
CREATE TEMPORARY TABLE temp_identifiers
(
patient_id						INT,
emr_id							VARCHAR(25)
);

INSERT INTO temp_identifiers(patient_id)
select distinct patient_id from temp_visits;

set @primary_emr_uuid = metadata_uuid('org.openmrs.module.emrapi', 'emr.primaryIdentifierType');
UPDATE temp_identifiers SET emr_id=patient_identifier(patient_id,@primary_emr_uuid );

CREATE INDEX temp_identifiers_p ON temp_identifiers (patient_id);

update temp_visits tv 
inner join temp_identifiers ti on ti.patient_id = tv.patient_id
set tv.emr_id = ti.emr_id;

-- visit type
update temp_visits t
inner join visit_type vt on vt.visit_type_id = t.visit_type_id
set t.visit_type = vt.name;

-- locations
update temp_visits tv 
set tv.visit_location = location_name(location_id);

-- user entered
DROP TEMPORARY TABLE IF EXISTS temp_users;
CREATE TEMPORARY TABLE temp_users
(
creator						INT,
creator_name				VARCHAR(255)
);

INSERT INTO temp_users(creator)
select distinct visit_creator from temp_visits;

CREATE INDEX temp_users_c ON temp_users(creator);

update temp_users t set creator_name  = person_name_of_user(creator);	

update temp_visits tv 
inner join temp_users tu on tu.creator = tv.visit_creator
set tv.user_entered = tu.creator_name;

update temp_visits tv 
inner join visit_attribute va on va.visit_id = tv.visit_id and value_reference = 'true'
set inborn = 1;  

select
concat(@partition,"-",patient_id) patient_id,
emr_id,
concat(@partition,"-",visit_id),
visit_date_started,
visit_date_stopped,
datetime_entered,
user_entered,
visit_type,
visit_location,
inborn,
index_asc,
index_desc
from temp_visits;
