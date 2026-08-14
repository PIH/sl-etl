-- Note!  this script, which is for an etl, has a cloned script for an EMR export in config-pihsl

-- ============================================================
-- CONCEPT DEFINITIONS
-- ============================================================

-- Shared
SET @concept_other               = concept_from_mapping('CIEL', '5622');

-- -- Diabetes (concept_id)
SET @dm_confirmed_finding        = concept_from_mapping('CIEL', '1127');
SET @dm_diabetes_mellitus        = concept_from_mapping('CIEL', '113271');
SET @dm_diabetic_ketoacidosis    = concept_from_mapping('CIEL', '119109');
SET @dm_type2                    = concept_from_mapping('CIEL', '124755');
SET @dm_type1                    = concept_from_mapping('CIEL', '137300');
SET @dm_neuropathy               = concept_from_mapping('CIEL', '142429');
SET @dm_retinopathy              = concept_from_mapping('CIEL', '142820');
SET @dm_diabetic_foot            = concept_from_mapping('CIEL', '143265');
SET @dm_in_pregnancy             = concept_from_mapping('CIEL', '156567');
SET @dm_gestational              = concept_from_mapping('CIEL', '165471');
SET @dm_hba1c_test               = concept_from_mapping('CIEL', '167916');
SET @dm_hba1c_result             = concept_from_mapping('CIEL', '167917');
SET @dm_pih_11974                = concept_from_mapping('PIH', '11974');
SET @dm_pih_14485                = concept_from_mapping('PIH', '14485');
SET @dm_pih_14705                = concept_from_mapping('PIH', '14705');
SET @dm_pih_14706                = concept_from_mapping('PIH', '14706');
SET @dm_pih_14711                = concept_from_mapping('PIH', '14711');
SET @dm_pih_14778                = concept_from_mapping('PIH', '14778');
SET @dm_pih_14779                = concept_from_mapping('PIH', '14779');
SET @dm_pih_14781                = concept_from_mapping('PIH', '14781');
SET @dm_pih_14782                = concept_from_mapping('PIH', '14782');
SET @dm_pih_14469                = concept_from_mapping('PIH', '14469');

-- Heart Failure (concept_id)
SET @hf_heart_failure            = concept_from_mapping('CIEL', '160714');
SET @hf_dyspnea                  = concept_from_mapping('CIEL', '122496');
SET @hf_edema                    = concept_from_mapping('CIEL', '127640');
SET @hf_fatigue                  = concept_from_mapping('CIEL', '130166');
SET @hf_orthopnea                = concept_from_mapping('CIEL', '130783');
SET @hf_pnd                      = concept_from_mapping('CIEL', '131689');
SET @hf_jvd                      = concept_from_mapping('CIEL', '136394');
SET @hf_nyha_class               = concept_from_mapping('PIH', 'NYHA CLASS');
SET @hf_pih_14725                = concept_from_mapping('PIH', '14725');
SET @hf_pih_6329                 = concept_from_mapping('PIH', '6329');
SET @hf_pih_14733                = concept_from_mapping('PIH', '14733');
SET @hf_pih_14724                = concept_from_mapping('PIH', '14724');
SET @hf_pih_14742                = concept_from_mapping('PIH', '14742');
SET @hf_pih_14752                = concept_from_mapping('PIH', '14752');
SET @hf_pih_14754                = concept_from_mapping('PIH', '14754');
SET @hf_pih_14756                = concept_from_mapping('PIH', '14756');
SET @hf_pih_20164                = concept_from_mapping('PIH', '20164');

-- Heart Failure (value_coded)
SET @hf_vc_edema                 = concept_from_mapping('CIEL', '5016');
SET @hf_ciel_168116              = concept_from_mapping('CIEL', '168116');
SET @hf_cardiomegaly             = concept_from_mapping('CIEL', '117386');
SET @hf_afib                     = concept_from_mapping('CIEL', '113227');
SET @hf_pericardial_effusion     = concept_from_mapping('CIEL', '127376');
SET @hf_constrictive_pericarditis = concept_from_mapping('CIEL', '119092');
SET @hf_dilated_cardiomyopathy   = concept_from_mapping('CIEL', '120148');
SET @hf_hypertensive_heart_disease = concept_from_mapping('CIEL', '124800');
SET @hf_ischemic_heart_disease   = concept_from_mapping('CIEL', '119956');
SET @hf_lvh                      = concept_from_mapping('CIEL', '139529');
SET @hf_mitral_valve_disease     = concept_from_mapping('CIEL', '142317');
SET @hf_aortic_stenosis          = concept_from_mapping('CIEL', '113918');
SET @hf_aortic_regurgitation     = concept_from_mapping('CIEL', '113096');
SET @hf_rheumatic_heart_disease  = concept_from_mapping('CIEL', '134082');
SET @hf_infective_endocarditis   = concept_from_mapping('CIEL', '115735');
SET @hf_myocarditis              = concept_from_mapping('CIEL', '121532');
SET @hf_restrictive_cardiomyopathy = concept_from_mapping('CIEL', '148546');
SET @hf_hypertrophic_cardiomyopathy = concept_from_mapping('CIEL', '134088');
SET @hf_cor_pulmonale            = concept_from_mapping('PIH', 'COR PULMONALE');
SET @hf_pulmonary_hypertension   = concept_from_mapping('CIEL', '117152');
SET @hf_pulmonary_embolism       = concept_from_mapping('CIEL', '124033');
SET @hf_vsd                      = concept_from_mapping('CIEL', '159343');
SET @hf_asd                      = concept_from_mapping('CIEL', '148203');
SET @hf_pda                      = concept_from_mapping('CIEL', '148202');
SET @hf_tetralogy_of_fallot      = concept_from_mapping('CIEL', '113504');
SET @hf_coarctation_of_aorta     = concept_from_mapping('CIEL', '119624');
SET @hf_ebstein_anomaly          = concept_from_mapping('CIEL', '148196');
SET @hf_tricuspid_regurgitation  = concept_from_mapping('CIEL', '123240');
SET @hf_mitral_stenosis          = concept_from_mapping('CIEL', '130715');
SET @hf_aortic_aneurysm          = concept_from_mapping('CIEL', '144674');
SET @hf_cardiac_tamponade        = concept_from_mapping('CIEL', '124944');
SET @hf_ciel_163712              = concept_from_mapping('CIEL', '163712');
SET @hf_ciel_168127              = concept_from_mapping('CIEL', '168127');
SET @hf_ciel_168128              = concept_from_mapping('CIEL', '168128');
SET @hf_ciel_168182              = concept_from_mapping('CIEL', '168182');
SET @hf_ciel_169981              = concept_from_mapping('CIEL', '169981');
SET @hf_ciel_127436              = concept_from_mapping('CIEL', '127436');
SET @hf_ciel_127437              = concept_from_mapping('CIEL', '127437');
SET @hf_ciel_127438              = concept_from_mapping('CIEL', '127438');
SET @hf_pih_14836                = concept_from_mapping('PIH', '14836');
SET @hf_pih_12231                = concept_from_mapping('PIH', '12231');
SET @hf_pih_20004                = concept_from_mapping('PIH', '20004');
SET @hf_pih_14753                = concept_from_mapping('PIH', '14753');
SET @hf_pih_14750                = concept_from_mapping('PIH', '14750');
SET @hf_pih_11973                = concept_from_mapping('PIH', '11973');
SET @hf_pih_20165                = concept_from_mapping('PIH', '20165');
SET @hf_pih_20166                = concept_from_mapping('PIH', '20166');
SET @hf_pih_20167                = concept_from_mapping('PIH', '20167');
SET @hf_pih_20168                = concept_from_mapping('PIH', '20168');

-- Hypertension (concept_id)
SET @htn_ciel_165583             = concept_from_mapping('CIEL', '165583');
SET @htn_pih_11940               = concept_from_mapping('PIH', '11940');
SET @htn_pih_11971               = concept_from_mapping('PIH', '11971');
SET @htn_pih_14456               = concept_from_mapping('PIH', '14456');
SET @htn_pih_14457               = concept_from_mapping('PIH', '14457');
SET @htn_pih_14462               = concept_from_mapping('PIH', '14462');

