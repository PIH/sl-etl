select encounter_type_id INTO @NCDInitial FROM encounter_type where uuid = 'ae06d311-1866-455b-8a64-126a9bd74171'; 
select encounter_type_id INTO @NCDFollowup FROM encounter_type where uuid = '5cbfd6a2-92d9-4ad0-b526-9d29bfe1d10c'; 
set @locale = global_property_value('default_locale', 'en');
set @partition = '${partitionNum}';

drop temporary table if exists temp_ncd;
create temporary table temp_ncd
(
 patient_id                        int(11),      
 emr_id                            varchar(50),  
 encounter_id                      int(11),      
 encounter_datetime                datetime,     
 date_created                      datetime,     
 visit_id                          int(11),      
 provider                          varchar(255), 
 creator_user_id                   int(11),      
 creator                           varchar(255), 
 encounter_location_id             int(11),      
 encounter_location                varchar(255), 
 encounter_type_id                 int(11),      
 encounter_type                    varchar(255), 
 social_support                    bit,          
 social_support_type               varchar(255), 
 missed_school                     bit,          
 days_lost_schooling               double,       
 hiv                               varchar(255), 
 comorbidities                     varchar(255), 
 bp_systolic                       double,       
 bp_diastolic                      double,       
 glucose_fingerstick               varchar(255), 
 bmi                               varchar(255), 
 obesity                           bit,          
 hospitalizations_since_last_visit varchar(255), 
 number_hospitalizations           double,       
 discharge_date                    datetime,     
 number_days_hospitalized          double,       
 diabetes                          bit,          
 hypertension                      bit,          
 heart_failure                     bit,          
 chronic_lung_disease              bit,          
 chronic_kidney_disease            bit,           
 liver_cirrhosis_hepb              bit,          
 palliative_care                   bit,          
 sickle_cell                       bit,          
 other_ncd                         bit,          
 diabetes_type                     varchar(255), 
 diabetes_indicators_obs_group     int(11),      
 diabetes_control                  varchar(255), 
 diabetes_on_insulin               bit,          
 hypertension_type                 varchar(255), 
 hypertension_stage                varchar(255), 
 hypertension_indicators_obs_group int(11),      
 hypertension_controlled           varchar(255), 
 rheumatic_heart_disease           bit,          
 congenital_heart_disease          bit,          
 nyha_classification               varchar(255), 
 lung_disease_type                 text,         
 ckd_stage                         varchar(255), 
 ckd_indicators_obs_group          int(11),      
 ckd_controlled                    varchar(255), 
 liver_indicators_obs_group        int(11),      
 liver_disease_controlled          varchar(255), 
 sickle_cell_type                  varchar(255), 
 next_appointment_date             date,     
 disposition                       varchar(255), 
 transfer_site                     varchar(255),
 index_asc                         int, 
 index_desc                        int
);
	
insert into temp_ncd
	(patient_id,
	encounter_id,
	encounter_datetime,
	date_created,
	visit_id,
	creator_user_id,
	encounter_location_id,
	encounter_type_id)
select 
	patient_id,
	encounter_id,
	e.encounter_datetime ,
	e.date_created ,
	e.visit_id ,
	e.creator ,
	e.location_id ,
	e.encounter_type 
from encounter e
where e.voided = 0
and e.encounter_type in (@NCDInitial,@NCDFollowup)
and (DATE(encounter_datetime) >=  date(@startDate) or @startDate is null)
and (DATE(encounter_datetime) <=  date(@endDate) or @endDate is null)
;	

-- encounter level columns
update temp_ncd
set creator = person_name_of_user(creator_user_id);

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
from obs o
inner join temp_ncd t on t.encounter_id = o.encounter_id
where o.voided = 0 
;

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
set social_support = value_coded_as_boolean(obs_id_from_temp(encounter_id, 'PIH','14443',0));

update temp_ncd t
set social_support_type = obs_value_coded_list_from_temp(encounter_id, 'PIH','2156',@locale);

update temp_ncd t
set missed_school = value_coded_as_boolean(obs_id_from_temp(encounter_id, 'PIH','5629',0));

update temp_ncd t
set days_lost_schooling = obs_value_numeric_from_temp(encounter_id, 'PIH','14446');

update temp_ncd t
set hiv = obs_value_coded_list_from_temp(encounter_id, 'PIH','1169',@locale);

update temp_ncd t
set comorbidities = obs_value_coded_list_from_temp(encounter_id, 'PIH','12976',@locale);

update temp_ncd t
set bp_systolic = obs_value_numeric_from_temp(encounter_id, 'PIH','5085');

update temp_ncd t
set bp_diastolic = obs_value_numeric_from_temp(encounter_id, 'PIH','5086');

set @yes = concept_name(concept_from_mapping('PIH','YES'),@locale);
update temp_ncd t
set glucose_fingerstick = 
	if(obs_single_value_coded_from_temp(encounter_id, 'PIH','6689','PIH','1065')=@yes, 'FBG',
		if(obs_single_value_coded_from_temp(encounter_id, 'PIH','6689','PIH','1066')=@yes, 'RBG',null));

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

