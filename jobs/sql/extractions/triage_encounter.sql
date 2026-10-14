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
user_entered             varchar(255),
creator                  int(11),
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


-- encounter-level columns that come straight from encounter / person / location / visit
-- are filled by joins here, rather than by one function call per row afterwards.
-- The date filter compares encounter_datetime directly (not date(encounter_datetime)) so it can use an index.
insert into temp_ED_Triage (patient_id, encounter_id, visit_id, encounter_datetime, date_entered, creator,
                            age_at_encounter, encounter_location, ED_Visit_Start_Datetime)
select e.patient_id, e.encounter_id, e.visit_id, e.encounter_datetime, e.date_created, e.creator,
       TIMESTAMPDIFF(YEAR, p.birthdate, e.encounter_datetime),
       l.name,
       v.date_started
from encounter e
left join person p on p.person_id = e.patient_id
left join location l on l.location_id = e.location_id
left join visit v on v.visit_id = e.visit_id
where e.encounter_type = @EDTriageEnc and e.voided = 0
AND ((e.encounter_datetime >= @startDate) or (@startDate is null))
AND ((e.encounter_datetime < date_add(@endDate, interval 1 day)) or (@endDate is null))
;

create index temp_ED_Triage_ei on temp_ED_Triage(encounter_id);
create index temp_ED_Triage_pi on temp_ED_Triage(patient_id);

-- user entered: look up each distinct creator once
DROP TEMPORARY TABLE IF EXISTS temp_ed_users;
CREATE TEMPORARY TABLE temp_ed_users
select distinct creator from temp_ED_Triage;
alter table temp_ed_users add column user_name text;
create index temp_ed_users_c on temp_ed_users(creator);
update temp_ed_users set user_name = person_name_of_user(creator);

update temp_ED_Triage t
inner join temp_ed_users u on u.creator = t.creator
set t.user_entered = u.user_name;

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
set @primary_emr_uuid = metadata_uuid('org.openmrs.module.emrapi', 'emr.primaryIdentifierType');
UPDATE temp_ed_patient SET
    wellbody_emr_id = patient_identifier(patient_id,'1a2acce0-7426-11e5-a837-0800200c9a66'),
    kgh_emr_id = patient_identifier(patient_id,'c09a1d24-7162-11eb-8aa6-0242ac110002'),
    emr_id = patient_identifier(patient_id,@primary_emr_uuid),
    unknown_patient = unknown_patient(patient_id),
    loc_registered = loc_registered(patient_id);  -- patient-level, so computed once per patient

-- gender
UPDATE temp_ed_patient t
inner join person p on p.person_id = t.patient_id and p.voided = 0
SET t.gender = p.gender;

update temp_ED_Triage t
inner join temp_ed_patient p on p.patient_id = t.patient_id
set	t.wellbody_emr_id = p.wellbody_emr_id,
    t.kgh_emr_id = p.kgh_emr_id,
    t.emr_id = p.emr_id,
	t.unknown_patient = p.unknown_patient,
	t.gender = p.gender,
	t.loc_registered = p.loc_registered;

-- Provider
UPDATE temp_ED_Triage SET provider = PROVIDER(encounter_id);

-- only the obs columns used below are copied
DROP TEMPORARY TABLE if exists temp_obs;
CREATE TEMPORARY TABLE temp_obs
select o.encounter_id, o.concept_id, o.value_coded, o.value_numeric, o.value_text
from obs o inner join temp_ED_Triage t on o.encounter_id = t.encounter_id
where o.voided = 0;

create index temp_obs_c2 on temp_obs(encounter_id, concept_id, value_coded);

-- look up each coded answer's name once, instead of calling concept_name() for every obs row
drop temporary table if exists temp_concept_names;
create temporary table temp_concept_names
select distinct value_coded as concept_id from temp_obs where value_coded is not null;
alter table temp_concept_names add column name varchar(255);
create index temp_concept_names_ci on temp_concept_names(concept_id);
update temp_concept_names set name = concept_name(concept_id, @locale);

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
max(case when t.concept_id = @queue_status then cn.name end) "Triage_queue_status",
max(case when t.concept_id = @triage_color then cn.name end) "Triage_Color",
max(case when t.concept_id = @triage_score then value_numeric end) "Triage_Score",
max(case when t.concept_id = @chief_complaint then value_text end) "Chief_Complaint",
max(case when t.concept_id = @weight then value_numeric end) "Weight_KG",
max(case when t.concept_id = @mobility then cn.name end) "Mobility",
max(case when t.concept_id = @rr then value_numeric end) "Respiratory_Rate",
max(case when t.concept_id = @o2 then value_numeric end) "Blood_Oxygen_Saturation",
max(case when t.concept_id = @pulse then value_numeric end) "Pulse",
max(case when t.concept_id = @sbp then value_numeric end) "bp_systolic",
max(case when t.concept_id = @dbp then value_numeric end) "bp_diastolic",
max(case when t.concept_id = @temp then value_numeric end) "Temperature_C",
max(case when t.concept_id = @triage_diagnosis and value_coded = @trauma then cn.name end) "Trauma_Present",
max(case when t.concept_id = @ci then value_text end) "Clinical_Impression",
max(case when t.concept_id = @gv then value_numeric end) "Glucose_Value",
max(case when t.concept_id = @destination then cn.name end) "Referral_Destination",
max(case when t.concept_id = @destination then value_coded end) "destination_concept_id"
from temp_obs t
left join temp_concept_names cn on cn.concept_id = t.value_coded
group by encounter_id;

