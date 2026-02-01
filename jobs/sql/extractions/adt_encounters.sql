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

SET @partition = '${partitionNum}';
SET sql_safe_updates = 0;

select encounter_type_id  into @trf_type_id 
from encounter_type et where uuid='436cfe33-6b81-40ef-a455-f134a9f7e580';

select encounter_type_id  into @adm_type_id 
from encounter_type et where uuid='260566e1-c909-4d61-a96f-c1019291a09d';

select encounter_type_id  into @sort_type_id 
from encounter_type et where uuid='b6631959-2105-49dd-b154-e1249e0fbcd7';

select encounter_type_id  into @cons_type_id 
from encounter_type et where uuid='92fd09b4-5335-4f7e-9f63-b2a663fd09a6';
SELECT 'a541af1e-105c-40bf-b345-ba1fd6a59b85' INTO @emr_identifier_type;

drop temporary table if exists adt_encounters;
create temporary table adt_encounters
(
    patient_id           int,
	emr_id               varchar(15),
    encounter_id         int,
    visit_id			 int,
    encounter_datetime   datetime,
    creator              varchar(255),
    datetime_created	 datetime,
    location_id          int(11),
    encounter_location   varchar(255),
    mcoe_location        boolean,
    provider 			 varchar(255),
    encounter_type 		 int,
    encounter_type_name  varchar(50),
    index_asc			 int,
    index_desc			 int
);


insert into adt_encounters (patient_id, encounter_id, visit_id, encounter_datetime, datetime_created, encounter_type, location_id)
select patient_id, encounter_id, visit_id, encounter_datetime, date_created, encounter_type, location_id
from encounter e
where e.voided = 0
AND encounter_type IN (@adm_type_id , @trf_type_id , @sort_type_id)
ORDER BY encounter_datetime desc;

UPDATE adt_encounters
SET encounter_type_name = encounter_type_name_from_id(encounter_type);

UPDATE adt_encounters
SET creator = encounter_creator_name(encounter_id);

UPDATE adt_encounters
SET encounter_location = location_name(location_id);

UPDATE adt_encounters
SET provider = provider(encounter_id);

set @primary_identifier = metadata_uuid('org.openmrs.module.emrapi', 'emr.primaryIdentifierType');
UPDATE adt_encounters t
SET emr_id = patient_identifier(patient_id, @primary_identifier);

UPDATE adt_encounters ae
SET ae.mcoe_location = 1
where ae.location_id in (@anc, @labour, @nicu, @pacu, @pnc, @quiet, @mccu, @postop, @preop, @kgh_mch,
  @mcoe_pharmacy, @mcoe_registration, @mcoe_triage, @mothers_dorm, @staff, @kangaroo);

SELECT 
emr_id,
CONCAT(@partition,'-',encounter_id) "encounter_id",
CONCAT(@partition,'-',visit_id) "visit_id",
encounter_datetime,
creator AS user_entered,
datetime_created,
encounter_type_name AS encounter_type,
encounter_location,
mcoe_location,
provider,
index_asc,
index_desc
FROM adt_encounters;
