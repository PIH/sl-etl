CALL initialize_global_metadata();
set @partition = '${partitionNum}';

SELECT encounter_type_id into @EDTriageEnc from encounter_type where uuid = '74cef0a6-2801-11e6-b67b-9e71128cae77';

set @locale = global_property_value('default_locale', 'en');

drop temporary table if exists temp_ED_Triage;
create temporary table temp_ED_Triage
(
patient_id               int(11),        
encounter_id             int(11),      
visit_id                 int(11),
emr_id                   varchar(50),
wellbody_emr_id          varchar(50),
kgh_emr_id               varchar(50), 
loc_registered           varchar(255),   
unknown_patient          varchar(255),   
gender                   varchar(255),	
age_at_encounter         int(3), 
ED_Visit_Start_Datetime  datetime,     
encounter_datetime       datetime,       
encounter_location       text,       
date_entered             date,
user_entered               varchar(255),
provider                 varchar(255), 
Triage_queue_status      varchar(255), 
Triage_Color             varchar(255), 
Triage_Score             int,          
Chief_Complaint          text,         
Weight_KG                double, 
Mobility                 text,         
Respiratory_Rate         double,       
Blood_Oxygen_Saturation  double,       
Pulse                    double,       
bp_systolic  double,       
bp_diastolic double,       
Temperature_C            double, 
Response                 varchar(255),         
Trauma_Present           varchar(255),    
Emergency_signs          varchar(255), 
signs_of_shock           varchar(255),
dehydration              varchar(255),
Neurological             varchar(255),         
Burn                     varchar(255),         
Glucose                  varchar(255),         
Trauma_type              varchar(255),         
Digestive                varchar(255),         
Pregnancy                varchar(255),         
Respiratory              varchar(255),         
Pain                     varchar(255),         
Other_Symptom            varchar(255),         
Clinical_Impression      text,         
Glucose_Value            double,
Referral_Destination     varchar(255),
index_asc                int,
index_desc               int
);

insert into temp_ED_Triage (patient_id, encounter_id, visit_id, encounter_datetime, date_entered, user_entered)
select e.patient_id, e.encounter_id, e.visit_id,e.encounter_datetime, e.date_created , person_name_of_user(e.creator) 
from encounter e
where e.encounter_type = @EDTriageEnc and e.voided = 0
AND ((date(e.encounter_datetime) >=@startDate) or (@startDate is null))
AND ((date(e.encounter_datetime) <=@endDate) or (@endDate is null))
;

-- patient level info
DROP TEMPORARY TABLE IF EXISTS temp_ed_patient;
CREATE TEMPORARY TABLE temp_ed_patient
(
patient_id      int(11), 
emr_id          varchar(50),
wellbody_emr_id varchar(50),
kgh_emr_id      varchar(50),  
loc_registered  varchar(255),  
unknown_patient varchar(255),
gender          varchar(255)
);
   
insert into temp_ed_patient(patient_id)
select distinct patient_id from temp_ED_Triage;

create index temp_ed_patient_pi on temp_ed_patient(patient_id);

-- identifiers
UPDATE temp_ed_patient SET wellbody_emr_id = patient_identifier(patient_id,'1a2acce0-7426-11e5-a837-0800200c9a66');
UPDATE temp_ed_patient SET kgh_emr_id = patient_identifier(patient_id,'c09a1d24-7162-11eb-8aa6-0242ac110002');
set @primary_emr_uuid = metadata_uuid('org.openmrs.module.emrapi', 'emr.primaryIdentifierType');
UPDATE temp_ed_patient SET emr_id=patient_identifier(patient_id,@primary_emr_uuid );

-- unknown patient
UPDATE temp_ed_patient SET unknown_patient = unknown_patient(patient_id);

-- gender
UPDATE temp_ed_patient SET gender = gender(patient_id);