-- Kidney (concept_id)
SET @kidney_ciel_165570          = concept_from_mapping('CIEL', '165570');
SET @kidney_pih_3597             = concept_from_mapping('PIH', '3597');
SET @kidney_pih_14717            = concept_from_mapping('PIH', '14717');
SET @kidney_pih_14732            = concept_from_mapping('PIH', '14732');
SET @kidney_pih_14765            = concept_from_mapping('PIH', '14765');
SET @kidney_pih_14766            = concept_from_mapping('PIH', '14766');
SET @kidney_pih_14815            = concept_from_mapping('PIH', '14815');

-- Liver (concept_id)
SET @liver_pih_14875             = concept_from_mapping('PIH', '14875');
SET @liver_pih_14827             = concept_from_mapping('PIH', '14827');
SET @liver_pih_14890             = concept_from_mapping('PIH', '14890');

-- Liver (value_coded)
SET @liver_hepatitis_b           = concept_from_mapping('CIEL', '121812');
SET @liver_hepatitis_c           = concept_from_mapping('CIEL', '120557');
SET @liver_hepatitis_e           = concept_from_mapping('CIEL', '145347');
SET @liver_ciel_146184           = concept_from_mapping('CIEL', '146184');
SET @liver_ciel_149157           = concept_from_mapping('CIEL', '149157');
SET @liver_ciel_143118           = concept_from_mapping('CIEL', '143118');
SET @liver_ciel_168297           = concept_from_mapping('CIEL', '168297');
SET @liver_ciel_168298           = concept_from_mapping('CIEL', '168298');
SET @liver_ciel_168300           = concept_from_mapping('CIEL', '168300');
SET @liver_ciel_168301           = concept_from_mapping('CIEL', '168301');
SET @liver_pih_14910             = concept_from_mapping('PIH', '14910');
SET @liver_pih_14911             = concept_from_mapping('PIH', '14911');
SET @liver_pih_15156             = concept_from_mapping('PIH', '15156');

-- Lung (concept_id)
SET @lung_copd_group             = concept_from_mapping('PIH', 'COPD group classification');
SET @lung_pih_7397               = concept_from_mapping('PIH', '7397');
SET @lung_pih_7399               = concept_from_mapping('PIH', '7399');
SET @lung_pih_7405               = concept_from_mapping('PIH', '7405');
SET @lung_pih_11972              = concept_from_mapping('PIH', '11972');
SET @lung_pih_14587              = concept_from_mapping('PIH', '14587');
SET @lung_pih_14610              = concept_from_mapping('PIH', '14610');
SET @lung_pih_14617              = concept_from_mapping('PIH', '14617');
SET @lung_pih_14620              = concept_from_mapping('PIH', '14620');
SET @lung_pih_14812              = concept_from_mapping('PIH', '14812');

-- Lung (value_coded)
SET @lung_asthma                 = concept_from_mapping('CIEL', '116711');
SET @lung_copd                   = concept_from_mapping('CIEL', '132486');
SET @lung_bronchiectasis         = concept_from_mapping('CIEL', '127611');
SET @lung_ciel_1295              = concept_from_mapping('CIEL', '1295');
SET @lung_ciel_121011            = concept_from_mapping('CIEL', '121011');
SET @lung_ciel_121375            = concept_from_mapping('CIEL', '121375');
SET @lung_ciel_143381            = concept_from_mapping('CIEL', '143381');
SET @lung_pih_14601              = concept_from_mapping('PIH', '14601');

-- Palliative Care (concept_id)
SET @palliative_ciel_165310      = concept_from_mapping('CIEL', '165310');
SET @palliative_ciel_160379      = concept_from_mapping('CIEL', '160379');
SET @palliative_ciel_1788        = concept_from_mapping('CIEL', '1788');
SET @palliative_ciel_1887        = concept_from_mapping('CIEL', '1887');
SET @palliative_pih_14816        = concept_from_mapping('PIH', '14816');
SET @palliative_pih_14817        = concept_from_mapping('PIH', '14817');
SET @palliative_pih_14859        = concept_from_mapping('PIH', '14859');

-- Palliative Care (value_coded)
SET @palliative_ciel_116026      = concept_from_mapping('CIEL', '116026');
SET @palliative_ciel_116066      = concept_from_mapping('CIEL', '116066');
SET @palliative_ciel_133328      = concept_from_mapping('CIEL', '133328');
SET @palliative_ciel_134788      = concept_from_mapping('CIEL', '134788');
SET @palliative_ciel_145438      = concept_from_mapping('CIEL', '145438');
SET @palliative_ciel_155569      = concept_from_mapping('CIEL', '155569');
SET @palliative_pih_14771        = concept_from_mapping('PIH', '14771');
SET @palliative_pih_14772        = concept_from_mapping('PIH', '14772');

-- Sickle Cell (concept_id)
SET @sc_ciel_168730              = concept_from_mapping('CIEL', '168730');
SET @sc_pih_14826                = concept_from_mapping('PIH', '14826');
SET @sc_pih_14858                = concept_from_mapping('PIH', '14858');
SET @sc_pih_14872                = concept_from_mapping('PIH', '14872');
SET @sc_pih_14924                = concept_from_mapping('PIH', '14924');
SET @sc_pih_15162                = concept_from_mapping('PIH', '15162');

-- Sickle Cell (value_coded)
SET @sc_sickle_cell_disease      = concept_from_mapping('CIEL', '117703');
SET @sc_sickle_cell_crisis       = concept_from_mapping('CIEL', '126513');
SET @sc_sickle_cell_trait        = concept_from_mapping('CIEL', '126512');
SET @sc_complications            = concept_from_mapping('CIEL', '168107');
SET @sc_hemoglobin_s             = concept_from_mapping('CIEL', '117635');
SET @sc_painful_crisis           = concept_from_mapping('CIEL', '76613');
SET @sc_acute_chest_syndrome     = concept_from_mapping('CIEL', '81724');

select encounter_type_id INTO @NCDInitial FROM encounter_type where uuid = 'ae06d311-1866-455b-8a64-126a9bd74171'; 
select encounter_type_id INTO @NCDFollowup FROM encounter_type where uuid = '5cbfd6a2-92d9-4ad0-b526-9d29bfe1d10c'; 
select encounter_type_id INTO @NCDFollowupPart1 FROM encounter_type where uuid = 'e02a8c32-4f14-4ff7-a4e9-2f087d9a1cf7'; 
select encounter_type_id INTO @NCDFollowupPart2 FROM encounter_type where uuid = '6a3afa6f-8f78-44a9-80c9-3f4f3b6ad8f2'; 
select encounter_type_id INTO @NCDInitialPart1 FROM encounter_type where uuid = '48c413c4-e7f6-491a-8431-900451fe8a32'; 
select encounter_type_id INTO @NCDInitialPart2 FROM encounter_type where uuid = '43423212-6f70-4df8-a9f7-2aef88df1ee2'; 

set @ncdProgramId = program('NCD'); 

set @locale = global_property_value('default_locale', 'en');
set @partition = '${partitionNum}';

set @yes = concept_name(concept_from_mapping('PIH','YES'),@locale);

