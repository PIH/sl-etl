
-- --------- outpatient table 
set @partition = '${partitionNum}';
SELECT patient_identifier_type_id INTO @identifier_type FROM patient_identifier_type pit WHERE uuid ='1a2acce0-7426-11e5-a837-0800200c9a66';
SELECT patient_identifier_type_id INTO @kgh_identifier_type FROM patient_identifier_type pit WHERE uuid ='c09a1d24-7162-11eb-8aa6-0242ac110002';
SELECT patient_identifier_type_id INTO @hiv_identifier_type FROM patient_identifier_type pit WHERE uuid ='139766e8-15f5-102d-96e4-000c29c2a5d7';
SELECT encounter_type_id INTO @OutpatientInit FROM encounter_type where uuid = '7d5853d4-67b7-4742-8492-fcf860690ed5';
SELECT encounter_type_id INTO @OutpatientFollowup FROM encounter_type where uuid = 'd8a038b5-90d2-43dc-b94b-8338b76674f3';


drop temporary table if exists outpatient_encs;
create temporary table outpatient_encs (
patient_id                 int,           
emr_id                     varchar(255),  
encounter_id               int,           
visit_id                   int,          
encounter_datetime         datetime,      
encounter_location         varchar(255),  
datetime_entered           datetime,      
user_entered               varchar(255),  
provider                   varchar(255),  
encounter_type             varchar(255),  
weight_loss                boolean,      
obesity                    boolean,      
jaundice                   boolean,      
depression                 boolean,      
rash                       boolean,      
pallor                     boolean,      
cardiac_murmur             boolean,      
tachycardia                boolean,      
splenomegaly               boolean,      
hepatomegaly               boolean,      
ascites                    boolean,      
abdominal_mass             boolean,      
abdominal_pain             boolean,      
seizure                    boolean,      
hemiplegia                 boolean,      
effusion_of_joint          boolean,      
oedema                     boolean,      
muscle_pain                boolean,      
hiv_counseling             boolean,      
family_planning_counseling boolean,      
disposition                varchar(255), 
disposition_comment        text,         
next_visit_date            date          
);

insert into outpatient_encs(patient_id, encounter_id, visit_id, encounter_datetime,
datetime_entered, user_entered, encounter_type)
select patient_id, encounter_id, visit_id, encounter_datetime, date_created, creator, encounter_type_name_from_id(encounter_type)
from encounter e
where e.voided = 0
AND encounter_type IN (@OutpatientInit, @OutpatientFollowup)
ORDER BY encounter_datetime desc;

create index outpatient_encs_ei on outpatient_encs(encounter_id);

UPDATE outpatient_encs
set user_entered = person_name_of_user(user_entered);

UPDATE outpatient_encs
SET provider = provider(encounter_id);

UPDATE outpatient_encs t
SET emr_id = patient_identifier(patient_id, metadata_uuid('org.openmrs.module.emrapi', 'emr.primaryIdentifierType'));

UPDATE outpatient_encs
SET encounter_location=encounter_location_name(encounter_id);

DROP TEMPORARY TABLE IF EXISTS temp_obs;
create temporary table temp_obs
select o.obs_id, o.voided ,o.obs_group_id , o.encounter_id, o.person_id, o.concept_id, o.value_coded, o.value_numeric,
o.value_text,o.value_datetime, o.comments, o.date_created, o.obs_datetime
from obs o
inner join outpatient_encs t on t.encounter_id = o.encounter_id
where o.voided = 0;

create index temp_obs_encs_ei on temp_obs(encounter_id);

set @weight_loss = concept_from_mapping('PIH','832');
set @obesity = concept_from_mapping('PIH','7507');
set @jaundice = concept_from_mapping('PIH','215');
set @depression = concept_from_mapping('PIH','DEPRESSION');
set @rash = concept_from_mapping('PIH','RASH');
set @pallor = concept_from_mapping('PIH','PALLOR');
set @cardiac_murmur = concept_from_mapping('PIH','562');
set @tachycardia = concept_from_mapping('PIH','TACHYCARDIA');
set @splenomegaly = concept_from_mapping('PIH','SPLENOMEGALY');
set @hepatomegaly = concept_from_mapping('PIH','HEPATOMEGALY');
set @ascites = concept_from_mapping('PIH','ASCITES');
set @abdominal_mass = concept_from_mapping('PIH','5103');
set @abdominal_pain = concept_from_mapping('PIH','151');
set @seizure = concept_from_mapping('PIH','SEIZURE');
set @hemiplegia = concept_from_mapping('PIH','11782');
set @effusion_of_joint = concept_from_mapping('PIH','8401');
set @oedema = concept_from_mapping('PIH','OEDEMA');
set @muscle_pain = concept_from_mapping('PIH','6034');
set @hiv_counseling = concept_from_mapping('PIH','11381');
set @disposition = concept_from_mapping('PIH','8620');
set @family_planning_counseling = concept_from_mapping('PIH','12241');
set @disposition_comment = concept_from_mapping('PIH','10578');
set @next_visit_date = concept_from_mapping('PIH','5096');
set @symptom = concept_from_mapping('PIH','11119');
set @neurologic_exam  = concept_from_mapping('PIH','1129');
set @general_exam  = concept_from_mapping('PIH','1119');
set @mh_exam  = concept_from_mapping('PIH','10470');
set @skin_exam  = concept_from_mapping('PIH','1120');
set @cardiac_exam  = concept_from_mapping('PIH','1124');
set @abdominal_exam  = concept_from_mapping('PIH','1125');
set @musculoskeletal_exam  = concept_from_mapping('PIH','1128');
set @yes = concept_from_mapping('PIH','1065');
set @no = concept_from_mapping('PIH','1066');

