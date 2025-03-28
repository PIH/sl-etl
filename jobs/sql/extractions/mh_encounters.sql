-- set @startDate='2021-01-01';
-- set @endDate='2023-05-22';
set @partition = '${partitionNum}';
set @locale = global_property_value('default_locale', 'en');
select encounter_type_id into @mhIntake from encounter_type where uuid = 'a8584ab8-cc2a-11e5-9956-625662870761';
select encounter_type_id into @mhFollowup from encounter_type where uuid = '9d701a81-bb83-40ea-9efc-af50f05575f2';
set @mhProgramId = program('Mental Health'); 

drop temporary table if exists temp_mh;
create temporary table temp_mh
(
    patient_id int,
    emr_id varchar(50),
    location_registered varchar(255),
    age_at_encounter int,
    address varchar(1000),
    encounter_id int,
    encounter_type varchar(255),
    visit_id int,
    mh_program_id int,
    encounter_datetime datetime,
    provider varchar(255),
    referred_by_community varchar(255),
    other_community_referral text, 
    referred_by_facility varchar(255),
    other_facility_referral text,
    history_of_homelessness varchar(100),
    housing_type varchar(100), 
    hiv_test varchar(255),
    ARV_start_date datetime,
    TB_smear_result varchar(255),
    extrapulmonary_tuberculosis varchar(255),
    alcohol_history varchar(255),
    alcohol_duration double,
    marijuana_history varchar(255),
    marijuana_duration double,
    kush_history varchar(255),
    kush_duration double,
    tramadol_history varchar(255),
    tramadol_duration double,    
    other_drug_history varchar(255),
    other_drug_duration double,
    other_drug_name varchar(255),
    traditional_medicine_history varchar(255),
    family_epilepsy varchar(255),
    family_mental_illness varchar(255),
    family_behavioral_problems varchar(255),
    presenting_features varchar(1000),
    other_presenting_features text,
    clinical_impressions text,
    mental_state_exam_findings varchar(1000),
    other_mental_state_exam_finding text,
    past_suicidal_ideation varchar(255),
    past_suicidal_attempt varchar(255),
    current_suicidal_ideation varchar(255),
    current_suicidal_attempt varchar(255),
    date_latest_suicidal_attempt datetime,
    psychosocial_counseling varchar(255),
    interventions varchar(255),
    diagnosis_1 varchar(255),
    diagnosis_2 varchar(255), 
    diagnosis_3 varchar(255),
    diagnosis_4 varchar(255),
    noncoded_diagnosis varchar(255),
    seizure_frequency double,
    CGI_S double,
    CGI_I double,
    CGI_E double,
    chlorpromazine_hydrochloride_tab_dose double,
    chlorpromazine_hydrochloride_tab_dose_units varchar(50),
    chlorpromazine_hydrochloride_tab_freq varchar(50),
    chlorpromazine_hydrochloride_tab_duration double,
    chlorpromazine_hydrochloride_tab_dur_units varchar(50),
    chlorpromazine_hydrochloride_tab_route varchar(50),
    chlorpromazine_hydrochloride_sol_dose double,
    chlorpromazine_hydrochloride_sol_dose_units varchar(50),
    chlorpromazine_hydrochloride_sol_freq varchar(50),
    chlorpromazine_hydrochloride_sol_duration double,
    chlorpromazine_hydrochloride_sol_dur_units varchar(50),
    chlorpromazine_hydrochloride_sol_route varchar(50),
    haloperidol_oily_sol_dose double,
    haloperidol_oily_sol_dose_units varchar(50),
    haloperidol_oily_sol_freq varchar(50),
    haloperidol_oily_sol_duration double,
    haloperidol_oily_sol_dur_units varchar(50),
    haloperidol_oily_sol_route varchar(50),
    haloperidol_tab_dose double,
    haloperidol_tab_dose_units varchar(50),
    haloperidol_tab_freq varchar(50),
    haloperidol_tab_duration double,
    haloperidol_tab_dur_units varchar(50),
    haloperidol_tab_route varchar(50),
    haloperidol_sol_dose double,
    haloperidol_sol_dose_units varchar(50),
    haloperidol_sol_freq varchar(50),
    haloperidol_sol_duration double,
    haloperidol_sol_dur_units varchar(50),
    haloperidol_sol_route varchar(50),
    fluphenazine_oily_sol_dose double,
    fluphenazine_oily_sol_dose_units varchar(50),
    fluphenazine_oily_sol_freq varchar(50),
    fluphenazine_oily_sol_duration double,
    fluphenazine_oily_sol_dur_units varchar(50),
    fluphenazine_oily_sol_route varchar(50),
    carbamazepine_tab_dose double,
    carbamazepine_tab_dose_units varchar(50),
    carbamazepine_tab_freq varchar(50),
    carbamazepine_tab_duration double,
    carbamazepine_tab_dur_units varchar(50),
    carbamazepine_tab_route varchar(50),
    sodium_valproate_tab_dose double,
    sodium_valproate_tab_dose_units varchar(50),
    sodium_valproate_tab_freq varchar(50),
    sodium_valproate_tab_duration double,
    sodium_valproate_tab_dur_units varchar(50),
    sodium_valproate_tab_route varchar(50),   
    sodium_valproate_sol_dose double,
    sodium_valproate_sol_dose_units varchar(50),
    sodium_valproate_sol_freq varchar(50),
    sodium_valproate_sol_duration double,
    sodium_valproate_sol_dur_units varchar(50),
    sodium_valproate_sol_route varchar(50),
    risperidone_tab_dose double,
    risperidone_tab_dose_units varchar(50),
    risperidone_tab_freq varchar(50),
    risperidone_tab_duration double,
    risperidone_tab_dur_units varchar(50),
    risperidone_tab_route varchar(50),
    fluoxetine_hydrochloride_tab_dose double,
    fluoxetine_hydrochloride_tab_dose_units varchar(50),
    fluoxetine_hydrochloride_tab_freq varchar(50),
    fluoxetine_hydrochloride_tab_duration double,
    fluoxetine_hydrochloride_tab_dur_units varchar(50),
    fluoxetine_hydrochloride_tab_route varchar(50),  
    olanzapine_5mg_tab_dose double,
    olanzapine_5mg_tab_dose_units varchar(50),
    olanzapine_5mg_tab_freq varchar(50),
    olanzapine_5mg_tab_duration double,
    olanzapine_5mg_tab_dur_units varchar(50),
    olanzapine_5mg_tab_route varchar(50),
    olanzapine_10mg_tab_dose double,
    olanzapine_10mg_tab_dose_units varchar(50),
    olanzapine_10mg_tab_freq varchar(50),
    olanzapine_10mg_tab_duration double,
    olanzapine_10mg_tab_dur_units varchar(50),
    olanzapine_10mg_tab_route varchar(50),
    diphenhydramine_hydrochloride_tab_dose double,
    diphenhydramine_hydrochloride_tab_dose_units varchar(50),
    diphenhydramine_hydrochloride_tab_freq varchar(50),
    diphenhydramine_hydrochloride_tab_duration double,
    diphenhydramine_hydrochloride_tab_dur_units varchar(50),
    diphenhydramine_hydrochloride_tab_route varchar(50),
    diphenhydramine_hydrochloride_sol_dose double,
    diphenhydramine_hydrochloride_sol_dose_units varchar(50),
    diphenhydramine_hydrochloride_sol_freq varchar(50),
    diphenhydramine_hydrochloride_sol_duration double,
    diphenhydramine_hydrochloride_sol_dur_units varchar(50),
    diphenhydramine_hydrochloride_sol_route varchar(50),   
    phenobarbital_30mg_tab_dose double,
    phenobarbital_30mg_tab_dose_units varchar(50),
    phenobarbital_30mg_tab_freq varchar(50),
    phenobarbital_30mg_tab_duration double,
    phenobarbital_30mg_tab_dur_units varchar(50),
    phenobarbital_30mg_tab_route varchar(50),
    phenobarbital_50mg_tab_dose double,
    phenobarbital_50mg_tab_dose_units varchar(50),
    phenobarbital_50mg_tab_freq varchar(50),
    phenobarbital_50mg_tab_duration double,
    phenobarbital_50mg_tab_dur_units varchar(50),
    phenobarbital_50mg_tab_route varchar(50),
    phenobarbital_sol_dose double,
    phenobarbital_sol_dose_units varchar(50),
    phenobarbital_sol_freq varchar(50),
    phenobarbital_sol_duration double,
    phenobarbital_sol_dur_units varchar(50),
    phenobarbital_sol_route varchar(50),   
    phenytoin_sodium_tab_dose double,
    phenytoin_sodium_tab_dose_units varchar(50),
    phenytoin_sodium_tab_freq varchar(50),
    phenytoin_sodium_tab_duration double,
    phenytoin_sodium_tab_dur_units varchar(50),
    phenytoin_sodium_tab_route varchar(50),
    phenytoin_sodium_sol_dose double,
    phenytoin_sodium_sol_dose_units varchar(50),
    phenytoin_sodium_sol_freq varchar(50),
    phenytoin_sodium_sol_duration double,
    phenytoin_sodium_sol_dur_units varchar(50),
    phenytoin_sodium_sol_route varchar(50),
    amitriptyline_hydrochloride_tab_dose double,
    amitriptyline_hydrochloride_tab_dose_units varchar(50),
    amitriptyline_hydrochloride_tab_freq varchar(50),
    amitriptyline_hydrochloride_tab_duration double,
    amitriptyline_hydrochloride_tab_dur_units varchar(50),
    amitriptyline_hydrochloride_tab_route varchar(50),  
    diazepam_tab_dose double,
    diazepam_tab_dose_units varchar(50),
    diazepam_tab_freq varchar(50),
    diazepam_tab_duration double,
    diazepam_tab_dur_units varchar(50),
    diazepam_tab_route varchar(50),
    diazepam_sol_dose double,
    diazepam_sol_dose_units varchar(50),
    diazepam_sol_freq varchar(50),
    diazepam_sol_duration double,
    diazepam_sol_dur_units varchar(50),
    diazepam_sol_route varchar(50),
    trihexyphenidyl_tab_dose double,
    trihexyphenidyl_tab_dose_units varchar(50),
    trihexyphenidyl_tab_freq varchar(50),
    trihexyphenidyl_tab_duration double,
    trihexyphenidyl_tab_dur_units varchar(50),
    trihexyphenidyl_tab_route varchar(50),  
    mirtazapine_15mg_tab_dose double,
    mirtazapine_15mg_tab_dose_units varchar(50),
    mirtazapine_15mg_tab_freq varchar(50),
    mirtazapine_15mg_tab_duration double,
    mirtazapine_15mg_tab_dur_units varchar(50),
    mirtazapine_15mg_tab_route varchar(50),
    mirtazapine_30mg_tab_dose double,
    mirtazapine_30mg_tab_dose_units varchar(50),
    mirtazapine_30mg_tab_freq varchar(50),
    mirtazapine_30mg_tab_duration double,
    mirtazapine_30mg_tab_dur_units varchar(50),
    mirtazapine_30mg_tab_route varchar(50),
    quetiapine_fumarate_tab_dose double,
    quetiapine_fumarate_tab_dose_units varchar(50),
    quetiapine_fumarate_tab_freq varchar(50),
    quetiapine_fumarate_tab_duration double,
    quetiapine_fumarate_tab_dur_units varchar(50),
    quetiapine_fumarate_tab_route varchar(50),
    additional_medication_comments text,
    assigned_chw varchar(50),
    return_visit_date datetime
    );  