drop temporary table if exists temp_ncd;
create temporary table temp_ncd
(
 patient_id                              int(11),         
 emr_id                                  varchar(50),     
 encounter_id                            int(11),         
 encounter_datetime                      datetime,        
 datetime_entered                        datetime,        
 visit_id                                int(11),  
 ncd_program_id                          int(11),
 provider                                varchar(255),    
 creator_user_id                         int(11),         
 user_entered                            varchar(255),    
 encounter_location_id                   int(11),         
 encounter_location                      varchar(255),    
 encounter_type_id                       int(11),         
 encounter_type                          varchar(255), 
 visit_type                        varchar(255),
 care_household                          bit,
 vulnerable                              varchar(255),
 education_level                         varchar(255),
 literacy_level                          varchar(255),
 employment_status                       varchar(255),
 social_support                          bit,             
 social_support_type                     varchar(255),  
 other_social_support                    text, 
 missed_school                           bit,             
 days_lost_schooling                     double,    
 referred_from                           text,
 other_referral                          text,
 hiv                                     varchar(255),    
 risk_factors                            text,            
 comorbidities                           varchar(255),    
 bp_systolic                             double,          
 bp_diastolic                            double,          
 glucose_fingerstick                     varchar(255),    
 fbg_level                               double,          
 rbg_level                               double,          
 bmi                                     varchar(255),    
 obesity                                 bit,    
 number_hospitalizations_since_visit     double,          
 number_hospitalizations_for_ncds        double,
 hospitalization_1_obs_group_id          int(11),
 ncd_diagnoses_caused_hospitalization_1  text,
 number_days_hospitalization_1           double,
 discharge_date_hospitalization_1        date,
 outcome_hospitalization_1               varchar(255),
 hospitalization_2_obs_group_id          int(11), 
 ncd_diagnoses_caused_hospitalization_2  text,
 number_days_hospitalization_2           double,
 discharge_date_hospitalization_2        date,
 outcome_hospitalization_2               varchar(255), 
 hospitalization_3_obs_group_id          int(11), 
 ncd_diagnoses_caused_hospitalization_3  text,
 number_days_hospitalization_3           double,
 discharge_date_hospitalization_3        date,
 outcome_hospitalization_3               varchar(255), 
 diabetes                                bit,             
 hypertension                            bit,             
 heart_failure                           bit,   
 cardiomyopathy                          bit,
 chronic_lung_disease                    bit,             
 chronic_kidney_disease                  bit,             
 liver_cirrhosis_hepb                    bit,             
 palliative_care                         bit,             
 sickle_cell                             bit,             
 other_ncd                               bit,             
 diabetes_onset_date                     date,            
 hypertension_onset_date                 date,            
 heart_failure_onset_date                date,            
 chronic_lung_disease_onset_date         date,            
 chronic_kidney_disease_onset_date       date,            
 liver_cirrhosis_hepb_onset_date         date,            
 palliative_care_onset_date              date,            
 sickle_cell_onset_date                  date,            
 other_ncd_onset_date                    date,            
 treatment_with_hydroxyurea              boolean,         
 reason_no_hydroxyurea                   varchar(255),    
 diabetes_type                           varchar(255),    
 diabetes_indicators_obs_group           int(11),         
 diabetes_control                        varchar(255),    
 diabetes_on_insulin                     bit,             
 diabetes_home_glucometer                bit,
 diabetes_complications                  text,
 lab_order_hba1c                         boolean,        
 hypertension_type                       varchar(255),    
 hypertension_stage                      varchar(255),    
 hypertension_indicators_obs_group       int(11),         
 hypertension_controlled                 varchar(255),    
 rheumatic_heart_disease                 bit,             
 congenital_heart_disease                bit,             
 nyha_classification                     varchar(255),    
 lung_disease_type                       text,    
 on_saba                                 bit,
 on_oral_salbutamol                      bit,
 on_steroid_inhaler                      bit,
 ckd_stage                               varchar(255),    
 ckd_indicators_obs_group                int(11),         
 ckd_controlled                          varchar(255),    
 liver_indicators_obs_group              int(11),       
 liver_disease_controlled                varchar(255),    
 hepatitis_b_obs_group                   int(11),
 on_hepatitis_b_treatment                varchar(255),
 sickle_cell_type                        varchar(255),    
 sickle_cell_complications               text,            
 next_appointment_date                   date,            
 disposition                             varchar(255),    
 transfer_site                           varchar(255),    
 echooptions                             text,            
 echocomment                             text,            
 echocardiogram_findings                 text,            
 on_on_ace_inhibitor_group_id            int,             
 on_ace_inhibitor                        varchar(255),    
 on_beta_blocker                         varchar(255),    
 secondary_antibiotic_prophylaxis        boolean,   
 referred_to_surgery_for_heart_failure   varchar(255), 
 cardiac_surgery_scheduled               varchar(255),    
 type_cardiac_surgery                    varchar(255),    
 cardiac_surgery_performed_date          date,            
 cardiac_surgery_performed               boolean,         
 scd_penicillin_treatment                boolean,         
 scd_folic_acid_treatment                boolean,         
 transfusion_past_12_months              boolean,  
 transfusion_date                        date,
 asthma_severity                         varchar(255),    
 nighttime_waking_asthma                 varchar(255),    
 nighttime_count                         int,             
 symptoms_2x_week_asthma                 varchar(255),    
 symptoms_2x_count                       int,             
 inhaler_for_symptoms_2x_week_asthma     varchar(255),    
 inhaler_count                           int,             
 limitation_obs_group_id                 int,             
 activity_limitation_asthma              varchar(255),    
 activity_count                          int,             
 asthma_control_GINA                     varchar(255), 
 on_esophageal_varices_prophylaxis       varchar(255),
 echocardiogram_obs_group_id             int,             
 echocardiogram_date                     date,            
 diabetic_coma                           boolean,         
 diabetic_without_coma                   boolean,    
 lab_tests_ordered                       text,   
 diabetes_section_populated              boolean,
 heart_failure_section_populated         boolean,
 hypertension_section_populated          boolean,
 kidney_section_populated                boolean,
 liver_section_populated                 boolean,
 lung_section_populated                  boolean,
 palliative_care_section_populated       boolean,
 sickle_cell_section_populated           boolean,
 index_asc                               int,             
 index_desc                              int              
);

insert into temp_ncd
	(patient_id,
	encounter_id,
	encounter_datetime,
	datetime_entered,
	visit_id,
	creator_user_id,
	encounter_location_id,
	encounter_type_id)
select 
	patient_id,
	encounter_id,
	e.encounter_datetime ,
	e.date_created,
	e.visit_id ,
	e.creator ,
	e.location_id ,
	e.encounter_type 
from encounter e
where e.voided = 0
and e.encounter_type in (@NCDInitial,@NCDFollowup, @NCDInitialPart1, @NCDInitialPart2, @NCDFollowupPart1, @NCDFollowupPart2)
and (DATE(encounter_datetime) >=  date(@startDate) or @startDate is null)
and (DATE(encounter_datetime) <=  date(@endDate) or @endDate is null)
;	

create index ncd_encounter_ei on temp_ncd(encounter_id);

update temp_ncd
set ncd_program_id = patient_program_id_from_encounter(patient_id, @ncdProgramId, encounter_id);

-- encounter level columns
update temp_ncd
set user_entered = person_name_of_user(creator_user_id);

update temp_ncd
set encounter_location = location_name(encounter_location_id);

update temp_ncd
set encounter_type = encounterName(encounter_type_id);

update temp_ncd
set provider = provider(encounter_id);

-- patient level columns
drop temporary table if exists temp_ncd_patients;
create temporary table temp_ncd_patients
	(patient_id int(11),
	emr_id varchar(255));

create index temp_ncd_patients_pi on temp_ncd_patients(patient_id);

insert into temp_ncd_patients (patient_id)
select distinct patient_id from temp_ncd;

update temp_ncd_patients t
set t.emr_id = patient_identifier(patient_id, metadata_uuid('org.openmrs.module.emrapi', 'emr.primaryIdentifierType'));

update temp_ncd t 
inner join temp_ncd_patients p on p.patient_id = t.patient_id
set t.emr_id = p.emr_id;

-- obs level columns
DROP TEMPORARY TABLE IF EXISTS temp_obs;
create temporary table temp_obs 
select o.obs_id, o.voided ,o.obs_group_id , o.encounter_id, o.person_id, o.concept_id, o.value_coded, o.value_numeric, o.value_text,o.value_datetime, o.comments, o.date_created 
,o.obs_datetime
from obs o
inner join temp_ncd t on t.encounter_id = o.encounter_id
where o.voided = 0 
;

create index temp_obs_oi on temp_obs(obs_id);
create index temp_obs_ci1 on temp_obs(encounter_id,concept_id);
create index temp_obs_ci2 on temp_obs(person_id,concept_id);
create index temp_obs_ci3 on temp_obs(encounter_id, concept_id, value_coded);
create index temp_obs_ci4 on temp_obs(obs_group_id, concept_id);