drop temporary table if exists temp_obs_collated;
create temporary table temp_obs_collated 
select encounter_id,
max(case when concept_id = @symptom and value_coded = @weight_loss then 1 end) "weight_loss",
max(case when concept_id = @general_exam and value_coded = @obesity then 1 end) "obesity",
max(case when concept_id = @general_exam and value_coded = @jaundice then 1 end) "jaundice",
max(case when concept_id = @mh_exam and value_coded = @depression then 1 end) "depression",
max(case when concept_id = @skin_exam and value_coded = @rash then 1 end) "rash",
max(case when concept_id = @skin_exam and value_coded = @pallor then 1 end) "pallor",
max(case when concept_id = @cardiac_exam and value_coded = @cardiac_murmur then 1 end) "cardiac_murmur",
max(case when concept_id = @cardiac_exam and value_coded = @tachycardia then 1 end) "tachycardia",
max(case when concept_id = @abdominal_exam and value_coded = @splenomegaly then 1 end) "splenomegaly",
max(case when concept_id = @abdominal_exam and value_coded = @hepatomegaly then 1 end) "hepatomegaly",
max(case when concept_id = @abdominal_exam and value_coded = @ascites then 1 end) "ascites",
max(case when concept_id = @abdominal_exam and value_coded = @abdominal_mass then 1 end) "abdominal_mass",
max(case when concept_id = @abdominal_exam and value_coded = @abdominal_pain then 1 end) "abdominal_pain",
max(case when concept_id = @neurologic_exam and value_coded = @seizure then 1 end) "seizure",
max(case when concept_id = @neurologic_exam and value_coded = @hemiplegia then 1 end) "hemiplegia",
max(case when concept_id = @musculoskeletal_exam and value_coded = @effusion_of_joint then 1 end) "effusion_of_joint",
max(case when concept_id = @musculoskeletal_exam and value_coded = @oedema then 1 end) "oedema",
max(case when concept_id = @musculoskeletal_exam and value_coded = @muscle_pain then 1 end) "muscle_pain",
max(case when concept_id = @hiv_counseling and value_coded = @yes then 1 
		 when concept_id = @hiv_counseling and value_coded = @no then 0 end) "hiv_counseling",
max(case when concept_id = @family_planning_counseling and value_coded = @yes then 1 
		 when concept_id = @family_planning_counseling and value_coded = @no then 0 end) "family_planning_counseling",
max(case when concept_id = @disposition_comment then value_text end) "disposition_comment",
max(case when concept_id = @disposition then concept_name(value_coded, @locale) end) "disposition",
max(case when concept_id = @next_visit_date then value_datetime end) "next_visit_date"
from temp_obs
group by encounter_id;

create index temp_obs_collated_ei on temp_obs_collated(encounter_id);

update outpatient_encs t
inner join temp_obs_collated o on o.encounter_id = t.encounter_id
set	t.weight_loss = o.weight_loss,
	t.obesity = o.obesity,
	t.jaundice = o.jaundice,
	t.depression = o.depression,
	t.rash = o.rash,
	t.pallor = o.pallor,
	t.cardiac_murmur = o.cardiac_murmur,
	t.tachycardia = o.tachycardia,
	t.splenomegaly = o.splenomegaly,
	t.hepatomegaly = o.hepatomegaly,
	t.ascites = o.ascites,
	t.abdominal_mass = o.abdominal_mass,
	t.abdominal_pain = o.abdominal_pain,
	t.seizure = o.seizure,
	t.hemiplegia = o.hemiplegia,
	t.effusion_of_joint = o.effusion_of_joint,
	t.oedema = o.oedema,
	t.muscle_pain = o.muscle_pain,
	t.hiv_counseling = o.hiv_counseling,
	t.family_planning_counseling = o.family_planning_counseling,
	t.disposition_comment = o.disposition_comment,
	t.disposition = o.disposition,
	t.next_visit_date = o.next_visit_date;

select 
concat(@partition,"-",patient_id) patient_id,       
emr_id, 
concat(@partition,"-",encounter_id) encounter_id,
concat(@partition,"-",visit_id) visit_id,
encounter_datetime,     
encounter_location, 
datetime_entered,    
user_entered,
provider, 
encounter_type,
weight_loss,
obesity,
jaundice,
depression,
rash,
pallor,
cardiac_murmur,
tachycardia,
splenomegaly,
hepatomegaly,
ascites,
abdominal_mass,
abdominal_pain,
seizure,
hemiplegia,
effusion_of_joint,
oedema,
muscle_pain,
hiv_counseling,
family_planning_counseling,
disposition, 
disposition_comment,
next_visit_date 
from outpatient_encs;