-- load temporary table with all mh encounters within the date range 
insert into temp_mh (
    patient_id,
    encounter_id,
    encounter_datetime,
    encounter_type,
    visit_id
)
select
    e.patient_id,
    e.encounter_id,
    e.encounter_datetime,
    encounter_type_name_from_id(e.encounter_type), 
    e.visit_id
from
    encounter e
where e.encounter_type in (@mhIntake, @mhFollowup);

create index temp_mh_patient on temp_mh(patient_id);
create index temp_mh_encounter_id on temp_mh(encounter_datetime);

-- demographics
update temp_mh set emr_id = patient_identifier(patient_id, metadata_uuid('org.openmrs.module.emrapi', 'emr.primaryIdentifierType'));
update temp_mh set location_registered = loc_registered(patient_id);
update temp_mh set age_at_encounter = age_at_enc(patient_id, encounter_id);
update temp_mh set address = person_address(patient_id);

update temp_mh set provider = provider(encounter_id);

update temp_mh
set mh_program_id = patient_program_id_from_encounter(patient_id, @mhProgramId, encounter_id);
-- referrals

update temp_mh set referred_by_community = obs_value_coded_list(encounter_id, 'PIH','Role of referring person',@locale);
update temp_mh set other_community_referral = obs_comments(encounter_id, 'PIH','Role of referring person', 'PIH','OTHER');
update temp_mh set referred_by_facility = obs_value_coded_list(encounter_id, 'PIH','10635',@locale);
update temp_mh set other_facility_referral = obs_comments(encounter_id, 'PIH','10635', 'PIH','OTHER');