DROP TEMPORARY TABLE IF EXISTS limitation_obs_id;
CREATE TEMPORARY TABLE limitation_obs_id
SELECT encounter_id, obs_id AS obs_group_id
FROM temp_obs
WHERE concept_id=concept_from_mapping('PIH','14587');

create index limitation_obs_id_c1 on limitation_obs_id(encounter_id, obs_group_id);

update temp_ncd t
set echocardiogram_obs_group_id=obs_group_id_of_value_coded_from_temp(encounter_id,'PIH','8614','PIH','3763');

UPDATE temp_ncd t
SET echocardiogram_date=obs_from_group_id_value_datetime_from_temp(t.echocardiogram_obs_group_id,'PIH','12847');

update temp_ncd t
set next_appointment_date = DATE(obs_value_datetime_from_temp(encounter_id, 'PIH','5096'));

update temp_ncd t
set disposition = 
	CASE obs_value_coded_list_from_temp(encounter_id, 'PIH','8620',@locale)
		WHEN concept_name(concept_from_mapping('PIH','2224'),@locale) then 'Laboratory tests outstanding'
		WHEN concept_name(concept_from_mapping('PIH','12358'),@locale) then 'No action taken'
		ELSE obs_value_coded_list_from_temp(encounter_id, 'PIH','8620',@locale)
	END;

update temp_ncd t
set visit_type = obs_value_coded_list_from_temp(encounter_id, 'PIH','6189',@locale);

update temp_ncd t
set care_household = value_coded_as_boolean(obs_id_from_temp(encounter_id, 'PIH','10642',0));

update temp_ncd t
set vulnerable = obs_value_coded_list_from_temp(encounter_id, 'PIH','11959',@locale);

update temp_ncd t
set education_level = obs_value_coded_list_from_temp(encounter_id, 'PIH','1688',@locale);

update temp_ncd t
set literacy_level = obs_value_coded_list_from_temp(encounter_id, 'PIH','13736',@locale);

update temp_ncd t
set employment_status = obs_value_coded_list_from_temp(encounter_id, 'PIH','3395',@locale);

update temp_ncd t
set referred_from = obs_value_coded_list_from_temp(encounter_id, 'PIH','7454',@locale);

-- update referred from to match form
UPDATE temp_ncd set referred_from = replace(referred_from, 'Hospitalized', 'Inpatient Ward');
UPDATE temp_ncd set referred_from = replace(referred_from, 'Primary care clinic', 'OPD');

update temp_ncd t
set other_referral = obs_value_text_from_temp(encounter_id, 'PIH','6421');

update temp_ncd t
set social_support = value_coded_as_boolean(obs_id_from_temp(encounter_id, 'PIH','14443',0));

update temp_ncd t
set social_support_type = obs_value_coded_list_from_temp(encounter_id, 'PIH','2156',@locale);

update temp_ncd t
set other_social_support = obs_comments_from_temp(encounter_id, 'PIH','2156', 'PIH','5622');

update temp_ncd t
set missed_school = value_coded_as_boolean(obs_id_from_temp(encounter_id, 'PIH','5629',0));

update temp_ncd t
set days_lost_schooling = obs_value_numeric_from_temp(encounter_id, 'PIH','14446');

update temp_ncd t
set hiv = obs_value_coded_list_from_temp(encounter_id, 'PIH','1169',@locale);

-- risk factors
set @yes_concept = concept_from_mapping('PIH','YES');
set @alcohol = concept_from_mapping('CIEL','159449');
set @smoking = concept_from_mapping('CIEL','163731');
set @indoor_cooking = concept_from_mapping('CIEL','159365');
set @history_pulmonary_tb = concept_from_mapping('PIH','14582');
set @occupational_exposure = concept_from_mapping('CIEL','167822');
set @seasonal_allergies = concept_from_mapping('PIH','14584');
set @excessive_salt = concept_from_mapping('PIH','14452');
set @maggie_seasoning = concept_from_mapping('CIEL','167878');
set @ace_inhibitors = concept_from_mapping('CIEL','167998');
set @nsaids = concept_from_mapping('PIH','14712');
set @nephrotoxic_drugs = concept_from_mapping('PIH','14713');
set @history_cardiac_disease = concept_from_mapping('CIEL','140231');

update temp_ncd t
set risk_factors = (
	select group_concat(concept_name(concept_id,@locale) SEPARATOR '|') from temp_obs o
	where o.encounter_id = t.encounter_id
	and value_coded = @yes_concept
	and obs_group_id is null
	and concept_id in (@alcohol,@smoking,@indoor_cooking,@history_pulmonary_tb,
		@occupational_exposure,@seasonal_allergies,@excessive_salt,@maggie_seasoning,
		@ace_inhibitors,@nsaids,@nephrotoxic_drugs,@history_cardiac_disease)
	group by encounter_id);

update temp_ncd t
set comorbidities = obs_value_coded_list_from_temp(encounter_id, 'PIH','12976',@locale);

update temp_ncd t
set bp_systolic = obs_value_numeric_from_temp(encounter_id, 'PIH','5085');

update temp_ncd t
set bp_diastolic = obs_value_numeric_from_temp(encounter_id, 'PIH','5086');

update temp_ncd t
set glucose_fingerstick = 
	if(obs_single_value_coded_from_temp(encounter_id, 'PIH','6689','PIH','1065')=@yes, 'FBG',
		if(obs_single_value_coded_from_temp(encounter_id, 'PIH','6689','PIH','1066')=@yes, 'RBG',null));

update temp_ncd t 
set fbg_level = obs_value_numeric_from_temp(encounter_id, 'CIEL','160912');

update temp_ncd t 
set rbg_level = obs_value_numeric_from_temp(encounter_id, 'CIEL','887');
	
update temp_ncd t
set bmi = 
	CASE obs_value_coded_list_from_temp(encounter_id, 'PIH','14126',@locale)
		WHEN concept_name(concept_from_mapping('PIH','7507'),@locale) then 'Moderate obese'
		WHEN concept_name(concept_from_mapping('PIH','14455'),@locale) then 'Severe obese'
		ELSE obs_value_coded_list_from_temp(encounter_id, 'PIH','14126',@locale)
	END;

update temp_ncd t
set obesity = 
	if(obs_single_value_coded_from_temp(encounter_id, 'PIH','1293','PIH','7507')=@yes, 1,
		if(obs_single_value_coded_from_temp(encounter_id, 'PIH','1734','PIH','7507')=@yes, 0,null));

-- hospitalization section
update temp_ncd t
set number_hospitalizations_since_visit = obs_value_numeric_from_temp(encounter_id, 'PIH','5704');

update temp_ncd t
set number_hospitalizations_for_ncds = obs_value_numeric_from_temp(encounter_id, 'PIH','15160');

-- hospitalization section 1
update temp_ncd t
set hospitalization_1_obs_group_id = obs_id_from_temp(encounter_id, 'PIH','3801',0);

update temp_ncd t
set number_days_hospitalization_1 = obs_from_group_id_value_numeric_from_temp(hospitalization_1_obs_group_id,'PIH','2872');

update temp_ncd t
set discharge_date_hospitalization_1 = obs_from_group_id_value_datetime_from_temp(hospitalization_1_obs_group_id,'PIH','3800');

update temp_ncd t
set ncd_diagnoses_caused_hospitalization_1 = obs_from_group_id_value_coded_list_from_temp(hospitalization_1_obs_group_id, 'PIH','12476',@locale);

update temp_ncd t
set outcome_hospitalization_1 = obs_from_group_id_value_coded_list_from_temp(hospitalization_1_obs_group_id,'PIH','15159', @locale);

-- hospitalization section 2
update temp_ncd t
set hospitalization_2_obs_group_id = obs_id_from_temp(encounter_id, 'PIH','3801',1);

update temp_ncd t
set number_days_hospitalization_2 = obs_from_group_id_value_numeric_from_temp(hospitalization_2_obs_group_id,'PIH','2872');

update temp_ncd t
set discharge_date_hospitalization_2 = obs_from_group_id_value_datetime_from_temp(hospitalization_2_obs_group_id,'PIH','3800');

