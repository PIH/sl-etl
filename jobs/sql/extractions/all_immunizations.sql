set @immunization = concept_from_mapping('PIH','10156');
set @pregnancyProgramId = program('Pregnancy');
set @partition = '${partitionNum}';

drop temporary table if exists temp_immunizations;
create temporary table temp_immunizations
(patient_id                 int,          
emr_id                     varchar(255), 
encounter_id               int,       
obs_group_id               int,
visit_id                   int,
pregnancy_program_id       int, 
encounter_datetime         datetime, 
encounter_location         varchar(255), 
datetime_entered           datetime,     
user_entered               varchar(255), 
provider                   varchar(255),
encounter_type             varchar(255), 
age_at_encounter           int,
value_coded                int,
immunization               varchar(255),
immunization_date          date,
index_asc                  int,
index_desc                 int);

insert into temp_immunizations(patient_id, encounter_id, obs_group_id, value_coded)
select person_id, encounter_id, obs_group_id, value_coded 
from obs o 
where o.voided = 0
and concept_id = @immunization;

create index temp_immunizations_ei on temp_immunizations(encounter_id);

drop temporary table if exists temp_immunizations_encounter;
create temporary table temp_immunizations_encounter
(patient_id                int,          
emr_id                     varchar(255), 
encounter_id               int,       
visit_id                   int,
encounter_datetime         datetime,     
location_id                int,
encounter_location         varchar(255), 
datetime_entered           datetime,
creator                    int,
user_entered               varchar(255), 
provider                   varchar(255),
encounter_type_id          int,
encounter_type             varchar(255), 
age_at_encounter           int,
pregnancy_program_id       int);

insert into temp_immunizations_encounter(encounter_id)
select distinct encounter_id from temp_immunizations;

create index temp_immunizations_encounter_ei on temp_immunizations_encounter(encounter_id);

update temp_immunizations_encounter t 
inner join encounter e on t.encounter_id = e.encounter_id
set t.patient_id = e.patient_id,
	t.visit_id = e.visit_id, 
	t.encounter_datetime = e.encounter_datetime, 
	t.location_id = e.location_id, 
	t.datetime_entered = e.date_created, 
	t.creator = e.creator, 
	t.encounter_type_id = e.encounter_type;

set @primary_identifier = metadata_uuid('org.openmrs.module.emrapi', 'emr.primaryIdentifierType');
UPDATE temp_immunizations_encounter t
SET emr_id = patient_identifier(patient_id, @primary_identifier);

UPDATE temp_immunizations_encounter t
SET encounter_location = location_name(location_id);

UPDATE temp_immunizations_encounter
set user_entered = person_name_of_user(creator);

UPDATE temp_immunizations_encounter
set encounter_type = encounter_type_name_from_id(encounter_type_id);

UPDATE temp_immunizations_encounter
set provider = provider(encounter_id);

UPDATE temp_immunizations_encounter
set age_at_encounter = age_at_enc(patient_id, encounter_id);

UPDATE temp_immunizations_encounter
set pregnancy_program_id = patient_program_id_from_encounter(patient_id, @pregnancyProgramId ,encounter_id);

update temp_immunizations i 
inner join temp_immunizations_encounter e on e.encounter_id = i.encounter_id 
set i.emr_id = e.emr_id,
	i.encounter_id = e.encounter_id,
	i.visit_id = e.visit_id,
	i.encounter_datetime = e.encounter_datetime,
	i.encounter_location = e.encounter_location,
	i.datetime_entered = e.datetime_entered,
	i.user_entered = e.user_entered,
	i.provider = e.provider,
	i.encounter_type = e.encounter_type,
	i.age_at_encounter = e.age_at_encounter,
	i.pregnancy_program_id = e.pregnancy_program_id;

update temp_immunizations t set immunization = concept_name(value_coded, @locale);
update temp_immunizations t set immunization_date = obs_from_group_id_value_datetime(obs_group_id, 'PIH','10170');

select 
concat(@partition, '-', obs_group_id) as obs_id,
concat(@partition, '-', patient_id) as patient_id,
concat(@partition, '-', encounter_id) as encounter_id,
concat(@partition, '-', visit_id) as visit_id,
emr_id,
concat(@partition, '-', pregnancy_program_id) as pregnancy_program_id,
encounter_datetime,
encounter_location,
datetime_entered,
user_entered,
provider,
encounter_type,
age_at_encounter,
immunization,
immunization_date,
index_asc,
index_desc
from temp_immunizations;