-- patient History

update temp_mh set hiv_test = obs_value_coded_list(encounter_id, 'PIH','1040',@locale);
update temp_mh set ARV_start_date = obs_value_datetime(encounter_id, 'PIH','2516');
update temp_mh set TB_smear_result = obs_value_coded_list(encounter_id, 'PIH','3052',@locale);
update temp_mh set extrapulmonary_tuberculosis = obs_value_coded_list(encounter_id, 'PIH','1547',@locale);

update temp_mh set alcohol_history = obs_value_coded_list(encounter_id, 'PIH','1552',@locale);
update temp_mh set alcohol_duration = obs_value_numeric(encounter_id, 'PIH','2241');
update temp_mh set marijuana_history = obs_value_coded_list(encounter_id, 'PIH','12391',@locale);
update temp_mh set marijuana_duration = obs_value_numeric(encounter_id, 'PIH','13239');
update temp_mh set kush_history = obs_value_coded_list(encounter_id, 'PIH','20106',@locale);
update temp_mh set kush_duration = obs_value_numeric(encounter_id, 'PIH','20109');
update temp_mh set tramadol_history = obs_value_coded_list(encounter_id, 'PIH','20107',@locale);
update temp_mh set tramadol_duration = obs_value_numeric(encounter_id, 'PIH','20110');
update temp_mh set other_drug_history = obs_value_coded_list(encounter_id, 'PIH','2546',@locale);
update temp_mh set other_drug_duration = obs_value_numeric(encounter_id, 'PIH','12997');
update temp_mh set other_drug_name = obs_value_text(encounter_id, 'PIH','6489');
update temp_mh set traditional_medicine_history = obs_value_coded_list(encounter_id, 'PIH','13242',@locale);

-- homeless
 update temp_mh set history_of_homelessness = obs_value_coded_list(encounter_id, 'PIH','14697',@locale);
 update temp_mh set housing_type = obs_value_coded_list(encounter_id, 'CIEL', 163577, @locale);

-- family history
update temp_mh set family_epilepsy = obs_value_coded_list(encounter_id, 'CIEL','152450',@locale);
update temp_mh set family_mental_illness = obs_value_coded_list(encounter_id, 'CIEL','140526',@locale);
update temp_mh set family_behavioral_problems = obs_value_coded_list(encounter_id, 'CIEL','152465',@locale);

-- presenting features
update temp_mh set presenting_features = obs_value_coded_list(encounter_id, 'PIH','11505',@locale);
update temp_mh set other_presenting_features = obs_comments(encounter_id, 'PIH','11505', 'PIH','OTHER');

-- clinical impressions
update temp_mh set clinical_impressions = obs_value_text(encounter_id, 'PIH','1364');

-- mental state exam
update temp_mh set mental_state_exam_findings = obs_value_coded_list(encounter_id, 'CIEL','163043',@locale);

-- other mental state finding
update temp_mh set other_mental_state_exam_finding = obs_comments(encounter_id, 'CIEL','163043', 'PIH','OTHER'); 

-- suicidal evaluation
update temp_mh set past_suicidal_ideation = obs_value_coded_list(encounter_id, 'CIEL','165529',@locale);
update temp_mh set past_suicidal_attempt = obs_value_coded_list(encounter_id, 'CIEL','129176',@locale);
update temp_mh set current_suicidal_ideation = obs_value_coded_list(encounter_id, 'CIEL','125562',@locale);
update temp_mh set current_suicidal_attempt = obs_value_coded_list(encounter_id, 'CIEL','148143',@locale);
update temp_mh set date_latest_suicidal_attempt = obs_value_datetime(encounter_id, 'CIEL','165530');
update temp_mh set psychosocial_counseling = obs_value_coded_list(encounter_id, 'PIH','5490',@locale);

-- interventions
update temp_mh set interventions = obs_value_coded_list(encounter_id, 'PIH', 'Mental health intervention', @locale);

-- diagnoses

update temp_mh t
  inner join obs o on o.obs_id = 
  	(select obs_id from obs o2 where o2.encounter_id = t.encounter_id and o2.voided = 0 and o2.concept_id = concept_from_mapping('PIH','10594') 
     and concept_in_set(o2.value_coded ,concept_from_mapping('PIH','HUM Psychological diagnosis'))
	 order by o2.obs_id limit 1 offset 0)	
set diagnosis_1 = concept_name(o.value_coded, @locale);	

update temp_mh t
  inner join obs o on o.obs_id = 
  	(select obs_id from obs o2 where o2.encounter_id = t.encounter_id and o2.voided = 0 and o2.concept_id = concept_from_mapping('PIH','10594') 
     and concept_in_set(o2.value_coded ,concept_from_mapping('PIH','HUM Psychological diagnosis'))
	 order by o2.obs_id limit 1 offset 1)	
set diagnosis_2 = concept_name(o.value_coded, @locale);	

update temp_mh t
  inner join obs o on o.obs_id = 
  	(select obs_id from obs o2 where o2.encounter_id = t.encounter_id and o2.encounter_id = t.encounter_id and o2.voided = 0 and o2.concept_id = concept_from_mapping('PIH','10594') 
     and concept_in_set(o2.value_coded ,concept_from_mapping('PIH','HUM Psychological diagnosis'))
	 order by o2.obs_id limit 1 offset 2)	
set diagnosis_3 = concept_name(o.value_coded, @locale);	

update temp_mh t
  inner join obs o on o.obs_id = 
  	(select obs_id from obs o2 where o2.encounter_id = t.encounter_id and o2.voided = 0 and o2.concept_id = concept_from_mapping('PIH','10594') 
     and concept_in_set(o2.value_coded ,concept_from_mapping('PIH','HUM Psychological diagnosis'))
	 order by o2.obs_id limit 1 offset 3)	
set diagnosis_4 = concept_name(o.value_coded, @locale);	

update temp_mh t
  inner join obs o on o.obs_id = 
  	(select obs_id from obs o2 where o2.encounter_id = t.encounter_id and o2.voided = 0 and o2.concept_id = concept_from_mapping('PIH','10594') 
     and o2.value_coded = concept_from_mapping('PIH','OTHER')
	 limit 1)	
