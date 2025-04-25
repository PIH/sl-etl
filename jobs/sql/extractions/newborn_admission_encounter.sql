set @partition = '${partitionNum}';

SELECT encounter_type_id INTO @newborn_admission FROM encounter_type et WHERE uuid = '093b6ffc-e55a-461a-85cc-c6acf7714a23';
SELECT encounter_role_id INTO @consulting_clinician FROM encounter_role where uuid = '4f10ad1a-ec49-48df-98c7-1391c6ac7f05';

drop temporary table if exists temp_na;
create temporary table temp_na
(
patient_id                  int,          
emr_id                      varchar(255), 
encounter_id                int,           
visit_id                    int,           
encounter_datetime          datetime,     
encounter_location          varchar(255), 
datetime_entered            datetime,     
user_entered                varchar(255), 
admitting_clinician         varchar(255), 
admitted_to                 varchar(255),  
admission_date              date,      
condition_at_admission      varchar(255), 
clinical_adverse_effects    boolean, 
outborn_mothers_name        varchar(255), 
outborn_mothers_age         int,          
outborn_mother_is_alive     varchar(255), 
outborn_number_of_newborns  varchar(255),  
outborn_delivery_type       varchar(255), 
outborn_delivery_location   varchar(255), 
outborn_method_of_transport varchar(255), 
maternal_complications      text,
weight                      double,        
muac                        double,        
length                      double,        
head_circumference          double,        
heart_rate                  double,        
bp_systolic                 double,        
bp_diastolic                double,        
respiratory_rate            double,        
o2_saturation               double,        
temperature                 double,        
hemoglobin                  double,       
rbg                         double,       
mrdt                        varchar(255), 
bilirubin                   double,       
umbilical_cord              varchar(255), 
eyes                        varchar(255), 
skin_color                  varchar(255), 
urination                   varchar(255), 
stool                       varchar(255), 
neurological                varchar(255), 
seizures                    varchar(255), 
feeding_method              varchar(255), 
treatment_air               varchar(255), 
disposition                 varchar(255), 
death_date                  datetime,     
index_asc                   int,
index_desc                  int    
);

insert into temp_na(patient_id, encounter_id, visit_id, encounter_datetime, datetime_entered, user_entered)
select patient_id, encounter_id, visit_id, encounter_datetime, date_created, creator
from encounter e
where e.voided = 0
AND encounter_type IN (@newborn_admission)
ORDER BY encounter_datetime desc;

create index temp_na_ei on temp_na (encounter_id);

UPDATE temp_na set user_entered = person_name_of_user(user_entered);
UPDATE temp_na SET admitting_clinician = provider(encounter_id);
UPDATE temp_na  SET emr_id = patient_identifier(patient_id, metadata_uuid('org.openmrs.module.emrapi', 'emr.primaryIdentifierType'));
UPDATE temp_na SET encounter_location=encounter_location_name(encounter_id);
UPDATE temp_na t SET admitting_clinician = provider_name_of_type(encounter_id, @consulting_clinician, 0);
UPDATE temp_na t SET admitted_to = encounter_location;
UPDATE temp_na t SET admission_date = encounter_datetime;

DROP TEMPORARY TABLE IF EXISTS temp_obs;
create temporary table temp_obs
select o.obs_id, o.voided, o.obs_group_id, o.encounter_id, o.person_id, o.concept_id, o.value_coded, o.value_numeric,
       o.value_text,o.value_datetime, o.comments, o.date_created, o.obs_datetime
from obs o
inner join temp_na t on t.encounter_id = o.encounter_id
where o.voided = 0;

create index temp_obs_encs_ei on temp_obs(encounter_id);
create index temp_obs_encs_eobs on temp_obs(encounter_id, obs_group_id);

UPDATE temp_na set condition_at_admission = obs_value_coded_list_from_temp(encounter_id, 'PIH','1463','en');
UPDATE temp_na set clinical_adverse_effects = value_coded_as_boolean(obs_id_from_temp(encounter_id, 'PIH','14891',0));

UPDATE temp_na set outborn_mothers_name = obs_value_text_from_temp(encounter_id, 'PIH','14691');
UPDATE temp_na set outborn_mothers_age = obs_value_numeric_from_temp(encounter_id, 'PIH','3467');
UPDATE temp_na set outborn_mother_is_alive = obs_value_coded_list_from_temp(encounter_id, 'PIH','20363','en');
UPDATE temp_na set outborn_number_of_newborns = obs_value_coded_list_from_temp(encounter_id, 'PIH','20362','en');
UPDATE temp_na set outborn_delivery_type = obs_value_coded_list_from_temp(encounter_id, 'PIH','11663','en');
UPDATE temp_na set outborn_delivery_location = obs_value_coded_list_from_temp(encounter_id, 'PIH','20260','en');
UPDATE temp_na set outborn_method_of_transport = obs_value_coded_list_from_temp(encounter_id, 'PIH','975','en');