update temp_ncd t
set hospitalizations_since_last_visit = obs_value_coded_list_from_temp(encounter_id, 'PIH','1715','en');

update temp_ncd t
set number_hospitalizations = obs_value_numeric_from_temp(encounter_id, 'PIH','12594');

update temp_ncd t
set discharge_date = obs_value_datetime_from_temp(encounter_id, 'PIH','3800');

update temp_ncd t
set number_days_hospitalized = obs_value_numeric_from_temp(encounter_id, 'PIH','2872');

update temp_ncd t
set diabetes = 
	if(obs_single_value_coded_from_temp(encounter_id, 'PIH','10529','PIH','3720')=@yes, 1,null);

update temp_ncd t
set hypertension = 
	if(obs_single_value_coded_from_temp(encounter_id, 'PIH','10529','PIH','903')=@yes, 1,null);

update temp_ncd t
set heart_failure = 
	if(obs_single_value_coded_from_temp(encounter_id, 'PIH','10529','PIH','3468')=@yes, 1,null);

update temp_ncd t
set chronic_lung_disease = 
	if(obs_single_value_coded_from_temp(encounter_id, 'PIH','10529','PIH','6768')=@yes, 1,null);

update temp_ncd t
set chronic_kidney_disease = 
	if(obs_single_value_coded_from_temp(encounter_id, 'PIH','10529','PIH','3699')=@yes, 1,null);

update temp_ncd t
set liver_cirrhosis_hepb = 
	if(obs_single_value_coded_from_temp(encounter_id, 'PIH','10529','PIH','3714')=@yes, 1,null);

update temp_ncd t
set palliative_care = 
	if(obs_single_value_coded_from_temp(encounter_id, 'PIH','10529','PIH','10359')=@yes, 1,null);

update temp_ncd t
set sickle_cell = 
	if(obs_single_value_coded_from_temp(encounter_id, 'PIH','10529','PIH','7908')=@yes, 1,null);

update temp_ncd t
set sickle_cell = 
	if(obs_single_value_coded_from_temp(encounter_id, 'PIH','10529','PIH','7908')=@yes, 1,null);

update temp_ncd t
set other_ncd = 
	if(obs_single_value_coded_from_temp(encounter_id, 'PIH','10529','PIH','5622')=@yes, 1,null);

update temp_ncd t
set diabetes_type = obs_value_coded_list_from_temp(encounter_id, 'PIH','1715',@locale);

update temp_ncd t
set diabetes_indicators_obs_group = obs_id_from_temp(encounter_id,'PIH','14469',0 );

update temp_ncd t
set  diabetes_control = obs_from_group_id_value_coded_list_from_temp(diabetes_indicators_obs_group, 'PIH','11506',@locale);

update temp_ncd t
set diabetes_on_insulin = value_coded_as_boolean(obs_id_from_temp(encounter_id, 'PIH','6756',0));

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

-- select obs_value_coded_list_from_temp(646965, 'PIH','12699',@locale);


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
set ckd_stage = obs_value_coded_list_from_temp(encounter_id, 'PIH','12501',@locale);

update temp_ncd t
set ckd_indicators_obs_group = obs_id_from_temp(encounter_id,'PIH','14717',0);

update temp_ncd t
set  ckd_controlled = obs_from_group_id_value_coded_list_from_temp(ckd_indicators_obs_group, 'PIH','11506',@locale);

update temp_ncd t
set liver_indicators_obs_group = obs_id_from_temp(encounter_id,'PIH','14827',0);

update temp_ncd t
set  liver_disease_controlled = obs_from_group_id_value_coded_list_from_temp(liver_indicators_obs_group, 'PIH','11506',@locale);

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
set transfer_site = obs_value_datetime_from_temp(encounter_id, 'PIH','14424');

update temp_ncd t
set transfer_site = obs_value_coded_list_from_temp(encounter_id, 'PIH','14424',@locale);

select
concat(@partition,"-",patient_id) patient_id,
emr_id,
concat(@partition,"-",encounter_id) encounter_id,
encounter_datetime,
date_created,
concat(@partition,"-",visit_id) visit_id,
provider,
creator,
encounter_location,
encounter_type,
social_support,
social_support_type,
missed_school,
days_lost_schooling,
hiv,
comorbidities,
bp_systolic,
bp_diastolic,
glucose_fingerstick,
bmi,
obesity,
hospitalizations_since_last_visit,
number_hospitalizations,
discharge_date,
number_days_hospitalized,
diabetes,
hypertension,
heart_failure,
chronic_lung_disease,
chronic_kidney_disease,
liver_cirrhosis_hepb,
palliative_care,
sickle_cell,
other_ncd,
diabetes_type,
diabetes_control,
diabetes_on_insulin,
hypertension_type,
hypertension_stage,
hypertension_controlled,
rheumatic_heart_disease,
congenital_heart_disease,
nyha_classification,
lung_disease_type,
ckd_stage,
ckd_controlled,
liver_disease_controlled,
sickle_cell_type,
next_appointment_date,
disposition,
transfer_site,
index_asc,
index_desc
from temp_ncd order by date_created desc;