set noncoded_diagnosis = o.comments ;	

-- improvement

update temp_mh set seizure_frequency = obs_value_numeric(encounter_id, 'PIH','6797');
update temp_mh set CGI_S = obs_value_numeric(encounter_id, 'PIH','Mental Health CGI-S');
update temp_mh set CGI_I = obs_value_numeric(encounter_id, 'PIH','Mental Health CGI-S');
update temp_mh set CGI_E = obs_value_numeric(encounter_id, 'CIEL','163224');

-- medication
set @drug_id = drugId('6a2a96d1-c01f-48d3-b3b9-2741bce4e064');
update temp_mh set chlorpromazine_hydrochloride_tab_dose = obs_from_group_id_value_numeric(obs_group_id_with_drug_answer(encounter_id,@drug_id),'CIEL','160856');
update temp_mh set chlorpromazine_hydrochloride_tab_dose_units = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','10744',@locale);
update temp_mh set chlorpromazine_hydrochloride_tab_freq = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','9363',@locale);
update temp_mh set chlorpromazine_hydrochloride_tab_duration = obs_from_group_id_value_numeric(obs_group_id_with_drug_answer(encounter_id,@drug_id),'CIEL','159368');
update temp_mh set chlorpromazine_hydrochloride_tab_dur_units = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','6412',@locale);
update temp_mh set chlorpromazine_hydrochloride_tab_route = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','12651',@locale);

set @drug_id = drugId('526d37fd-d378-441d-8af4-423a46447cbc');
update temp_mh set chlorpromazine_hydrochloride_sol_dose = obs_from_group_id_value_numeric(obs_group_id_with_drug_answer(encounter_id,@drug_id),'CIEL','160856');
update temp_mh set chlorpromazine_hydrochloride_sol_dose_units = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','10744',@locale);
update temp_mh set chlorpromazine_hydrochloride_sol_freq = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','9363',@locale);
update temp_mh set chlorpromazine_hydrochloride_sol_duration = obs_from_group_id_value_numeric(obs_group_id_with_drug_answer(encounter_id,@drug_id),'CIEL','159368');
update temp_mh set chlorpromazine_hydrochloride_sol_dur_units = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','6412',@locale);
update temp_mh set chlorpromazine_hydrochloride_sol_route = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','12651',@locale);

set @drug_id = drugId('671d7b24-6266-4af5-a998-4997f2cd6d48');
update temp_mh set haloperidol_oily_sol_dose = obs_from_group_id_value_numeric(obs_group_id_with_drug_answer(encounter_id,@drug_id),'CIEL','160856');
update temp_mh set haloperidol_oily_sol_dose_units = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','10744',@locale);
update temp_mh set haloperidol_oily_sol_freq = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','9363',@locale);
update temp_mh set haloperidol_oily_sol_duration = obs_from_group_id_value_numeric(obs_group_id_with_drug_answer(encounter_id,@drug_id),'CIEL','159368');
update temp_mh set haloperidol_oily_sol_dur_units = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','6412',@locale);
update temp_mh set haloperidol_oily_sol_route = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','12651',@locale);

set @drug_id = drugId('23f2d94b-3072-4e86-b737-d5ccded81bc0');
update temp_mh set haloperidol_tab_dose = obs_from_group_id_value_numeric(obs_group_id_with_drug_answer(encounter_id,@drug_id),'CIEL','160856');
update temp_mh set haloperidol_tab_dose_units = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','10744',@locale);
update temp_mh set haloperidol_tab_freq = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','9363',@locale);
update temp_mh set haloperidol_tab_duration = obs_from_group_id_value_numeric(obs_group_id_with_drug_answer(encounter_id,@drug_id),'CIEL','159368');
update temp_mh set haloperidol_tab_dur_units = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','6412',@locale);
update temp_mh set haloperidol_tab_route = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','12651',@locale);

set @drug_id = drugId('a8541367-1eb0-4144-9cc7-41a909902d5d');
update temp_mh set haloperidol_sol_dose = obs_from_group_id_value_numeric(obs_group_id_with_drug_answer(encounter_id,@drug_id),'CIEL','160856');
update temp_mh set haloperidol_sol_dose_units = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','10744',@locale);
update temp_mh set haloperidol_sol_freq = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','9363',@locale);
update temp_mh set haloperidol_sol_duration = obs_from_group_id_value_numeric(obs_group_id_with_drug_answer(encounter_id,@drug_id),'CIEL','159368');
update temp_mh set haloperidol_sol_dur_units = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','6412',@locale);
update temp_mh set haloperidol_sol_route = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','12651',@locale);

set @drug_id = drugId('fd58488b-b6ee-4a73-bf77-ab1eb44ec0b7');
update temp_mh set fluphenazine_oily_sol_dose = obs_from_group_id_value_numeric(obs_group_id_with_drug_answer(encounter_id,@drug_id),'CIEL','160856');
update temp_mh set fluphenazine_oily_sol_dose_units = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','10744',@locale);
update temp_mh set fluphenazine_oily_sol_freq = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','9363',@locale);
update temp_mh set fluphenazine_oily_sol_duration = obs_from_group_id_value_numeric(obs_group_id_with_drug_answer(encounter_id,@drug_id),'CIEL','159368');
update temp_mh set fluphenazine_oily_sol_dur_units = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','6412',@locale);
update temp_mh set fluphenazine_oily_sol_route = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','12651',@locale);

set @drug_id = drugId('e371d811-d32c-4f6e-8493-2fa667b7b44c');
update temp_mh set carbamazepine_tab_dose = obs_from_group_id_value_numeric(obs_group_id_with_drug_answer(encounter_id,@drug_id),'CIEL','160856');
update temp_mh set carbamazepine_tab_dose_units = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','10744',@locale);
update temp_mh set carbamazepine_tab_freq = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','9363',@locale);
update temp_mh set carbamazepine_tab_duration = obs_from_group_id_value_numeric(obs_group_id_with_drug_answer(encounter_id,@drug_id),'CIEL','159368');
update temp_mh set carbamazepine_tab_dur_units = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','6412',@locale);
update temp_mh set carbamazepine_tab_route = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','12651',@locale);