update temp_ncd t
set ncd_diagnoses_caused_hospitalization_2 = obs_from_group_id_value_coded_list_from_temp(hospitalization_2_obs_group_id, 'PIH','12476',@locale);

update temp_ncd t
set outcome_hospitalization_2 = obs_from_group_id_value_coded_list_from_temp(hospitalization_2_obs_group_id,'PIH','15159', @locale);

-- hospitalization section 3
update temp_ncd t
set hospitalization_3_obs_group_id = obs_id_from_temp(encounter_id, 'PIH','3801',2);

update temp_ncd t
set number_days_hospitalization_3 = obs_from_group_id_value_numeric_from_temp(hospitalization_3_obs_group_id,'PIH','2872');

update temp_ncd t
set discharge_date_hospitalization_3 = obs_from_group_id_value_datetime_from_temp(hospitalization_3_obs_group_id,'PIH','3800');

update temp_ncd t
set ncd_diagnoses_caused_hospitalization_3 = obs_from_group_id_value_coded_list_from_temp(hospitalization_3_obs_group_id, 'PIH','12476',@locale);

update temp_ncd t
set outcome_hospitalization_3 = obs_from_group_id_value_coded_list_from_temp(hospitalization_3_obs_group_id,'PIH','15159', @locale);

update temp_ncd t
set diabetes = 
	if(obs_single_value_coded_from_temp(encounter_id, 'PIH','10529','PIH','3720')=@yes, 1,null);

update temp_ncd t
set diabetes_onset_date =  obs_from_group_id_value_datetime(obs_group_id_of_value_coded(encounter_id, 'PIH','10529','PIH','3720'), 'PIH','7538');
 

update temp_ncd t
set hypertension = 
	if(obs_single_value_coded_from_temp(encounter_id, 'PIH','10529','PIH','903')=@yes, 1,null);

update temp_ncd t
set hypertension_onset_date =  obs_from_group_id_value_datetime(obs_group_id_of_value_coded(encounter_id, 'PIH','10529','PIH','903'), 'PIH','7538');

update temp_ncd t
set cardiomyopathy = 
	if(obs_single_value_coded_from_temp(encounter_id, 'PIH','3064','PIH','5016')=@yes, 1,null);

update temp_ncd t
set heart_failure = 
	if(obs_single_value_coded_from_temp(encounter_id, 'PIH','10529','PIH','3468')=@yes, 1,null);

update temp_ncd t
set heart_failure_onset_date =  obs_from_group_id_value_datetime(obs_group_id_of_value_coded(encounter_id, 'PIH','10529','PIH','3468'), 'PIH','7538');
 

update temp_ncd t
set chronic_lung_disease = 
	if(obs_single_value_coded_from_temp(encounter_id, 'PIH','10529','PIH','6768')=@yes, 1,null);

update temp_ncd t
set chronic_lung_disease_onset_date =  obs_from_group_id_value_datetime(obs_group_id_of_value_coded(encounter_id, 'PIH','10529','PIH','6768'), 'PIH','7538');

update temp_ncd t
set chronic_kidney_disease = 
	if(obs_single_value_coded_from_temp(encounter_id, 'PIH','10529','PIH','3699')=@yes, 1,null);

update temp_ncd t
set chronic_kidney_disease_onset_date =  obs_from_group_id_value_datetime(obs_group_id_of_value_coded(encounter_id, 'PIH','10529','PIH','3699'), 'PIH','7538');


update temp_ncd t
set liver_cirrhosis_hepb = 
	if(obs_single_value_coded_from_temp(encounter_id, 'PIH','10529','PIH','3714')=@yes, 1,null);

update temp_ncd t
set liver_cirrhosis_hepb_onset_date =  obs_from_group_id_value_datetime(obs_group_id_of_value_coded(encounter_id, 'PIH','10529','PIH','3714'), 'PIH','7538');


update temp_ncd t
set palliative_care = 
	if(obs_single_value_coded_from_temp(encounter_id, 'PIH','10529','PIH','10359')=@yes, 1,null);

update temp_ncd t
set palliative_care_onset_date =  obs_from_group_id_value_datetime(obs_group_id_of_value_coded(encounter_id, 'PIH','10529','PIH','10359'), 'PIH','7538');


update temp_ncd t
set sickle_cell = 
	if(obs_single_value_coded_from_temp(encounter_id, 'PIH','10529','PIH','7908')=@yes, 1,null);

update temp_ncd t
set sickle_cell_onset_date =  obs_from_group_id_value_datetime(obs_group_id_of_value_coded(encounter_id, 'PIH','10529','PIH','7908'), 'PIH','7538');

update temp_ncd t
set other_ncd = 
	if(obs_single_value_coded_from_temp(encounter_id, 'PIH','10529','PIH','5622')=@yes, 1,null);

update temp_ncd t
set other_ncd_onset_date =  obs_from_group_id_value_datetime(obs_group_id_of_value_coded(encounter_id, 'PIH','10529','PIH','5622'), 'PIH','7538');

update temp_ncd t
set treatment_with_hydroxyurea  = value_coded_as_boolean(obs_id_from_temp(encounter_id, 'PIH','14870',0));

update temp_ncd t
set reason_no_hydroxyurea = obs_value_coded_list_from_temp(encounter_id, 'PIH','15169',@locale);

update temp_ncd t
set diabetes_indicators_obs_group = obs_id_from_temp(encounter_id,'PIH','14469',0 );

update temp_ncd t
set  diabetes_control = obs_from_group_id_value_coded_list_from_temp(diabetes_indicators_obs_group, 'PIH','11506',@locale);

update temp_ncd t
set diabetes_home_glucometer = value_coded_as_boolean(obs_id_from_temp(encounter_id, 'PIH','14503',0));

update temp_ncd t
set diabetes_on_insulin = value_coded_as_boolean(obs_id_from_temp(encounter_id, 'PIH','6756',0));

update temp_ncd t
set diabetes_complications = obs_value_coded_list_from_temp(encounter_id, 'PIH','14485',@locale);
update temp_ncd t
set diabetes_complications = replace(diabetes_complications, 'Cerebrovascular accident', 'Stroke'); -- update to match form verbiage

set @dx = concept_from_mapping('PIH','3064');
set @type_1_dm = concept_from_mapping('PIH','6691');
set @type_2_dm = concept_from_mapping('PIH','6692');
set @gest_dm = concept_from_mapping('PIH','6693');
set @unspec_dm = concept_from_mapping('PIH','3720');
update temp_ncd t
set diabetes_type = 
(select concept_name(o.value_coded,@locale)
from temp_obs o 
where o.encounter_id = t.encounter_id
and o.concept_id = @dx
 and o.value_coded IN (@type_1_dm,@type_2_dm,@gest_dm,@unspec_dm)
ORDER BY FIELD(o.value_coded,@unspec_dm)
limit 1);

update temp_ncd t
set hypertension_indicators_obs_group = obs_id_from_temp(encounter_id,'PIH','14462',0);

update temp_ncd t
set  hypertension_controlled = obs_from_group_id_value_coded_list_from_temp(hypertension_indicators_obs_group, 'PIH','11506',@locale);

update temp_ncd t
set hypertension_type = obs_value_coded_list_from_temp(encounter_id, 'PIH','11940',@locale);

update temp_ncd t
set hypertension_stage = 
	CASE obs_value_coded_list_from_temp(encounter_id, 'PIH','12699',@locale)
		WHEN concept_name(concept_from_mapping('PIH','12697'),@locale) then 'Pre-HTN'
		WHEN concept_name(concept_from_mapping('PIH','12698'),@locale) then '1 (Mild)'
		WHEN concept_name(concept_from_mapping('PIH','12695'),@locale) then '2 (Moderate)'		
		ELSE obs_value_coded_list_from_temp(encounter_id, 'PIH','12699',@locale)
	END;

update temp_ncd t
set rheumatic_heart_disease = 
	if(obs_single_value_coded_from_temp(encounter_id, 'PIH','3064','PIH','221')=@yes, 1,null);

update temp_ncd t
set congenital_heart_disease = 
	if(obs_single_value_coded_from_temp(encounter_id, 'PIH','3064','PIH','3131')=@yes, 1,null);

