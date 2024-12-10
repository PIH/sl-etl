-- --------------- Variables ----------------------------
set @partition = '${partitionNum}';
set @locale = 'en';
select encounter_type_id  into @regEncounterType from encounter_type et where uuid='873f968a-73a8-4f9c-ac78-9f4778b751b6';

DROP TABLE IF EXISTS temp_patients;
CREATE TEMPORARY TABLE  temp_patients
(wellbody_emr_id                   varchar(50),   
kgh_emr_id                        varchar(50),  
emr_id                            varchar(50),  
sl_national_id                    varchar(50),  
patient_id                        int,           
mothers_first_name                VARCHAR(255),  
country                           VARCHAR(255),  
registration_encounter_id         int(11),       
district                          VARCHAR(255),  
chiefdom                          VARCHAR(255),  
section                           VARCHAR(255),  
village                           VARCHAR(255),  
telephone_number                  VARCHAR(255),  
civil_status                      VARCHAR(255),  
occupation                        VARCHAR(255),  
reg_location                      varchar(50),   
reg_location_id                   int(11),       
registration_date                 date,          
registration_entry_date           datetime,      
creator                           int(11),       
user_entered                      varchar(50),   
first_encounter_date              date,          
last_encounter_date               date,          
name                              varchar(50),   
family_name                       varchar(50),   
dob                               date,          
dob_estimated                     bit,           
gender                            varchar(2),    
dead                              bit,           
death_date                        date,          
cause_of_death_concept_id         int(11),       
cause_of_death                    varchar(100), 
last_modified_patient             datetime,     
last_modified_datetime            datetime,     
last_modified_person_datetime     datetime,     
last_modified_name_datetime       datetime,     
last_modified_address_datetime    datetime,     
last_modified_attributes_datetime datetime,     
last_modified_obs_datetime        datetime,
last_modified_registration_datetime datetime      
);

-- load all patients
insert into temp_patients (patient_id,last_modified_patient) 
select patient_id,COALESCE(date_changed, date_created) from patient p where p.voided = 0;
create index temp_patients_pi on temp_patients(patient_id);


-- person info
update temp_patients t
inner join person p on p.person_id = t.patient_id
set t.gender = p.gender,
	t.dob = p.birthdate,
	t.dob_estimated = p.birthdate_estimated,
	t.dead = p.dead,
	t.death_date = p.death_date,
	t.cause_of_death_concept_id = p.cause_of_death,
	t.last_modified_person_datetime = COALESCE(date_changed,date_created);

-- name info
update temp_patients t
inner join person_name n on n.person_name_id =
	(select n2.person_name_id from person_name n2
	where n2.person_id = t.patient_id
	order by preferred desc, date_created desc limit 1)
set t.name = n.given_name,
	t.family_name = n.family_name,
	t.last_modified_name_datetime = COALESCE(date_changed,date_created);

-- address info
update temp_patients t
inner join person_address a on a.person_address_id =
	(select a2.person_address_id from person_address a2
	where a2.person_id = t.patient_id
	order by preferred desc, date_created desc limit 1)
set t.country = a.country,
	t.chiefdom = a.state_province,
	t.village = a.city_village,
	t.district = a.county_district ,
	t.section = a.address1,
	t.last_modified_address_datetime = COALESCE(date_changed,date_created);

-- identifiers
update temp_patients t set wellbody_emr_id = patient_identifier(patient_id,'1a2acce0-7426-11e5-a837-0800200c9a66');
update temp_patients t set kgh_emr_id = patient_identifier(patient_id, 'c09a1d24-7162-11eb-8aa6-0242ac110002');
update temp_patients t set sl_national_id = patient_identifier(patient_id, 'eb201574-8abe-4393-9a8a-8d30a48a08ad');
update temp_patients set emr_id = patient_identifier(patient_id, metadata_uuid('org.openmrs.module.emrapi', 'emr.primaryIdentifierType'));

select person_attribute_type_id into @telephone from person_attribute_type where name = 'Telephone Number' ;
select person_attribute_type_id into @motherName from person_attribute_type where name = 'First Name of Mother' ;
-- person attributes
update temp_patients t set telephone_number = person_attribute_value(patient_id,'Telephone Number');
update temp_patients t set mothers_first_name = person_attribute_value(patient_id,'First Name of Mother');
update temp_patients t set last_modified_attributes_datetime =
	(select max(COALESCE(date_changed,date_created)) from person_attribute a 
	where a.person_id = t.patient_id
	and a.voided = 0
	and a.person_attribute_type_id in (@telephone, @motherName));

-- registration encounter
update temp_patients t set registration_encounter_id = latestEnc(patient_id,'Patient Registration',null);
create index temp_patients_pri on temp_patients(registration_encounter_id); 

-- registration encounter fields
update temp_patients t 
inner join encounter e on e.encounter_id = t.registration_encounter_id
set t.reg_location_id = e.location_id,
	t.registration_entry_date = e.date_created,
	t.registration_date = e.encounter_datetime,
	t.creator = e.creator,
    t.last_modified_registration_datetime = e.date_changed;

update temp_patients t set reg_location = location_name(reg_location_id);
update temp_patients t set user_entered = person_name_of_user(creator);

-- registration obs
set @civilStatus = concept_from_mapping('PIH','1054');
set @occupation = concept_from_mapping('PIH','1304');

DROP TABLE IF EXISTS temp_obs;
CREATE TEMPORARY TABLE temp_obs AS
SELECT o.person_id, o.obs_id ,o.obs_group_id, o.obs_datetime, o.date_created, o.encounter_id, o.value_coded, o.concept_id, o.value_numeric, o.voided, o.value_drug
from obs o
inner join temp_patients t on t.registration_encounter_id = o.encounter_id
WHERE o.voided = 0;
create index temp_obs_ci1 on temp_obs(encounter_id, concept_id);
create index temp_obs_pi on temp_obs(person_id);

update temp_patients t set civil_status = obs_value_coded_list_from_temp(t.registration_encounter_id, 'PIH','1054',@locale );
update temp_patients t set occupation = obs_value_coded_list_from_temp(t.registration_encounter_id, 'PIH','1304',@locale );
update temp_patients t set last_modified_obs_datetime = 
	(select max(o.date_created) from temp_obs o where o.person_id = t.patient_id);

-- first/latest encounter
update temp_patients t set first_encounter_date = (select min(encounter_datetime) from encounter e where e.patient_id = t.patient_id);
update temp_patients t set last_encounter_date = (select max(encounter_datetime) from encounter e where e.patient_id = t.patient_id);

-- set last modified datetime to most recent of all the changes
update temp_patients t set last_modified_datetime =
	greatest(ifnull(last_modified_person_datetime,last_modified_patient),
			ifnull(last_modified_name_datetime,last_modified_patient),
			ifnull(last_modified_address_datetime,last_modified_patient),
			ifnull(last_modified_attributes_datetime,last_modified_patient),
			ifnull(last_modified_obs_datetime,last_modified_patient),
            ifnull(last_modified_registration_datetime,last_modified_patient),			
			last_modified_patient);

SELECT 
wellbody_emr_id,
kgh_emr_id,
sl_national_id,
emr_id,
concat(@partition,"-",patient_id)  patient_id,
mothers_first_name,
country,
district,
chiefdom,
section,
village,
telephone_number,
civil_status,
occupation,
reg_location,
registration_date,
registration_entry_date,
user_entered,
first_encounter_date,
last_encounter_date,
name,
family_name,
dob,
dob_estimated,
gender,
dead,
death_date,
cause_of_death,
last_modified_datetime
FROM temp_patients;