set @drug_id = drugId('09b9f018-6aa5-4bcf-9292-d74e07707591');
update temp_mh set sodium_valproate_tab_dose = obs_from_group_id_value_numeric(obs_group_id_with_drug_answer(encounter_id,@drug_id),'CIEL','160856');
update temp_mh set sodium_valproate_tab_dose_units = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','10744',@locale);
update temp_mh set sodium_valproate_tab_freq = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','9363',@locale);
update temp_mh set sodium_valproate_tab_duration = obs_from_group_id_value_numeric(obs_group_id_with_drug_answer(encounter_id,@drug_id),'CIEL','159368');
update temp_mh set sodium_valproate_tab_dur_units = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','6412',@locale);
update temp_mh set sodium_valproate_tab_route = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','12651',@locale);

set @drug_id = drugId('355b9a8a-6e4e-4db8-a2cd-64f61456ef53');
update temp_mh set sodium_valproate_sol_dose = obs_from_group_id_value_numeric(obs_group_id_with_drug_answer(encounter_id,@drug_id),'CIEL','160856');
update temp_mh set sodium_valproate_sol_dose_units = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','10744',@locale);
update temp_mh set sodium_valproate_sol_freq = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','9363',@locale);
update temp_mh set sodium_valproate_sol_duration = obs_from_group_id_value_numeric(obs_group_id_with_drug_answer(encounter_id,@drug_id),'CIEL','159368');
update temp_mh set sodium_valproate_sol_dur_units = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','6412',@locale);
update temp_mh set sodium_valproate_sol_route = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','12651',@locale);

set @drug_id = drugId('bb5094d6-efdd-458e-ab4e-f9916cd904ab');
update temp_mh set risperidone_tab_dose = obs_from_group_id_value_numeric(obs_group_id_with_drug_answer(encounter_id,@drug_id),'CIEL','160856');
update temp_mh set risperidone_tab_dose_units = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','10744',@locale);
update temp_mh set risperidone_tab_freq = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','9363',@locale);
update temp_mh set risperidone_tab_duration = obs_from_group_id_value_numeric(obs_group_id_with_drug_answer(encounter_id,@drug_id),'CIEL','159368');
update temp_mh set risperidone_tab_dur_units = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','6412',@locale);
update temp_mh set risperidone_tab_route = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','12651',@locale);

set @drug_id = drugId('7f7178bd-a1f8-44dd-85a9-02e49065e56b');
update temp_mh set fluoxetine_hydrochloride_tab_dose = obs_from_group_id_value_numeric(obs_group_id_with_drug_answer(encounter_id,@drug_id),'CIEL','160856');
update temp_mh set fluoxetine_hydrochloride_tab_dose_units = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','10744',@locale);
update temp_mh set fluoxetine_hydrochloride_tab_freq = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','9363',@locale);
update temp_mh set fluoxetine_hydrochloride_tab_duration = obs_from_group_id_value_numeric(obs_group_id_with_drug_answer(encounter_id,@drug_id),'CIEL','159368');
update temp_mh set fluoxetine_hydrochloride_tab_dur_units = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','6412',@locale);
update temp_mh set fluoxetine_hydrochloride_tab_route = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','12651',@locale);

set @drug_id = drugId('9c9f85ed-945a-4701-9c4e-1548023e68de');
update temp_mh set olanzapine_5mg_tab_dose = obs_from_group_id_value_numeric(obs_group_id_with_drug_answer(encounter_id,@drug_id),'CIEL','160856');
update temp_mh set olanzapine_5mg_tab_dose_units = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','10744',@locale);
update temp_mh set olanzapine_5mg_tab_freq = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','9363',@locale);
update temp_mh set olanzapine_5mg_tab_duration = obs_from_group_id_value_numeric(obs_group_id_with_drug_answer(encounter_id,@drug_id),'CIEL','159368');
update temp_mh set olanzapine_5mg_tab_dur_units = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','6412',@locale);
update temp_mh set olanzapine_5mg_tab_route = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','12651',@locale);

set @drug_id = drugId('6192369d-c0fe-4d11-86b9-7765940ae73d');
update temp_mh set olanzapine_10mg_tab_dose = obs_from_group_id_value_numeric(obs_group_id_with_drug_answer(encounter_id,@drug_id),'CIEL','160856');
update temp_mh set olanzapine_10mg_tab_dose_units = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','10744',@locale);
update temp_mh set olanzapine_10mg_tab_freq = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','9363',@locale);
update temp_mh set olanzapine_10mg_tab_duration = obs_from_group_id_value_numeric(obs_group_id_with_drug_answer(encounter_id,@drug_id),'CIEL','159368');
update temp_mh set olanzapine_10mg_tab_dur_units = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','6412',@locale);
update temp_mh set olanzapine_10mg_tab_route = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','12651',@locale);

set @drug_id = drugId('81694757-3336-4195-ac6b-ea574b9b8597');
update temp_mh set diphenhydramine_hydrochloride_tab_dose = obs_from_group_id_value_numeric(obs_group_id_with_drug_answer(encounter_id,@drug_id),'CIEL','160856');
update temp_mh set diphenhydramine_hydrochloride_tab_dose_units = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','10744',@locale);
update temp_mh set diphenhydramine_hydrochloride_tab_freq = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','9363',@locale);
update temp_mh set diphenhydramine_hydrochloride_tab_duration = obs_from_group_id_value_numeric(obs_group_id_with_drug_answer(encounter_id,@drug_id),'CIEL','159368');
update temp_mh set diphenhydramine_hydrochloride_tab_dur_units = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','6412',@locale);
update temp_mh set diphenhydramine_hydrochloride_tab_route = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','12651',@locale);

set @drug_id = drugId('b476d417-800f-4e2e-89ec-09de8fd07607');
update temp_mh set diphenhydramine_hydrochloride_sol_dose = obs_from_group_id_value_numeric(obs_group_id_with_drug_answer(encounter_id,@drug_id),'CIEL','160856');
update temp_mh set diphenhydramine_hydrochloride_sol_dose_units = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','10744',@locale);
update temp_mh set diphenhydramine_hydrochloride_sol_freq = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','9363',@locale);
update temp_mh set diphenhydramine_hydrochloride_sol_duration = obs_from_group_id_value_numeric(obs_group_id_with_drug_answer(encounter_id,@drug_id),'CIEL','159368');
update temp_mh set diphenhydramine_hydrochloride_sol_dur_units = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','6412',@locale);
update temp_mh set diphenhydramine_hydrochloride_sol_route = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','12651',@locale);