update temp_ncd t
set nyha_classification = obs_value_coded_list_from_temp(encounter_id, 'PIH','3139',@locale);

set @copd = concept_from_mapping('PIH','3716');
set @bronchiectasis = concept_from_mapping('PIH','7952');
set @asthma = concept_from_mapping('PIH','5');
set @corPulmonale = concept_from_mapping('PIH','4000');
update temp_ncd t
set lung_disease_type = 
(select GROUP_CONCAT(concept_name(o.value_coded,@locale) separator ' | ')
from temp_obs o 
where o.encounter_id = t.encounter_id
and o.concept_id = @dx
 and o.value_coded IN (@copd,@bronchiectasis,@asthma,@corPulmonale)
 group by encounter_id
);

update temp_ncd t
set on_saba = 
	if(obs_single_value_coded_from_temp(encounter_id, 'PIH','14603','PIH','14604')=@yes, 1,null);

update temp_ncd t
set on_oral_salbutamol = 
	if(obs_single_value_coded_from_temp(encounter_id, 'PIH','14603','PIH','15163')=@yes, 1,null);

update temp_ncd t
set on_steroid_inhaler = 
	if(obs_single_value_coded_from_temp(encounter_id, 'PIH','14603','PIH','14609')=@yes, 1,null);

update temp_ncd t
set ckd_stage = obs_value_coded_list_from_temp(encounter_id, 'PIH','12501',@locale);

UPDATE temp_ncd t
SET echooptions = obs_from_group_id_value_coded_list(echocardiogram_obs_group_id,'PIH','3763',@locale);

UPDATE temp_ncd t
SET echocomment = obs_from_group_id_value_text(echocardiogram_obs_group_id, 'PIH', '8596');

UPDATE temp_ncd t
SET echocardiogram_findings =  concat(concat(echooptions,'| '),echocomment );

update temp_ncd t
set ckd_indicators_obs_group = obs_id_from_temp(encounter_id,'PIH','14717',0);

update temp_ncd t
set  ckd_controlled = obs_from_group_id_value_coded_list_from_temp(ckd_indicators_obs_group, 'PIH','11506',@locale);

update temp_ncd t
set liver_indicators_obs_group = obs_id_from_temp(encounter_id,'PIH','14827',0);

update temp_ncd t
set hepatitis_b_obs_group = obs_id_from_temp(encounter_id,'PIH','14890',0);

update temp_ncd t
set  liver_disease_controlled = obs_from_group_id_value_coded_list_from_temp(liver_indicators_obs_group, 'PIH','11506',@locale);

update temp_ncd t
set  on_hepatitis_b_treatment = obs_from_group_id_value_coded_list_from_temp(hepatitis_b_obs_group, 'PIH','14889',@locale);

set @sickle_cell_trait = concept_from_mapping('PIH','7915');
set @sickle_anemia = concept_from_mapping('PIH','7908');
set @beta_thalassemia = concept_from_mapping('PIH','14923');
set @hemoglobin_c  = concept_from_mapping('PIH','12715');
set @other_hemoglobinopathy  = concept_from_mapping('PIH','10134');

update temp_ncd t
set sickle_cell_type = 
(select concept_name(o.value_coded,@locale)
from temp_obs o 
where o.encounter_id = t.encounter_id
and o.concept_id = @dx
 and o.value_coded IN (@sickle_cell_trait,@sickle_anemia,@beta_thalassemia,@hemoglobin_c,@other_hemoglobinopathy)
limit 1);

update temp_ncd t
set sickle_cell_complications = obs_value_coded_list_from_temp(encounter_id,'PIH', '15157',@locale);


update temp_ncd t
set transfer_site = obs_value_datetime_from_temp(encounter_id, 'PIH','14424');

update temp_ncd t
set transfer_site = obs_value_coded_list_from_temp(encounter_id, 'PIH','14424',@locale);

UPDATE temp_ncd t
SET on_on_ace_inhibitor_group_id = obs_id_from_temp(encounter_id, 'PIH','14724', 0);


update temp_ncd t
set on_ace_inhibitor = obs_from_group_id_value_coded_list_from_temp(on_on_ace_inhibitor_group_id,'PIH','14531',@locale );

update temp_ncd t
set on_beta_blocker = obs_value_coded_list_from_temp(encounter_id,'PIH', '14723',@locale);

update temp_ncd t
set secondary_antibiotic_prophylaxis = value_coded_as_boolean(obs_id_from_temp(encounter_id, 'PIH','15168',0));

update temp_ncd t
set cardiac_surgery_scheduled = obs_value_coded_list_from_temp(encounter_id,'PIH', '15165',@locale);

update temp_ncd t
set type_cardiac_surgery = obs_value_coded_list_from_temp(encounter_id,'PIH', '7887',@locale);

update temp_ncd t
set cardiac_surgery_performed = 
	if(obs_single_value_coded_from_temp(encounter_id, 'PIH','10484','PIH','7827')=@yes, 1,null);

update temp_ncd t
set cardiac_surgery_performed_date = obs_value_datetime_from_temp(encounter_id, 'PIH','10485');

update temp_ncd t
set referred_to_surgery_for_heart_failure = obs_value_coded_list_from_temp(encounter_id, 'PIH','14738',@locale);

update temp_ncd t
set scd_penicillin_treatment = 
	if(obs_single_value_coded_from_temp(encounter_id, 'PIH','14857','PIH','784')=@yes, 1,null);

update temp_ncd t
set scd_folic_acid_treatment = 
	if(obs_single_value_coded_from_temp(encounter_id, 'PIH','14857','PIH','257')=@yes, 1,null);

update temp_ncd t
set transfusion_past_12_months = value_coded_as_boolean(obs_id_from_temp(encounter_id, 'PIH','7868',0));

update temp_ncd t
set transfusion_date = obs_value_datetime_from_temp(encounter_id, 'PIH','11064');

update temp_ncd t
set asthma_severity = obs_value_coded_list_from_temp(encounter_id,'PIH', '7405',@locale);

update temp_ncd t
set nighttime_waking_asthma = obs_value_coded_list_from_temp(encounter_id,'PIH', '11731',@locale);
UPDATE temp_ncd t
SET nighttime_count = if(nighttime_waking_asthma=@yes, 1, 0);
	
update temp_ncd t
set symptoms_2x_week_asthma = obs_value_coded_list_from_temp(encounter_id,'PIH', '11803',@locale);
UPDATE temp_ncd t
SET symptoms_2x_count = if(symptoms_2x_week_asthma=@yes, 1, 0);

update temp_ncd t
set inhaler_for_symptoms_2x_week_asthma = obs_value_coded_list_from_temp(encounter_id,'PIH', '11991',@locale);
UPDATE temp_ncd t
SET inhaler_count = if(inhaler_for_symptoms_2x_week_asthma=@yes, 1, 0);

UPDATE temp_ncd t
INNER JOIN limitation_obs_id l ON t.encounter_id=l.encounter_id
SET activity_limitation_asthma=obs_from_group_id_value_coded_list_from_temp(l.obs_group_id, 'PIH', '11925',@locale);

UPDATE temp_ncd t
SET activity_count = if(activity_limitation_asthma=@yes, 1, 0);

UPDATE temp_ncd t
SET asthma_control_GINA = 
CASE WHEN (nighttime_waking_asthma IS NULL OR symptoms_2x_week_asthma IS NULL OR inhaler_for_symptoms_2x_week_asthma IS NULL OR activity_limitation_asthma IS NULL) THEN NULL 
WHEN ((nighttime_count+symptoms_2x_count+inhaler_count+activity_count) BETWEEN 3 AND 4) THEN 'Uncontrolled'
WHEN ((nighttime_count+symptoms_2x_count+inhaler_count+activity_count) BETWEEN 1 AND 2) THEN 'Partly controlled'
WHEN ((nighttime_count+symptoms_2x_count+inhaler_count+activity_count)  = 0 ) THEN 'Well controlled'
END;