update temp_ED_Triage t
inner join temp_ed_patient p on p.patient_id = t.patient_id
set	t.wellbody_emr_id = p.wellbody_emr_id,
    t.kgh_emr_id = p.kgh_emr_id,
    t.emr_id = p.emr_id,
	t.unknown_patient = p.unknown_patient,
	t.gender = p.gender;

-- age
UPDATE temp_ED_Triage SET age_at_encounter = age_at_enc(patient_id, encounter_id);

-- Provider
UPDATE temp_ED_Triage SET provider = PROVIDER(encounter_id);

-- encounter location
UPDATE temp_ED_Triage SET encounter_location = ENCOUNTER_LOCATION_NAME(encounter_id);

-- location registered
UPDATE temp_ED_Triage SET loc_registered = loc_registered(patient_id);

-- ED Visit Start Datetime
UPDATE temp_ED_Triage t
inner join visit v on t.visit_id = v.visit_id
set t.ED_Visit_Start_Datetime = v.date_started;

DROP TEMPORARY TABLE if exists temp_obs;
CREATE TEMPORARY TABLE temp_obs
select o.obs_id, o.voided, o.obs_group_id, o.encounter_id, o.person_id, o.concept_id, o.value_coded, o.value_numeric, o.value_text, o.value_datetime, o.value_drug, o.comments, o.date_created, o.obs_datetime
from obs o inner join temp_ED_Triage t on o.encounter_id = t.encounter_id
where o.voided = 0;

create index temp_obs_ei on temp_obs(encounter_id);
create index temp_obs_c1 on temp_obs(encounter_id, concept_id);
create index temp_obs_c2 on temp_obs(encounter_id, concept_id, value_coded);

set @queue_status = concept_from_mapping('PIH','Triage queue status');
set @triage_color = concept_from_mapping('PIH','Triage color classification');
set @triage_score = concept_from_mapping('PIH','Triage score');
set @chief_complaint = concept_from_mapping('CIEL','160531');
set @weight = concept_from_mapping('PIH','WEIGHT (KG)');
set @mobility = concept_from_mapping('PIH','Mobility');
set @rr = concept_from_mapping('PIH','RESPIRATORY RATE');
set @o2 = concept_from_mapping('PIH','BLOOD OXYGEN SATURATION');
set @pulse = concept_from_mapping('PIH','PULSE');
set @sbp = concept_from_mapping('PIH','SYSTOLIC BLOOD PRESSURE');
set @dbp = concept_from_mapping('PIH','DIASTOLIC BLOOD PRESSURE');
set @temp = concept_from_mapping('PIH','TEMPERATURE (C)');
set @triage_diagnosis =concept_from_mapping('PIH','Triage diagnosis');
set @response = concept_from_mapping('PIH','Response triage symptom');
set @trauma = concept_from_mapping('PIH','Traumatic Injury');
set @emergencySigns = concept_from_mapping('PIH','Emergency signs');
set @shock = concept_from_mapping('PIH','14701');
set @dehydration = concept_from_mapping('PIH','14702');
set @neuro = concept_from_mapping('PIH','Neurological triage symptom');
set @burn = concept_from_mapping('PIH','Burn triage symptom');
set @glucose = concept_from_mapping('PIH','Glucose triage symptom');
set @tt = concept_from_mapping('PIH','Trauma triage symptom');
set @digestive = concept_from_mapping('PIH','Digestive triage symptom');
set @pregancy = concept_from_mapping('PIH','10721');
set @respiratory = concept_from_mapping('PIH','Respiratory triage symptom');
set @pain = concept_from_mapping('PIH','Pain triage symptom');
set @other = concept_from_mapping('PIH','Other triage symptom');
set @ci = concept_from_mapping('PIH','CLINICAL IMPRESSION COMMENTS');
set @gv = concept_from_mapping('PIH','20660');
set @destination = concept_from_mapping('PIH','14818');