set @drug_id = drugId('c6a90f40-fce4-11e9-8f0b-362b9e155667');
update temp_mh set phenobarbital_30mg_tab_dose = obs_from_group_id_value_numeric(obs_group_id_with_drug_answer(encounter_id,@drug_id),'CIEL','160856');
update temp_mh set phenobarbital_30mg_tab_dose_units = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','10744',@locale);
update temp_mh set phenobarbital_30mg_tab_freq = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','9363',@locale);
update temp_mh set phenobarbital_30mg_tab_duration = obs_from_group_id_value_numeric(obs_group_id_with_drug_answer(encounter_id,@drug_id),'CIEL','159368');
update temp_mh set phenobarbital_30mg_tab_dur_units = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','6412',@locale);
update temp_mh set phenobarbital_30mg_tab_route = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','12651',@locale);

set @drug_id = drugId('9a499fca-699e-4809-8175-732ef43d5c14');
update temp_mh set phenobarbital_50mg_tab_dose = obs_from_group_id_value_numeric(obs_group_id_with_drug_answer(encounter_id,@drug_id),'CIEL','160856');
update temp_mh set phenobarbital_50mg_tab_dose_units = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','10744',@locale);
update temp_mh set phenobarbital_50mg_tab_freq = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','9363',@locale);
update temp_mh set phenobarbital_50mg_tab_duration = obs_from_group_id_value_numeric(obs_group_id_with_drug_answer(encounter_id,@drug_id),'CIEL','159368');
update temp_mh set phenobarbital_50mg_tab_dur_units = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','6412',@locale);
update temp_mh set phenobarbital_50mg_tab_route = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','12651',@locale);

set @drug_id = drugId('4eb3c71f-b716-4f01-beb7-394cebd6c191');
update temp_mh set phenobarbital_sol_dose = obs_from_group_id_value_numeric(obs_group_id_with_drug_answer(encounter_id,@drug_id),'CIEL','160856');
update temp_mh set phenobarbital_sol_dose_units = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','10744',@locale);
update temp_mh set phenobarbital_sol_freq = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','9363',@locale);
update temp_mh set phenobarbital_sol_duration = obs_from_group_id_value_numeric(obs_group_id_with_drug_answer(encounter_id,@drug_id),'CIEL','159368');
update temp_mh set phenobarbital_sol_dur_units = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','6412',@locale);
update temp_mh set phenobarbital_sol_route = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','12651',@locale);

set @drug_id = drugId('34dd5905-c28d-4cf8-8ebe-0b83e5093e17');
update temp_mh set phenytoin_sodium_tab_dose = obs_from_group_id_value_numeric(obs_group_id_with_drug_answer(encounter_id,@drug_id),'CIEL','160856');
update temp_mh set phenytoin_sodium_tab_dose_units = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','10744',@locale);
update temp_mh set phenytoin_sodium_tab_freq = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','9363',@locale);
update temp_mh set phenytoin_sodium_tab_duration = obs_from_group_id_value_numeric(obs_group_id_with_drug_answer(encounter_id,@drug_id),'CIEL','159368');
update temp_mh set phenytoin_sodium_tab_dur_units = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','6412',@locale);
update temp_mh set phenytoin_sodium_tab_route = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','12651',@locale);

set @drug_id = drugId('d8297181-0a3f-48fc-89c5-cc283e5a8d42');
update temp_mh set phenytoin_sodium_sol_dose = obs_from_group_id_value_numeric(obs_group_id_with_drug_answer(encounter_id,@drug_id),'CIEL','160856');
update temp_mh set phenytoin_sodium_sol_dose_units = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','10744',@locale);
update temp_mh set phenytoin_sodium_sol_freq = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','9363',@locale);
update temp_mh set phenytoin_sodium_sol_duration = obs_from_group_id_value_numeric(obs_group_id_with_drug_answer(encounter_id,@drug_id),'CIEL','159368');
update temp_mh set phenytoin_sodium_sol_dur_units = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','6412',@locale);
update temp_mh set phenytoin_sodium_sol_route = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','12651',@locale);

set @drug_id = drugId('5edb194a-70bf-4fbf-b2ca-4dce586af7f3');
update temp_mh set amitriptyline_hydrochloride_tab_dose = obs_from_group_id_value_numeric(obs_group_id_with_drug_answer(encounter_id,@drug_id),'CIEL','160856');
update temp_mh set amitriptyline_hydrochloride_tab_dose_units = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','10744',@locale);
update temp_mh set amitriptyline_hydrochloride_tab_freq = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','9363',@locale);
update temp_mh set amitriptyline_hydrochloride_tab_duration = obs_from_group_id_value_numeric(obs_group_id_with_drug_answer(encounter_id,@drug_id),'CIEL','159368');
update temp_mh set amitriptyline_hydrochloride_tab_dur_units = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','6412',@locale);
update temp_mh set amitriptyline_hydrochloride_tab_route = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','12651',@locale);

set @drug_id = drugId('39d7a7ee-b0ff-48e0-a7ca-685688147c8f');
update temp_mh set diazepam_tab_dose = obs_from_group_id_value_numeric(obs_group_id_with_drug_answer(encounter_id,@drug_id),'CIEL','160856');
update temp_mh set diazepam_tab_dose_units = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','10744',@locale);
update temp_mh set diazepam_tab_freq = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','9363',@locale);
update temp_mh set diazepam_tab_duration = obs_from_group_id_value_numeric(obs_group_id_with_drug_answer(encounter_id,@drug_id),'CIEL','159368');
update temp_mh set diazepam_tab_dur_units = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','6412',@locale);
update temp_mh set diazepam_tab_route = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','12651',@locale);

set @drug_id = drugId('923e3e90-8b5c-4ae6-b17f-b6d547803437');
update temp_mh set diazepam_sol_dose = obs_from_group_id_value_numeric(obs_group_id_with_drug_answer(encounter_id,@drug_id),'CIEL','160856');
update temp_mh set diazepam_sol_dose_units = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','10744',@locale);
update temp_mh set diazepam_sol_freq = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','9363',@locale);
update temp_mh set diazepam_sol_duration = obs_from_group_id_value_numeric(obs_group_id_with_drug_answer(encounter_id,@drug_id),'CIEL','159368');
update temp_mh set diazepam_sol_dur_units = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','6412',@locale);
update temp_mh set diazepam_sol_route = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','12651',@locale);