DROP TABLE IF EXISTS order_hb1ac;
CREATE TABLE order_hb1ac AS
SELECT t.encounter_id,CASE WHEN o.concept_id = concept_from_mapping('PIH','7460') THEN TRUE ELSE FALSE END AS "lab_order_hba1c"
FROM temp_ncd t LEFT OUTER JOIN orders o ON t.encounter_id=o.encounter_id AND o.voided=0;

UPDATE temp_ncd t
INNER JOIN order_hb1ac o ON t.encounter_id=o.encounter_id
SET t.lab_order_hba1c= o.lab_order_hba1c;

update temp_ncd t
set on_esophageal_varices_prophylaxis = obs_value_coded_list_from_temp(encounter_id,'PIH', '15164',@locale);

UPDATE temp_ncd t
SET diabetic_coma = answer_exists_in_encounter(t.encounter_id, 'PIH', '14921', 'PIH','14482');
UPDATE temp_ncd t
SET diabetic_coma=NULL 
WHERE diabetic_coma=FALSE;

UPDATE temp_ncd t
SET diabetic_without_coma = answer_exists_in_encounter(t.encounter_id, 'PIH', '14921', 'PIH','14483');
UPDATE temp_ncd t
SET diabetic_without_coma=NULL 
WHERE diabetic_without_coma=FALSE;

-- lab tests
select order_type_id into @testOrder from order_type ot where uuid = '52a447d3-a64a-11e3-9aeb-50e549534c5e';
update temp_ncd t
set lab_tests_ordered = 
	(select GROUP_CONCAT(concept_name(o.concept_id,@locale) SEPARATOR '|')
	from orders o
	where o.encounter_id = t.encounter_id 
	and voided = 0
	and o.order_type_id = @testOrder
	group by encounter_id);


-- ============================================================
-- CHECK IF SECTIONS ARE POPULATED
-- ============================================================

-- Diabetes
UPDATE temp_ncd t
SET diabetes_section_populated = 1
WHERE EXISTS (
    SELECT 1 FROM temp_obs o
    WHERE o.encounter_id = t.encounter_id
    AND o.concept_id IN (
        @dm_confirmed_finding,
        @dm_diabetes_mellitus,
        @dm_diabetic_ketoacidosis,
        @dm_type2,
        @dm_type1,
        @dm_neuropathy,
        @dm_retinopathy,
        @dm_diabetic_foot,
        @dm_in_pregnancy,
        @dm_gestational,
        @dm_hba1c_test,
        @dm_hba1c_result,
        @concept_other,
        @dm_pih_11974,
        @dm_pih_14485,
        @dm_pih_14705,
        @dm_pih_14706,
        @dm_pih_14711,
        @dm_pih_14778,
        @dm_pih_14779,
        @dm_pih_14781,
        @dm_pih_14782,
        @dm_pih_14469
    )
);

-- Heart Failure (concept_id)
UPDATE temp_ncd t
SET heart_failure_section_populated = 1
WHERE EXISTS (
    SELECT 1 FROM temp_obs o
    WHERE o.encounter_id = t.encounter_id
    AND o.concept_id IN (
        @hf_pih_14725,
        @hf_heart_failure,
        @hf_pih_6329,
        @hf_pih_14733,
        @hf_dyspnea,
        @hf_edema,
        @hf_fatigue,
        @hf_orthopnea,
        @hf_pnd,
        @hf_jvd,
        @hf_pih_14724,
        @hf_pih_14742,
        @hf_pih_14752,
        @hf_pih_14754,
        @hf_pih_14756,
        @hf_pih_20164,
        @hf_nyha_class
    )
);

-- Heart Failure (value_coded)
UPDATE temp_ncd t
SET heart_failure_section_populated = 1
WHERE EXISTS (
    SELECT 1 FROM temp_obs o
    WHERE o.encounter_id = t.encounter_id
    AND o.value_coded IN (
        @hf_vc_edema,
        @hf_ciel_168116,
        @hf_cardiomegaly,
        @hf_afib,
        @hf_pih_14836,
        @hf_pericardial_effusion,
        @hf_constrictive_pericarditis,
        @hf_dilated_cardiomyopathy,
        @hf_hypertensive_heart_disease,
        @hf_ischemic_heart_disease,
        @hf_pih_12231,
        @hf_pih_20004,
        @hf_lvh,
        @hf_mitral_valve_disease,
        @hf_aortic_stenosis,
        @hf_aortic_regurgitation,
        @hf_ciel_163712,
        @hf_ciel_168128,
        @hf_ciel_168182,
        @hf_ciel_169981,
        @hf_pih_14753,
        @hf_ciel_127437,
        @hf_ciel_127438,
        @hf_ciel_127436,
        @hf_pih_20166,
        @hf_pih_14750,
        @hf_pih_20167,
        @hf_pih_20168,
        @hf_rheumatic_heart_disease,
        @hf_infective_endocarditis,
        @hf_myocarditis,
        @hf_restrictive_cardiomyopathy,
        @hf_hypertrophic_cardiomyopathy,
        @hf_cor_pulmonale,
        @hf_pulmonary_hypertension,
        @hf_pulmonary_embolism,
        @hf_ciel_168127,
        @hf_vsd,
        @hf_asd,
        @hf_pda,
        @hf_tetralogy_of_fallot,
        @hf_coarctation_of_aorta,
        @hf_ebstein_anomaly,
        @hf_tricuspid_regurgitation,
        @hf_mitral_stenosis,
        @hf_aortic_aneurysm,
        @hf_cardiac_tamponade,
        @hf_pih_20165,
        @hf_pih_20164,
        @hf_pih_11973
    )
);

-- Hypertension
UPDATE temp_ncd t
SET hypertension_section_populated = 1
WHERE EXISTS (
    SELECT 1 FROM temp_obs o
    WHERE o.encounter_id = t.encounter_id
    AND o.concept_id IN (
        @htn_pih_11940,
        @htn_ciel_165583,
        @htn_pih_11971,
        @htn_pih_14456,
        @htn_pih_14457,
        @htn_pih_14462
    )
);

-- Kidney
UPDATE temp_ncd t
SET kidney_section_populated = 1
WHERE EXISTS (
    SELECT 1 FROM temp_obs o
    WHERE o.encounter_id = t.encounter_id
    AND o.concept_id IN (
        @kidney_pih_14732,
        @kidney_pih_14717,
        @kidney_pih_14765,
        @kidney_pih_14815,
        @kidney_pih_3597,
        @kidney_pih_14766,
        @kidney_ciel_165570
    )
);

-- Liver (concept_id)
UPDATE temp_ncd t
SET liver_section_populated = 1
WHERE EXISTS (
    SELECT 1 FROM temp_obs o
    WHERE o.encounter_id = t.encounter_id
    AND o.concept_id IN (
        @liver_pih_14875,
        @liver_pih_14827,
        @liver_pih_14890
    )
);

-- Liver (value_coded)
UPDATE temp_ncd t
SET liver_section_populated = 1
WHERE EXISTS (
    SELECT 1 FROM temp_obs o
    WHERE o.encounter_id = t.encounter_id
    AND o.value_coded IN (
        @liver_hepatitis_b,
        @liver_hepatitis_c,
        @liver_hepatitis_e,
        @liver_ciel_168297,
        @liver_ciel_168298,
        @liver_pih_14911,
        @liver_ciel_168300,
        @liver_ciel_168301,
        @liver_ciel_149157,
        @liver_pih_15156,
        @liver_pih_14910,
        @liver_ciel_146184,
        @liver_ciel_143118
    )
);

-- Lung (concept_id)
UPDATE temp_ncd t
SET lung_section_populated = 1
WHERE EXISTS (
    SELECT 1 FROM temp_obs o
    WHERE o.encounter_id = t.encounter_id
    AND o.concept_id IN (
        @lung_pih_11972,
        @lung_pih_14587,
        @lung_pih_14610,
        @lung_pih_14617,
        @lung_pih_14620,
        @lung_pih_14812,
        @lung_pih_7397,
        @lung_pih_7399,
        @lung_pih_7405,
        @lung_copd_group
    )
);