create index temp_obs_collated_ei on temp_obs_collated(encounter_id);

-- SL-1436: show Referral_Destination with the labels the ED Triage app displays
-- (edtriageapp messages.properties, keyed by answer uuid) instead of the dictionary concept names.
-- Falls back to the concept name for any answer not listed here.
update temp_obs_collated o
inner join concept c on c.concept_id = o.destination_concept_id
set o.Referral_Destination =
    case c.uuid
        when '3cdc871e-26fe-102b-80cb-0017a47871b2' then 'General OPD'
        when '9b812de9-1a80-4bc8-9c8a-861516051811' then 'Pediatric OPD'
        when '868d99fd-f9d6-4367-b238-69f26ee60e26' then 'NCD clinic'
        when '160473AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' then 'Adult ER'
        when '1e7c8432-4158-4e9b-9916-1ea1f94056e1' then 'Pediatric ER'
        when '79b58985-301d-4222-8154-455a0be76015' then 'TB/HIV unit'
        when '9885de8c-6a5a-11e2-b6f9-aa00f871a3e1' then 'Medical ward'
        when '3ce6ae60-26fe-102b-80cb-0017a47871b2' then 'Pediatrics ward'
        when '430751c7-e8e2-4555-be66-ae085de3f5ed' then 'Isolation unit'
        when '3ce1e268-26fe-102b-80cb-0017a47871b2' then 'ANC'
        when '164834AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' then 'Minor theater'
        when '988c3b9c-6a5a-11e2-b6f9-aa00f871a3e1' then 'Surgical ward'
        when '3ce1e6e6-26fe-102b-80cb-0017a47871b2' then 'Maternity/Labor ward'
        when '164164AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' then 'Surgical OPD'
        when '3ced9a68-26fe-102b-80cb-0017a47871b2' then 'Mental health'
        when '623ee5c5-e59c-41e9-b62e-bc13a2c142b6' then 'Eye clinic'
        when 'f2948b7f-deac-4cdd-8968-4fc67ab95e05' then 'Rainbow clinic'
        when '3cee7fb4-26fe-102b-80cb-0017a47871b2' then 'Other'
        else o.Referral_Destination
    end;

-- triage symptoms: each "Triage diagnosis" answer is placed in a column by the symptom set it belongs to.
-- One pass over the obs, instead of one update per symptom set.
drop temporary table if exists temp_symptoms;
create temporary table temp_symptoms
select o.encounter_id,
max(case when cs.concept_set = @response       then cn.name end) "Response",
max(case when cs.concept_set = @emergencySigns then cn.name end) "Emergency_signs",
max(case when cs.concept_set = @shock          then cn.name end) "signs_of_shock",
max(case when cs.concept_set = @dehydration    then cn.name end) "dehydration",
max(case when cs.concept_set = @neuro          then cn.name end) "Neurological",
max(case when cs.concept_set = @burn           then cn.name end) "Burn",
max(case when cs.concept_set = @glucose        then cn.name end) "Glucose",
max(case when cs.concept_set = @tt             then cn.name end) "Trauma_type",
max(case when cs.concept_set = @digestive      then cn.name end) "Digestive",
max(case when cs.concept_set = @pregancy       then cn.name end) "Pregnancy",
max(case when cs.concept_set = @respiratory    then cn.name end) "Respiratory",
max(case when cs.concept_set = @pain           then cn.name end) "Pain",
max(case when cs.concept_set = @other          then cn.name end) "Other_Symptom"
from temp_obs o
inner join temp_concept_names cn on cn.concept_id = o.value_coded
inner join concept_set cs on cs.concept_id = o.value_coded
  and cs.concept_set in (@response, @emergencySigns, @shock, @dehydration, @neuro, @burn, @glucose,
                         @tt, @digestive, @pregancy, @respiratory, @pain, @other)
where o.concept_id = @triage_diagnosis
group by o.encounter_id;

create index temp_symptoms_ei on temp_symptoms(encounter_id);

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
inner join temp_symptoms s on s.encounter_id = t.encounter_id
set t.Response        = s.Response,
    t.Emergency_signs = s.Emergency_signs,
    t.signs_of_shock  = s.signs_of_shock,
    t.dehydration     = s.dehydration,
    t.Neurological    = s.Neurological,
    t.Burn            = s.Burn,
    t.Glucose         = s.Glucose,
    t.Trauma_type     = s.Trauma_type,
    t.Digestive       = s.Digestive,
    t.Pregnancy       = s.Pregnancy,
    t.Respiratory     = s.Respiratory,
    t.Pain            = s.Pain,
    t.Other_Symptom   = s.Other_Symptom;

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