UPDATE temp_na set maternal_complications = obs_value_coded_list_from_temp(encounter_id, 'PIH','20542', @locale);

UPDATE temp_na set weight = obs_value_numeric_from_temp(encounter_id, 'PIH','5089');
UPDATE temp_na set muac = obs_value_numeric_from_temp(encounter_id, 'PIH','1290');
UPDATE temp_na set length = obs_value_numeric_from_temp(encounter_id, 'PIH','5090');
UPDATE temp_na set heart_rate = obs_value_numeric_from_temp(encounter_id, 'PIH','5087');
UPDATE temp_na set bp_systolic = obs_value_numeric_from_temp(encounter_id, 'PIH','5085');
UPDATE temp_na set bp_diastolic = obs_value_numeric_from_temp(encounter_id, 'PIH','5086');
UPDATE temp_na set respiratory_rate = obs_value_numeric_from_temp(encounter_id, 'PIH','5242');
UPDATE temp_na set o2_saturation = obs_value_numeric_from_temp(encounter_id, 'PIH','5092');
UPDATE temp_na set temperature = obs_value_numeric_from_temp(encounter_id, 'PIH','5088');
UPDATE temp_na set head_circumference = obs_value_numeric_from_temp(encounter_id, 'PIH','5314');

UPDATE temp_na set hemoglobin = obs_value_numeric_from_temp(encounter_id, 'PIH','21');
UPDATE temp_na set rbg = obs_value_numeric_from_temp(encounter_id, 'PIH','887');
UPDATE temp_na set mrdt = obs_value_coded_list_from_temp(encounter_id, 'PIH','11464','en');
UPDATE temp_na set bilirubin = obs_value_numeric_from_temp(encounter_id, 'PIH','655');

UPDATE temp_na set umbilical_cord = obs_value_coded_list_from_temp(encounter_id, 'PIH','15138','en');
UPDATE temp_na set eyes = obs_value_coded_list_from_temp(encounter_id, 'PIH','11318','en');
UPDATE temp_na set skin_color = obs_value_coded_list_from_temp(encounter_id, 'PIH','1120','en');
UPDATE temp_na set urination = obs_value_coded_list_from_temp(encounter_id, 'PIH','13228','en');
UPDATE temp_na set stool = obs_value_coded_list_from_temp(encounter_id, 'PIH','12329','en');
UPDATE temp_na set neurological = obs_value_coded_list_from_temp(encounter_id, 'PIH','1129','en');
UPDATE temp_na set seizures = obs_value_coded_list_from_temp(encounter_id, 'PIH','206','en');

UPDATE temp_na set feeding_method = obs_value_coded_list_from_temp(encounter_id, 'PIH','10564','en');
UPDATE temp_na set treatment_air = obs_value_coded_list_from_temp(encounter_id, 'PIH','12891','en');
UPDATE temp_na set disposition = obs_value_coded_list_from_temp(encounter_id, 'PIH','8620','en');
UPDATE temp_na set death_date = obs_value_datetime_from_temp(encounter_id, 'PIH','14399');

select 
  concat(@partition, '-', patient_id) as patient_id,
  emr_id,
  concat(@partition, '-', encounter_id) as encounter_id,
  concat(@partition, '-', visit_id) as visit_id,encounter_datetime,
  encounter_location,
  datetime_entered,
  user_entered,
  admitting_clinician,
  admitted_to,
  admission_date,
  condition_at_admission,
  clinical_adverse_effects,
  outborn_mothers_name,
  outborn_mothers_age,
  outborn_mother_is_alive,
  outborn_number_of_newborns,
  outborn_delivery_type,
  outborn_delivery_location,
  outborn_method_of_transport,
  maternal_complications,
  weight,
  muac,
  length,
  head_circumference,
  heart_rate,
  bp_systolic,
  bp_diastolic,
  respiratory_rate,
  o2_saturation,
  temperature,
  hemoglobin,
  rbg,
  mrdt,
  bilirubin,
  umbilical_cord,
  eyes,
  skin_color,
  urination,
  stool,
  neurological,
  seizures,
  feeding_method,
  treatment_air,
  disposition,
  death_date,
  index_asc,
  index_desc
from temp_na;