set @drug_id = drugId('8893bad4-a63d-4da6-9d10-96f709b20173');
update temp_mh set trihexyphenidyl_tab_dose = obs_from_group_id_value_numeric(obs_group_id_with_drug_answer(encounter_id,@drug_id),'CIEL','160856');
update temp_mh set trihexyphenidyl_tab_dose_units = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','10744',@locale);
update temp_mh set trihexyphenidyl_tab_freq = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','9363',@locale);
update temp_mh set trihexyphenidyl_tab_duration = obs_from_group_id_value_numeric(obs_group_id_with_drug_answer(encounter_id,@drug_id),'CIEL','159368');
update temp_mh set trihexyphenidyl_tab_dur_units = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','6412',@locale);
update temp_mh set trihexyphenidyl_tab_route = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','12651',@locale);

set @drug_id = drugId('cd09b1b3-ceed-436c-bb57-3e5ca1684c86');
update temp_mh set mirtazapine_15mg_tab_dose = obs_from_group_id_value_numeric(obs_group_id_with_drug_answer(encounter_id,@drug_id),'CIEL','160856');
update temp_mh set mirtazapine_15mg_tab_dose_units = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','10744',@locale);
update temp_mh set mirtazapine_15mg_tab_freq = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','9363',@locale);
update temp_mh set mirtazapine_15mg_tab_duration = obs_from_group_id_value_numeric(obs_group_id_with_drug_answer(encounter_id,@drug_id),'CIEL','159368');
update temp_mh set mirtazapine_15mg_tab_dur_units = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','6412',@locale);
update temp_mh set mirtazapine_15mg_tab_route = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','12651',@locale);

set @drug_id = drugId('95dbfe7e-68ac-485c-af73-9057cbe591b2');
update temp_mh set mirtazapine_30mg_tab_dose = obs_from_group_id_value_numeric(obs_group_id_with_drug_answer(encounter_id,@drug_id),'CIEL','160856');
update temp_mh set mirtazapine_30mg_tab_dose_units = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','10744',@locale);
update temp_mh set mirtazapine_30mg_tab_freq = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','9363',@locale);
update temp_mh set mirtazapine_30mg_tab_duration = obs_from_group_id_value_numeric(obs_group_id_with_drug_answer(encounter_id,@drug_id),'CIEL','159368');
update temp_mh set mirtazapine_30mg_tab_dur_units = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','6412',@locale);
update temp_mh set mirtazapine_30mg_tab_route = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','12651',@locale);

set @drug_id = drugId('66ca3d3e-f594-403b-823c-8b6104738b6f');
update temp_mh set quetiapine_fumarate_tab_dose = obs_from_group_id_value_numeric(obs_group_id_with_drug_answer(encounter_id,@drug_id),'CIEL','160856');
update temp_mh set quetiapine_fumarate_tab_dose_units = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','10744',@locale);
update temp_mh set quetiapine_fumarate_tab_freq = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','9363',@locale);
update temp_mh set quetiapine_fumarate_tab_duration = obs_from_group_id_value_numeric(obs_group_id_with_drug_answer(encounter_id,@drug_id),'CIEL','159368');
update temp_mh set quetiapine_fumarate_tab_dur_units = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','6412',@locale);
update temp_mh set quetiapine_fumarate_tab_route = obs_from_group_id_value_coded_list(obs_group_id_with_drug_answer(encounter_id,@drug_id),'PIH','12651',@locale);

update temp_mh set additional_medication_comments = obs_value_text(encounter_id, 'PIH','10637');

-- outcome

update temp_mh set assigned_chw = obs_value_coded_list(encounter_id, 'PIH','3293',@locale);
update temp_mh set return_visit_date = obs_value_datetime(encounter_id,'PIH','5096');
    