drop temporary table if exists temp_obs_collated;
create temporary table temp_obs_collated 
select 
encounter_id,
max(case when concept_id = @queue_status then concept_name(value_coded, @locale) end) "Triage_queue_status",
max(case when concept_id = @triage_color then concept_name(value_coded, @locale) end) "Triage_Color",
max(case when concept_id = @triage_score then value_numeric end) "Triage_Score",
max(case when concept_id = @chief_complaint then value_text end) "Chief_Complaint",
max(case when concept_id = @weight then value_numeric end) "Weight_KG",
max(case when concept_id = @mobility then concept_name(value_coded, @locale) end) "Mobility",
max(case when concept_id = @rr then value_numeric end) "Respiratory_Rate",
max(case when concept_id = @o2 then value_numeric end) "Blood_Oxygen_Saturation",
max(case when concept_id = @pulse then value_numeric end) "Pulse",
max(case when concept_id = @sbp then value_numeric end) "bp_systolic",
max(case when concept_id = @dbp then value_numeric end) "bp_diastolic",
max(case when concept_id = @temp then value_numeric end) "Temperature_C",
max(case when concept_id = @triage_diagnosis and value_coded = @trauma then concept_name(value_coded, @locale) end) "Trauma_Present",
max(case when concept_id = @ci then value_text end) "Clinical_Impression",
max(case when concept_id = @gv then value_numeric end) "Glucose_Value",
max(case when concept_id = @destination then concept_name(value_coded, @locale) end) "Referral_Destination"
from temp_obs t
group by encounter_id;
 
create index temp_obs_collated_ei on temp_obs_collated(encounter_id);

update temp_ED_Triage t
inner join temp_obs_collated o on o.encounter_id = t.encounter_id
SET t.Triage_queue_status = o.Triage_queue_status,
	t.Triage_Color = o.Triage_Color,
	t.Triage_Score = o.Triage_Score,
	t.Chief_Complaint = o.Chief_Complaint,
	t.Weight_KG = o.Weight_KG,
	t.Mobility = o.Mobility,
	t.Respiratory_Rate = o.Respiratory_Rate,
	t.Blood_Oxygen_Saturation = o.Blood_Oxygen_Saturation,
	t.Pulse = o.Pulse,
	t.bp_systolic = o.bp_systolic,
	t.bp_diastolic = o.bp_diastolic,
	t.Temperature_C = o.Temperature_C,
	t.Trauma_Present = o.Trauma_Present,
	t.Clinical_Impression = o.Clinical_Impression,
	t.Glucose_Value = o.Glucose_Value,
	t.Referral_Destination = o.Referral_Destination;

update temp_ED_Triage t
inner join temp_obs o on o.encounter_id = t.encounter_id and o.voided =0
  and o.concept_id = @triage_diagnosis
inner join concept_set cs on cs.concept_id = o.value_coded and cs.concept_set = @response
set t.Response = concept_name(o.value_coded,@locale);

update temp_ED_Triage t
inner join temp_obs o on o.encounter_id = t.encounter_id and o.voided =0
  and o.concept_id = @triage_diagnosis
inner join concept_set cs on cs.concept_id = o.value_coded and cs.concept_set = @emergencySigns
set t.Emergency_signs = concept_name(o.value_coded,@locale);

update temp_ED_Triage t
inner join temp_obs o on o.encounter_id = t.encounter_id and o.voided =0
  and o.concept_id = @triage_diagnosis
inner join concept_set cs on cs.concept_id = o.value_coded and cs.concept_set = @shock
set t.signs_of_shock = concept_name(o.value_coded,@locale);

update temp_ED_Triage t
inner join temp_obs o on o.encounter_id = t.encounter_id and o.voided =0
  and o.concept_id = @triage_diagnosis
inner join concept_set cs on cs.concept_id = o.value_coded and cs.concept_set = @dehydration
set t.dehydration = concept_name(o.value_coded,@locale);

update temp_ED_Triage t
inner join temp_obs o on o.encounter_id = t.encounter_id and o.voided =0
  and o.concept_id = @triage_diagnosis
inner join concept_set cs on cs.concept_id = o.value_coded and cs.concept_set = @neuro
set t.Neurological = concept_name(o.value_coded,@locale);

