set @partition = '${partitionNum}';
SET @locale='en';

SELECT encounter_type_id  INTO @mch_triage
FROM encounter_type et WHERE uuid='41911448-71a1-43d7-bba8-dc86339850da';

drop temporary table if exists temp_mch_triage;
create temporary table temp_mch_triage
(
patient_id                 int,          
emr_id                     varchar(255), 
encounter_id               int,          
visit_id                   int,
encounter_datetime         datetime,    
location_id                int(11),
encounter_location         varchar(255), 
datetime_entered           datetime,     
user_entered               varchar(255), 
provider                   varchar(255), 
age_at_encounter           int,
referral_form_received     boolean,
referral_from              varchar(255),
referral_datetime          datetime,
method_of_transport        varchar(255),
disposition                varchar(255),
admission_location_id      int,
admission_location         varchar(255)
);

insert into temp_mch_triage(patient_id, encounter_id, visit_id, encounter_datetime,
location_id, datetime_entered, user_entered)
select patient_id, encounter_id, visit_id, encounter_datetime, location_id, date_created, creator
from encounter e
where e.voided = 0
AND encounter_type IN (@mch_triage)
ORDER BY encounter_datetime desc;

UPDATE temp_mch_triage
set user_entered = person_name_of_user(user_entered);

UPDATE temp_mch_triage
SET provider = provider(encounter_id);

UPDATE temp_mch_triage t
SET emr_id = patient_identifier(patient_id, metadata_uuid('org.openmrs.module.emrapi', 'emr.primaryIdentifierType'));

UPDATE temp_mch_triage
SET encounter_location=location_name(location_id);

update temp_mch_triage
set age_at_encounter = age_at_enc(patient_id, encounter_id);

DROP TEMPORARY TABLE IF EXISTS temp_obs;
create temporary table temp_obs
select o.obs_id, o.voided ,o.obs_group_id , o.encounter_id, o.person_id, o.concept_id, o.value_coded, o.value_numeric,
o.value_text,o.value_datetime, o.comments, o.date_created, o.obs_datetime
from obs o
inner join temp_mch_triage t on t.encounter_id = o.encounter_id
where o.voided = 0;

create index temp_obs_encs_ei on temp_obs(encounter_id);

SET @referral_form_received = concept_from_mapping('PIH','20858');
SET @referral_from = concept_from_mapping('PIH','10647');
SET @referral_datetime = concept_from_mapping('PIH','11954');
SET @method_of_transport = concept_from_mapping('PIH','975');
SET @disposition = concept_from_mapping('PIH','8620');
SET @admission_location_id = concept_from_mapping('PIH','8622');

UPDATE temp_mch_triage t SET referral_form_received = obs_value_coded_as_boolean_from_temp_using_concept_id(encounter_id, @referral_form_received);
UPDATE temp_mch_triage t SET referral_from = obs_value_coded_list_from_temp_using_concept_id(encounter_id, @referral_from, @locale);
UPDATE temp_mch_triage t SET referral_datetime = obs_value_datetime_from_temp_using_concept_id(encounter_id, @referral_datetime);
UPDATE temp_mch_triage t SET method_of_transport = obs_value_coded_list_from_temp_using_concept_id(encounter_id, @method_of_transport, @locale);
UPDATE temp_mch_triage t SET disposition = obs_value_coded_list_from_temp_using_concept_id(encounter_id, @disposition, @locale);
UPDATE temp_mch_triage t SET admission_location_id = obs_value_text_from_temp_using_concept_id(encounter_id, @admission_location_id);
UPDATE temp_mch_triage t SET admission_location = location_name(admission_location_id);

select
concat(@partition,"-",encounter_id) as encounter_id,
concat(@partition,"-",patient_id)  as patient_id,
concat(@partition,"-",visit_id)  as visit_id,
emr_id,
encounter_datetime,
encounter_location,
datetime_entered,
user_entered,
provider,
age_at_encounter,
referral_form_received,
referral_from,
referral_datetime,
method_of_transport,
disposition,
admission_location
from temp_mch_triage;