-- Lung (value_coded)
UPDATE temp_ncd t
SET lung_section_populated = 1
WHERE EXISTS (
    SELECT 1 FROM temp_obs o
    WHERE o.encounter_id = t.encounter_id
    AND o.value_coded IN (
        @lung_asthma,
        @lung_pih_14601,
        @lung_copd,
        @lung_bronchiectasis,
        @lung_ciel_1295,
        @lung_ciel_121375,
        @lung_ciel_121011,
        @lung_ciel_143381
    )
);

-- Palliative Care (concept_id)
UPDATE temp_ncd t
SET palliative_care_section_populated = 1
WHERE EXISTS (
    SELECT 1 FROM temp_obs o
    WHERE o.encounter_id = t.encounter_id
    AND o.concept_id IN (
        @palliative_ciel_165310,
        @palliative_pih_14817,
        @palliative_pih_14859,
        @palliative_ciel_160379,
        @palliative_ciel_1788,
        @palliative_ciel_1887,
        @palliative_pih_14816
    )
);

-- Palliative Care (value_coded)
UPDATE temp_ncd t
SET palliative_care_section_populated = 1
WHERE EXISTS (
    SELECT 1 FROM temp_obs o
    WHERE o.encounter_id = t.encounter_id
    AND o.value_coded IN (
        @palliative_pih_14772,
        @palliative_ciel_155569,
        @palliative_ciel_145438,
        @palliative_ciel_116066,
        @palliative_ciel_134788,
        @palliative_ciel_116026,
        @palliative_ciel_133328,
        @palliative_pih_14771,
        @concept_other
    )
);

-- Sickle Cell (concept_id)
UPDATE temp_ncd t
SET sickle_cell_section_populated = 1
WHERE EXISTS (
    SELECT 1 FROM temp_obs o
    WHERE o.encounter_id = t.encounter_id
    AND o.concept_id IN (
        @sc_pih_14924,
        @sc_ciel_168730,
        @sc_pih_14858,
        @sc_pih_14872,
        @sc_pih_15162,
        @sc_pih_14826
    )
);

-- Sickle Cell (value_coded)
UPDATE temp_ncd t
SET sickle_cell_section_populated = 1
WHERE EXISTS (
    SELECT 1 FROM temp_obs o
    WHERE o.encounter_id = t.encounter_id
    AND o.value_coded IN (
        @sc_sickle_cell_disease,
        @sc_sickle_cell_crisis,
        @sc_sickle_cell_trait,
        @sc_complications,
        @sc_hemoglobin_s,
        @sc_painful_crisis,
        @sc_acute_chest_syndrome
    )
);



-- The ascending/descending indexes are calculated ordering on the encounter date
-- new temp tables are used to build them and then joined into the main temp table.
### index ascending
drop temporary table if exists temp_visit_index_asc;
CREATE TEMPORARY TABLE temp_visit_index_asc
(
    SELECT
            patient_id,
            encounter_datetime,
            encounter_id,
            index_asc
FROM (SELECT
            @r:= IF(@u = patient_id, @r + 1,1) index_asc,
            encounter_datetime,
            encounter_id,
            patient_id,
            @u:= patient_id
      FROM temp_ncd,
                    (SELECT @r:= 1) AS r,
                    (SELECT @u:= 0) AS u
            ORDER BY patient_id, encounter_datetime ASC, encounter_id ASC
        ) index_ascending );
CREATE INDEX tvia_e ON temp_visit_index_asc(encounter_id);
update temp_ncd t
inner join temp_visit_index_asc tvia on tvia.encounter_id = t.encounter_id
set t.index_asc = tvia.index_asc;

drop temporary table if exists temp_visit_index_desc;
CREATE TEMPORARY TABLE temp_visit_index_desc
(
    SELECT
            patient_id,
            encounter_datetime,
            encounter_id,
            index_desc
FROM (SELECT
            @r:= IF(@u = patient_id, @r + 1,1) index_desc,
            encounter_datetime,
            encounter_id,
            patient_id,
            @u:= patient_id
      FROM temp_ncd,
                    (SELECT @r:= 1) AS r,
                    (SELECT @u:= 0) AS u
            ORDER BY patient_id, encounter_datetime DESC, encounter_id DESC
        ) index_descending );
       
 CREATE INDEX tvid_e ON temp_visit_index_desc(encounter_id);      
update temp_ncd t
inner join temp_visit_index_desc tvid on tvid.encounter_id = t.encounter_id
set t.index_desc = tvid.index_desc;

select
if(@partition REGEXP '^[0-9]+$' = 1,concat(@partition,'-',patient_id),patient_id) "patient_id",
emr_id,
if(@partition REGEXP '^[0-9]+$' = 1,concat(@partition,'-',encounter_id),encounter_id) "encounter_id",
encounter_datetime,
datetime_entered,
if(@partition REGEXP '^[0-9]+$' = 1,concat(@partition,'-',visit_id),visit_id) "visit_id",
if(@partition REGEXP '^[0-9]+$' = 1,concat(@partition,'-',ncd_program_id),ncd_program_id) "ncd_program_id",
provider,
user_entered,
encounter_location,
encounter_type,
visit_type,                  
care_household,                    
vulnerable,                          
education_level,                
literacy_level,             
employment_status,              
referred_from,                   
other_referral,                   
social_support,
social_support_type,
other_social_support,
missed_school,
days_lost_schooling,
hiv,
risk_factors,
comorbidities,
bp_systolic,
bp_diastolic,
glucose_fingerstick,
fbg_level,
rbg_level,
bmi,
obesity,
number_hospitalizations_since_visit,          
number_hospitalizations_for_ncds,
ncd_diagnoses_caused_hospitalization_1,
number_days_hospitalization_1,
discharge_date_hospitalization_1,
outcome_hospitalization_1,
ncd_diagnoses_caused_hospitalization_2,
number_days_hospitalization_2,
discharge_date_hospitalization_2,
outcome_hospitalization_2,
ncd_diagnoses_caused_hospitalization_3,
number_days_hospitalization_3,
discharge_date_hospitalization_3,
outcome_hospitalization_3,
diabetes,
hypertension,
heart_failure,
cardiomyopathy,
chronic_lung_disease,
chronic_kidney_disease,
liver_cirrhosis_hepb,
palliative_care,
sickle_cell,
other_ncd,
diabetes_onset_date,
hypertension_onset_date,
heart_failure_onset_date,
chronic_lung_disease_onset_date,
chronic_kidney_disease_onset_date,
liver_cirrhosis_hepb_onset_date,
palliative_care_onset_date,
sickle_cell_onset_date,
other_ncd_onset_date,
treatment_with_hydroxyurea,
reason_no_hydroxyurea,
diabetes_type,
diabetes_control,
diabetes_on_insulin,
diabetes_home_glucometer,
diabetes_complications,
lab_order_hba1c,
hypertension_type,
hypertension_stage,
hypertension_controlled,
rheumatic_heart_disease,
congenital_heart_disease,
nyha_classification,
lung_disease_type,
on_saba,
on_oral_salbutamol,
on_steroid_inhaler,
ckd_stage,
ckd_controlled,
liver_disease_controlled,
on_hepatitis_b_treatment,
sickle_cell_type,
sickle_cell_complications,
next_appointment_date,
disposition,
transfer_site,
echocardiogram_findings,
on_ace_inhibitor,
on_beta_blocker,
secondary_antibiotic_prophylaxis,
referred_to_surgery_for_heart_failure,
cardiac_surgery_scheduled,
type_cardiac_surgery,
cardiac_surgery_performed,
cardiac_surgery_performed_date,
scd_penicillin_treatment,
scd_folic_acid_treatment,
transfusion_past_12_months,
transfusion_date,
asthma_severity,
nighttime_waking_asthma,
symptoms_2x_week_asthma,
inhaler_for_symptoms_2x_week_asthma,
activity_limitation_asthma,
asthma_control_GINA,
on_esophageal_varices_prophylaxis,
echocardiogram_date,
lab_tests_ordered,
diabetes_section_populated,
heart_failure_section_populated,
hypertension_section_populated,
kidney_section_populated,
liver_section_populated,
lung_section_populated,
palliative_care_section_populated,
sickle_cell_section_populated,
index_asc,
index_desc
from temp_ncd 
order by patient_id, encounter_datetime;