select 
    concat(@partition,"-",patient_id)  "patient_id",
    emr_id,
    location_registered,
    age_at_encounter,
    address,
    concat(@partition,"-",encounter_id)  "encounter_id",
    encounter_type,
    concat(@partition,"-",visit_id)  "visit_id",
    concat(@partition,"-",mh_program_id)  "mh_program_id",
    encounter_datetime,
    provider,
    referred_by_community,
    other_community_referral, 
    referred_by_facility,
    other_facility_referral,
    history_of_homelessness,
    housing_type, 
    hiv_test,
    ARV_start_date,
    TB_smear_result,
    extrapulmonary_tuberculosis,
    alcohol_history,
    alcohol_duration,
    marijuana_history,
    marijuana_duration,
    kush_history,
    kush_duration,
    tramadol_history,
    tramadol_duration, 
    other_drug_history,
    other_drug_duration,
    other_drug_name,
    traditional_medicine_history,
    family_epilepsy,
    family_mental_illness,
    family_behavioral_problems,
    presenting_features,
    other_presenting_features,
    clinical_impressions,
    mental_state_exam_findings,
    other_mental_state_exam_finding,
    past_suicidal_ideation,
    past_suicidal_attempt,
    current_suicidal_ideation,
    current_suicidal_attempt,
    date_latest_suicidal_attempt,
    psychosocial_counseling,
    interventions,
    diagnosis_1,
    diagnosis_2, 
    diagnosis_3,
    diagnosis_4,
    noncoded_diagnosis,
    seizure_frequency,
    CGI_S,
    CGI_I,
    CGI_E,
    chlorpromazine_hydrochloride_tab_dose,
    chlorpromazine_hydrochloride_tab_dose_units,
    chlorpromazine_hydrochloride_tab_freq,
    chlorpromazine_hydrochloride_tab_duration,
    chlorpromazine_hydrochloride_tab_dur_units,
    chlorpromazine_hydrochloride_tab_route,
    chlorpromazine_hydrochloride_sol_dose,
    chlorpromazine_hydrochloride_sol_dose_units,
    chlorpromazine_hydrochloride_sol_freq,
    chlorpromazine_hydrochloride_sol_duration,
    chlorpromazine_hydrochloride_sol_dur_units,
    chlorpromazine_hydrochloride_sol_route,
    haloperidol_oily_sol_dose,
    haloperidol_oily_sol_dose_units,
    haloperidol_oily_sol_freq,
    haloperidol_oily_sol_duration,
    haloperidol_oily_sol_dur_units,
    haloperidol_oily_sol_route,
    haloperidol_tab_dose,
    haloperidol_tab_dose_units,
    haloperidol_tab_freq,
    haloperidol_tab_duration,
    haloperidol_tab_dur_units,
    haloperidol_tab_route,
    haloperidol_sol_dose,
    haloperidol_sol_dose_units,
    haloperidol_sol_freq,
    haloperidol_sol_duration,
    haloperidol_sol_dur_units,
    haloperidol_sol_route,
    fluphenazine_oily_sol_dose,
    fluphenazine_oily_sol_dose_units,
    fluphenazine_oily_sol_freq,
    fluphenazine_oily_sol_duration,
    fluphenazine_oily_sol_dur_units,
    fluphenazine_oily_sol_route,
    carbamazepine_tab_dose,
    carbamazepine_tab_dose_units,
    carbamazepine_tab_freq,
    carbamazepine_tab_duration,
    carbamazepine_tab_dur_units,
    carbamazepine_tab_route,
    sodium_valproate_tab_dose,
    sodium_valproate_tab_dose_units,
    sodium_valproate_tab_freq,
    sodium_valproate_tab_duration,
    sodium_valproate_tab_dur_units,
    sodium_valproate_tab_route,   
    sodium_valproate_sol_dose,
    sodium_valproate_sol_dose_units,
    sodium_valproate_sol_freq,
    sodium_valproate_sol_duration,
    sodium_valproate_sol_dur_units,
    sodium_valproate_sol_route,
    risperidone_tab_dose,
    risperidone_tab_dose_units,
    risperidone_tab_freq,
    risperidone_tab_duration,
    risperidone_tab_dur_units,
    risperidone_tab_route,
    fluoxetine_hydrochloride_tab_dose,
    fluoxetine_hydrochloride_tab_dose_units,
    fluoxetine_hydrochloride_tab_freq,
    fluoxetine_hydrochloride_tab_duration,
    fluoxetine_hydrochloride_tab_dur_units,
    fluoxetine_hydrochloride_tab_route,  
    olanzapine_5mg_tab_dose,
    olanzapine_5mg_tab_dose_units,
    olanzapine_5mg_tab_freq,
    olanzapine_5mg_tab_duration,
    olanzapine_5mg_tab_dur_units,
    olanzapine_5mg_tab_route,
    olanzapine_10mg_tab_dose,
    olanzapine_10mg_tab_dose_units,
    olanzapine_10mg_tab_freq,
    olanzapine_10mg_tab_duration,
    olanzapine_10mg_tab_dur_units,
    olanzapine_10mg_tab_route,
    diphenhydramine_hydrochloride_tab_dose,
    diphenhydramine_hydrochloride_tab_dose_units,
    diphenhydramine_hydrochloride_tab_freq,
    diphenhydramine_hydrochloride_tab_duration,
    diphenhydramine_hydrochloride_tab_dur_units,
    diphenhydramine_hydrochloride_tab_route,
    diphenhydramine_hydrochloride_sol_dose,
    diphenhydramine_hydrochloride_sol_dose_units,
    diphenhydramine_hydrochloride_sol_freq,
    diphenhydramine_hydrochloride_sol_duration,
    diphenhydramine_hydrochloride_sol_dur_units,
    diphenhydramine_hydrochloride_sol_route,   
    phenobarbital_30mg_tab_dose,
    phenobarbital_30mg_tab_dose_units,
    phenobarbital_30mg_tab_freq,
    phenobarbital_30mg_tab_duration,
    phenobarbital_30mg_tab_dur_units,
    phenobarbital_30mg_tab_route,
    phenobarbital_50mg_tab_dose,
    phenobarbital_50mg_tab_dose_units,
    phenobarbital_50mg_tab_freq,
    phenobarbital_50mg_tab_duration,
    phenobarbital_50mg_tab_dur_units,
    phenobarbital_50mg_tab_route,
    phenobarbital_sol_dose,
    phenobarbital_sol_dose_units,
    phenobarbital_sol_freq,
    phenobarbital_sol_duration,
    phenobarbital_sol_dur_units,
    phenobarbital_sol_route,   
    phenytoin_sodium_tab_dose,
    phenytoin_sodium_tab_dose_units,
    phenytoin_sodium_tab_freq,
    phenytoin_sodium_tab_duration,
    phenytoin_sodium_tab_dur_units,
    phenytoin_sodium_tab_route,
    phenytoin_sodium_sol_dose,
    phenytoin_sodium_sol_dose_units,
    phenytoin_sodium_sol_freq,
    phenytoin_sodium_sol_duration,
    phenytoin_sodium_sol_dur_units,
    phenytoin_sodium_sol_route,
    amitriptyline_hydrochloride_tab_dose,
    amitriptyline_hydrochloride_tab_dose_units,
    amitriptyline_hydrochloride_tab_freq,
    amitriptyline_hydrochloride_tab_duration,
    amitriptyline_hydrochloride_tab_dur_units,
    amitriptyline_hydrochloride_tab_route,  
    diazepam_tab_dose,
    diazepam_tab_dose_units,
    diazepam_tab_freq,
    diazepam_tab_duration,
    diazepam_tab_dur_units,
    diazepam_tab_route,
    diazepam_sol_dose,
    diazepam_sol_dose_units,
    diazepam_sol_freq,
    diazepam_sol_duration,
    diazepam_sol_dur_units,
    diazepam_sol_route,
    trihexyphenidyl_tab_dose,
    trihexyphenidyl_tab_dose_units,
    trihexyphenidyl_tab_freq,
    trihexyphenidyl_tab_duration,
    trihexyphenidyl_tab_dur_units,
    trihexyphenidyl_tab_route,  
    mirtazapine_15mg_tab_dose,
    mirtazapine_15mg_tab_dose_units,
    mirtazapine_15mg_tab_freq,
    mirtazapine_15mg_tab_duration,
    mirtazapine_15mg_tab_dur_units,
    mirtazapine_15mg_tab_route,
    mirtazapine_30mg_tab_dose,
    mirtazapine_30mg_tab_dose_units,
    mirtazapine_30mg_tab_freq,
    mirtazapine_30mg_tab_duration,
    mirtazapine_30mg_tab_dur_units,
    mirtazapine_30mg_tab_route,
    quetiapine_fumarate_tab_dose,
    quetiapine_fumarate_tab_dose_units,
    quetiapine_fumarate_tab_freq,
    quetiapine_fumarate_tab_duration,
    quetiapine_fumarate_tab_dur_units,
    quetiapine_fumarate_tab_route,
    additional_medication_comments,
    assigned_chw,
    return_visit_date
from temp_mh;
