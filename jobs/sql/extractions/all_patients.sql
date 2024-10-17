-- --------------- Variables ----------------------------
set @partition = '${partitionNum}';
set @locale = 'en';
select encounter_type_id  into @regEncounterType from encounter_type et where uuid='873f968a-73a8-4f9c-ac78-9f4778b751b6';

DROP TABLE IF EXISTS temp_patients;
CREATE TEMPORARY TABLE  temp_patients
(
wellbody_emr_id           varchar(50),  
kgh_emr_id                varchar(50),  
patient_id                int,           
mothers_first_name        VARCHAR(255), 
country                   VARCHAR(255), 
registration_encounter_id int(11),      
district                  VARCHAR(255), 
chiefdom                  VARCHAR(255), 
section                   VARCHAR(255), 
village                   VARCHAR(255), 
telephone_number          VARCHAR(255), 
civil_status              VARCHAR(255), 
occupation                VARCHAR(255), 
reg_location              varchar(50),  
reg_location_id           int(11),      
registration_date         date,         
registration_entry_date   datetime,     
creator                   int(11),      
user_entered              varchar(50),  
first_encounter_date      date,         
last_encounter_date       date,          
name                      varchar(50),  
family_name               varchar(50),  
dob                       date,         
dob_estimated             bit,          
gender                    varchar(2),   
dead                      bit,          
death_date                date,         
cause_of_death_concept_id int(11),      
cause_of_death            varchar(100)  
);

-- load all patients
insert into temp_patients (patient_id) 
select patient_id from patient p where p.voided = 0;

-- person info
update temp_patients t
inner join person p on p.person_id = t.patient_id
set t.gender = p.gender,
	t.dob = p.birthdate,
	t.dob_estimated = p.birthdate_estimated,
	t.dead = p.dead,
	t.death_date = p.death_date,
	t.cause_of_death_concept_id = p.cause_of_death; 

update temp_patients t set cause_of_death = concept_name(cause_of_death_concept_id,@locale);

-- name info
update temp_patients t set name = person_given_name(patient_id);
update temp_patients t set family_name = person_family_name(patient_id);

-- address info
update temp_patients t set country = person_address_country(patient_id);
update temp_patients t set district = person_address_county_district(patient_id);
update temp_patients t set chiefdom = person_address_state_province(patient_id);
update temp_patients t set section = person_address_one(patient_id);
update temp_patients t set village = person_address_city_village(patient_id);

-- identifiers
update temp_patients t set wellbody_emr_id = patient_identifier(patient_id,'1a2acce0-7426-11e5-a837-0800200c9a66');
update temp_patients t set kgh_emr_id = patient_identifier(patient_id, 'c09a1d24-7162-11eb-8aa6-0242ac110002');

-- person attributes
update temp_patients t set telephone_number = person_attribute_value(patient_id,'Telephone Number');
update temp_patients t set mothers_first_name = person_attribute_value(patient_id,'First Name of Mother');

-- registration encounter
update temp_patients t set registration_encounter_id = latestEnc(patient_id,'Patient Registration',null);

-- registration encounter fields
update temp_patients t 
inner join encounter e on e.encounter_id = t.registration_encounter_id
set t.reg_location_id = e.location_id,
	t.registration_entry_date = e.date_created,
	t.registration_date = e.encounter_datetime,
	t.creator = e.creator ;

update temp_patients t set reg_location = location_name(reg_location_id);
update temp_patients t set user_entered = person_name_of_user(creator);

-- registration obs
DROP TABLE IF EXISTS temp_obs;
CREATE TEMPORARY TABLE temp_obs AS
SELECT o.person_id, o.obs_id ,o.obs_group_id, o.obs_datetime, o.date_created, o.encounter_id, o.value_coded, o.concept_id, o.value_numeric, o.voided, o.value_drug
FROM temp_patients t INNER JOIN obs o ON t.registration_encounter_id = o.encounter_id
WHERE o.voided = 0;
create index temp_obs_ci1 on temp_obs(concept_id);

update temp_patients t set civil_status = obs_value_coded_list_from_temp(t.registration_encounter_id, 'PIH','1054',@locale );
update temp_patients t set occupation = obs_value_coded_list_from_temp(t.registration_encounter_id, 'PIH','1304',@locale );

-- first/latest encounter
update temp_patients t set first_encounter_date = (select min(encounter_datetime) from encounter e where e.patient_id = t.patient_id);
update temp_patients t set last_encounter_date = (select max(encounter_datetime) from encounter e where e.patient_id = t.patient_id);

SELECT 
wellbody_emr_id,
kgh_emr_id,
COALESCE(wellbody_emr_id, kgh_emr_id)  emr_id,
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
cause_of_death
FROM temp_patients;