update temp_ED_Triage t
inner join temp_obs o on o.encounter_id = t.encounter_id and o.voided =0
  and o.concept_id =@triage_diagnosis
inner join concept_set cs on cs.concept_id = o.value_coded and cs.concept_set = @burn
set t.Burn = concept_name(o.value_coded,@locale);

update temp_ED_Triage t
inner join temp_obs o on o.encounter_id = t.encounter_id and o.voided =0
  and o.concept_id =@triage_diagnosis
inner join concept_set cs on cs.concept_id = o.value_coded and cs.concept_set = @glucose
set t.Glucose = concept_name(o.value_coded,@locale);

update temp_ED_Triage t
inner join temp_obs o on o.encounter_id = t.encounter_id and o.voided =0
  and o.concept_id =@triage_diagnosis
inner join concept_set cs on cs.concept_id = o.value_coded and cs.concept_set = @tt
set t.Trauma_type = concept_name(o.value_coded,@locale);

update temp_ED_Triage t
inner join temp_obs o on o.encounter_id = t.encounter_id and o.voided =0
  and o.concept_id =@triage_diagnosis
inner join concept_set cs on cs.concept_id = o.value_coded and cs.concept_set = @digestive
set t.Digestive = concept_name(o.value_coded,@locale);

update temp_ED_Triage t
inner join temp_obs o on o.encounter_id = t.encounter_id and o.voided =0
  and o.concept_id =@triage_diagnosis
inner join concept_set cs on cs.concept_id = o.value_coded and cs.concept_set = @pregancy
set t.Pregnancy = concept_name(o.value_coded,@locale);

update temp_ED_Triage t
inner join temp_obs o on o.encounter_id = t.encounter_id and o.voided =0
  and o.concept_id = @triage_diagnosis
inner join concept_set cs on cs.concept_id = o.value_coded and cs.concept_set =@respiratory 
set t.Respiratory = concept_name(o.value_coded,@locale);

update temp_ED_Triage t
inner join temp_obs o on o.encounter_id = t.encounter_id and o.voided =0
  and o.concept_id =@triage_diagnosis
inner join concept_set cs on cs.concept_id = o.value_coded and cs.concept_set = @pain
set t.Pain = concept_name(o.value_coded,@locale);

update temp_ED_Triage t
inner join temp_obs o on o.encounter_id = t.encounter_id and o.voided =0
  and o.concept_id =@triage_diagnosis
inner join concept_set cs on cs.concept_id = o.value_coded and cs.concept_set = @other
set t.Other_Symptom = concept_name(o.value_coded,@locale);

-- final output of data
Select
if(@partition REGEXP '^[0-9]+$' = 1,concat(@partition,'-',patient_id),patient_id) "patient_id",
emr_id,
wellbody_emr_id,
kgh_emr_id,
if(@partition REGEXP '^[0-9]+$' = 1,concat(@partition,'-',encounter_id),encounter_id) "encounter_id",
if(@partition REGEXP '^[0-9]+$' = 1,concat(@partition,'-',visit_id),visit_id) "visit_id",
loc_registered,
unknown_patient,
gender,
age_at_encounter,
ED_Visit_Start_Datetime,
encounter_datetime,
encounter_location,
provider,
date_entered,
user_entered,
Triage_queue_status,
Triage_Color,
Triage_Score,
Chief_Complaint,
Weight_KG,
Emergency_signs,
Mobility,
Respiratory_Rate,
Blood_Oxygen_Saturation,
Pulse,
bp_systolic,
bp_diastolic,
Temperature_C,
Response,
Trauma_Present,
signs_of_shock,
dehydration,
Neurological,
Burn,
Glucose,
Trauma_type,
Digestive,
Pregnancy,
Respiratory,
Pain,
Other_Symptom,
Clinical_Impression,
Glucose_Value,
Referral_Destination,
index_asc,
index_desc
from temp_ED_Triage;
