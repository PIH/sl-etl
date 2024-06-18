drop table if exists ncd_monthly_summary_staging;
create table ncd_monthly_summary_staging
(emr_id varchar(20),
gender varchar(50),
dob date,
date_enrolled date,
date_completed date, 
outcome varchar(255),
latest_ncd_encounter_id varchar(50),
latest_ncd_encounter_datetime datetime,
ever_missed_school bit,
latest_days_lost_schooling_this_quarter float,
total_days_lost_schooling_this_quarter float,                   
social_support_this_quarter bit,
on_insulin_latest_encounter bit,
home_glucometer bit,
latest_a1c_test_date datetime,
latest_a1c_result varchar(255),
latest_echocardiogram_date date,
cardiomyopathy bit, 
on_beta_blocker bit,
on_ace_inhibitor bit,
secondary_antibiotic_prophylaxis bit,
latest_inr_datetime datetime,
latest_warfarin_prescription_datetime datetime,
latest_nyha_classification varchar(255),
latest_referred_to_surgery_datetime datetime,
on_hydroxurea_latest_visit bit,
latest_penicillen_prescription_datetime datetime,
latest_folic_acid_prescription_datetime datetime,
latest_transfusion_date date,
latest_number_hospitalizations_last_12_months float,
latest_number_hospitalizations_datetime datetime,
latest_on_saba_datetime datetime,
latest_on_oral_salbutamol_datetime datetime,
latest_on_steroid_inhaler_datetime datetime,
nighttime_waking_asthma bit,
asthma_control_GINA varchar(255),
latest_APRI_datetime datetime,
latest_HBsAg_datetime datetime,
latest_esophageal_varices_prophylaxis_datetime datetime,
latest_electrolytes_panel_datetime datetime,
latest_diastolic_bp float,
latest_systolic_bp float,
latest_seizure_frequency_datetime datetime,
latest_seizure_frequency float,
latest_anti_epilepsy_prescription_datetime datetime,
last_diabetes_type varchar(255), 
type_1_diabetes bit,
type_2_diabetes bit,
gestational_diabetes bit,
diabetes bit,
hypertension bit,
heart_failure bit,
chronic_lung_disease bit,
chronic_kidney_disease bit,
liver_disease bit,
palliative_care bit,
sickle_cell bit,
rheumatic_heart_disease bit,
congenital_heart_disease bit,
first_day_of_quarter date,
reporting_date date);

-- create list of monthends
drop table if exists #month_ends;
select distinct LastDayOfMonth as reporting_date 
into #month_ends from Dim_Date dd 
where LastDayOfMonth >= '2023-01-01'
and LastDayOfMonth <= GETDATE() 
;

-- enter a row for every month-end the patient was active in the program
insert into ncd_monthly_summary_staging
	(emr_id,
	date_enrolled,
	date_completed, 
	outcome,
	reporting_date)
select
	np.emr_id,
	np.date_enrolled,
	np.date_completed, 
	np.final_program_status,
	r.reporting_date
from ncd_program np, #month_ends r
where (YEAR(np.date_enrolled) <= YEAR(reporting_date))
		and (MONTH(np.date_enrolled) <= MONTH(reporting_date))   
and (date_completed is null or 
	((YEAR(np.date_completed) >= YEAR(reporting_date))
		and (MONTH(np.date_completed) >= MONTH(reporting_date))))   
;

update t 
set t.first_day_of_quarter = 
	(select max(FirstDayOfQuarter) from Dim_Date d 
	where d.FirstDayOfQuarter < t.reporting_date)
from ncd_monthly_summary_staging t;

update t 
set latest_ncd_encounter_id = e.encounter_id,
	latest_ncd_encounter_datetime = e.encounter_datetime
from ncd_monthly_summary_staging t
inner join ncd_encounter e on e.encounter_id = 
	(select top 1 e2.encounter_id from ncd_encounter e2
	where e2.emr_id = t.emr_id
	and e2.encounter_datetime <= t.reporting_date)
;	

-- data from ncd_patient
update t 
set t.diabetes = e.diabetes,
	t.hypertension = e.hypertension,
	t.heart_failure = e.heart_failure,
	t.chronic_lung_disease = e.chronic_lung_disease,
	t.liver_disease = e.liver_cirrhosis_hepb,
	t.palliative_care = e.palliative_care,
	t.sickle_cell = e.sickle_cell,
	t.rheumatic_heart_disease = e.rheumatic_heart_disease,
	t.congenital_heart_disease = e.congenital_heart_disease,
	t.cardiomyopathy = e.cardiomyopathy
from ncd_monthly_summary_staging t
inner join ncd_patient e on e.emr_id = t.emr_id;

-- data from latest ncd_encounter
update t 
set t.diabetes = e.diabetes,
	t.hypertension = e.hypertension,
	t.heart_failure = e.heart_failure,
	t.chronic_lung_disease = e.chronic_lung_disease,
	t.liver_disease = e.liver_cirrhosis_hepb,
	t.palliative_care = e.palliative_care,
	t.sickle_cell = e.sickle_cell,
	t.rheumatic_heart_disease = e.rheumatic_heart_disease,
	t.congenital_heart_disease = e.congenital_heart_disease,
	t.on_beta_blocker = iif(e.on_beta_blocker = 'Yes',1,null),
	t.on_ace_inhibitor = iif(e.on_ace_inhibitor = 'Yes',1,null),
	t.secondary_antibiotic_prophylaxis = e.secondary_antibiotic_prophylaxis,
	t.latest_nyha_classification = e.nyha_classification,
	t.on_hydroxurea_latest_visit = e.treatment_with_hydroxyurea,
	t.nighttime_waking_asthma = iif(e.nighttime_waking_asthma = 'Yes',1,null),
	t.asthma_control_GINA = e.asthma_control_GINA
from ncd_monthly_summary_staging t
inner join ncd_encounter e on e.encounter_id = t.latest_ncd_encounter_id
;

-- diabetes types
update t 
set t.last_diabetes_type = e.diabetes_type
from ncd_monthly_summary_staging t
inner join ncd_encounter e on e.encounter_id = 
	(select top 1 e2.encounter_id from ncd_encounter e2
	where e2.emr_id = t.emr_id
	and e2.encounter_datetime <= t.reporting_date
	and e2.diabetes_type is not null
	order by encounter_datetime desc, encounter_id desc);

update t
set type_1_diabetes = iif(last_diabetes_type = 'Type 1 diabetes',1,null)
from ncd_monthly_summary_staging t;

update t
set type_2_diabetes = iif(last_diabetes_type = 'Type 2 diabetes',1,null)
from ncd_monthly_summary_staging t;

update t
set gestational_diabetes = iif(last_diabetes_type = 'Gestational diabetes',1,null)
from ncd_monthly_summary_staging t;

-- missed school
update t 
set t.ever_missed_school =  1
from ncd_monthly_summary_staging t
where EXISTS 
	(select 1 from ncd_encounter e
	where e.emr_id = t.emr_id
	and e.encounter_datetime <= t.reporting_date
	and e.missed_school = 1);

-- days lost schooling 
update t 
set t.latest_days_lost_schooling_this_quarter = e.days_lost_schooling
from ncd_monthly_summary_staging t
inner join ncd_encounter e on e.encounter_id = 
	(select top 1 e2.encounter_id from ncd_encounter e2
	where e2.emr_id = t.emr_id
	and e2.encounter_datetime <= t.reporting_date
	and e2.days_lost_schooling is not null
	order by encounter_datetime desc, encounter_id desc);

update t
set t.total_days_lost_schooling_this_quarter =
	(select SUM(days_lost_schooling) from ncd_encounter e 
	where e.emr_id = t.emr_id
	and e.encounter_datetime <= t.reporting_date
	and e.encounter_datetime >= first_day_of_quarter)
from ncd_monthly_summary_staging t;

-- social support
update t 
set t.social_support_this_quarter =  1
from ncd_monthly_summary_staging t
where EXISTS 
	(select 1 from ncd_encounter e
	where e.emr_id = t.emr_id
	and e.encounter_datetime <= t.reporting_date
	and e.encounter_datetime >= first_day_of_quarter
	and e.social_support = 1);

-- on_insulin_latest_encounter
update t 
set t.on_insulin_latest_encounter = 1
from ncd_monthly_summary_staging t
where EXISTS 
	(select 1 from all_medications_prescribed m
	where m.encounter_id = t.latest_ncd_encounter_id
	and m.order_drug in
	('Insulin, Solution for injection, Glargine, 100IU/mL, 3mL prefilled pen (Lantus Solostar)',
	'Insulin, Solution for injection, Glulsine, 100 IU/mL, 3mL prefilled pen (Apidra Solostar)',
	'Insulin, Solution for injection, Neutral human, 70/30 (Mixtard), 100IU/mL, 10mL vial',
	'Insulin, Solution for injection, Neutral human, 70/30 (Mixtard), 100IU/mL, 3mL prefilled pen',
	'Insulin, Solution for injection, Neutral human, Regular (Rapid-Acting), 100IU/mL, 10mL vial'));

-- home glucometer
update t 
set t.home_glucometer =  1
from ncd_monthly_summary_staging t
where EXISTS 
	(select 1 from ncd_encounter e
	where e.emr_id = t.emr_id
	and e.encounter_datetime <= t.reporting_date
	and e.diabetes_home_glucometer = 1);

-- A1C
update t 
set t.latest_a1c_test_date = e.specimen_collection_date,
	t.latest_a1c_result = e.result
from ncd_monthly_summary_staging t
inner join labs_order_results e on e.encounter_id = 
	(select top 1 e2.encounter_id from labs_order_results e2
	where (e2.wellbody_emr_id = t.emr_id or e2.kgh_emr_id = t.emr_id)
	and e2.specimen_collection_date <= t.reporting_date
	and e2.test = 'HbA1c'
	order by specimen_collection_date desc, encounter_id desc);

-- echocardiogram
update t
set t.latest_echocardiogram_date =
	(select MAX(echocardiogram_datetime) from ncd_encounter e 
	where e.emr_id = t.emr_id
	and e.encounter_datetime <= t.reporting_date)
from ncd_monthly_summary_staging t;

-- INR
update t 
set t.latest_inr_datetime = e.specimen_collection_date
from ncd_monthly_summary_staging t
inner join labs_order_results e on e.encounter_id = 
	(select top 1 e2.encounter_id from labs_order_results e2
	where (e2.wellbody_emr_id = t.emr_id or e2.kgh_emr_id = t.emr_id)
	and e2.specimen_collection_date <= t.reporting_date
	and e2.test = 'International Normalized Ratio'
	order by specimen_collection_date desc, encounter_id desc);

-- Warfarin
update t 
set t.latest_warfarin_prescription_datetime = m.order_date_activated
from ncd_monthly_summary_staging t
inner join all_medications_prescribed m on m.encounter_id = 
	(select top 1 m2.encounter_id from all_medications_prescribed m2
	where m2.emr_id = t.emr_id
	and m2.order_date_activated <= t.reporting_date
	and m2.order_drug = 'Warfarin sodium'
	order by order_date_activated desc, encounter_id desc);

-- referred to surgery
update t 
set latest_referred_to_surgery_datetime = e.encounter_datetime
from ncd_monthly_summary_staging t
inner join ncd_encounter e on e.encounter_id = 
	(select top 1 e2.encounter_id from ncd_encounter e2
	where e2.emr_id = t.emr_id
	and e2.encounter_datetime <= t.reporting_date
	and e2.referred_to_surgery_for_heart_failure is not null);

-- penicillen
update t 
set t.latest_penicillen_prescription_datetime = m.order_date_activated
from ncd_monthly_summary_staging t
inner join all_medications_prescribed m on m.encounter_id = 
	(select top 1 m2.encounter_id from all_medications_prescribed m2
	where m2.emr_id = t.emr_id
	and m2.order_date_activated <= t.reporting_date
	and m2.order_drug in (
	'Benzathine benzylpenicillin, Powder for solution for injection, 2.4 MIU vial',
	'Benzylpenicillin procaine, Powder for solution for injection, 4 MIU vial',
	'Phenoxymethylpenicillin (Penicillin V), 250mg tablet')	
	order by order_date_activated desc, encounter_id desc);

-- folic acid
update t 
set t.latest_folic_acid_prescription_datetime = m.order_date_activated
from ncd_monthly_summary_staging t
inner join all_medications_prescribed m on m.encounter_id = 
	(select top 1 m2.encounter_id from all_medications_prescribed m2
	where m2.emr_id = t.emr_id
	and m2.order_date_activated <= t.reporting_date
	and m2.order_drug in (
	'Folic acid',
	'Ferrous sulphate + Folic acid')
	order by order_date_activated desc, encounter_id desc);

 -- transfusion date

update t
set t.latest_transfusion_date =
	(select MAX(transfusion_date) from ncd_encounter e 
	where e.emr_id = t.emr_id
	and e.encounter_datetime <= t.reporting_date)
from ncd_monthly_summary_staging t;

-- number hospitalizations
update t 
set latest_number_hospitalizations_last_12_months = e.number_hospitalizations_last_12_months,
	latest_number_hospitalizations_datetime = e.encounter_datetime
from ncd_monthly_summary_staging t
inner join ncd_encounter e on e.encounter_id = 
	(select top 1 e2.encounter_id from ncd_encounter e2
	where e2.emr_id = t.emr_id
	and e2.encounter_datetime <= t.reporting_date
	and e2.number_hospitalizations_last_12_months is not null);

-- on saba
update t 
set latest_on_saba_datetime = e.encounter_datetime
from ncd_monthly_summary_staging t
inner join ncd_encounter e on e.encounter_id = 
	(select top 1 e2.encounter_id from ncd_encounter e2
	where e2.emr_id = t.emr_id
	and e2.encounter_datetime <= t.reporting_date
	and e2.on_saba is not null);

-- latest_on_oral_salbutamol_datetime - encounter datetime of latest time this option was checked (before reporting date)
update t 
set latest_on_oral_salbutamol_datetime = e.encounter_datetime
from ncd_monthly_summary_staging t
inner join ncd_encounter e on e.encounter_id = 
	(select top 1 e2.encounter_id from ncd_encounter e2
	where e2.emr_id = t.emr_id
	and e2.encounter_datetime <= t.reporting_date
	and e2.on_oral_salbutamol = 1);

-- on_steroid_inhaler
update t 
set latest_on_steroid_inhaler_datetime = e.encounter_datetime
from ncd_monthly_summary_staging t
inner join ncd_encounter e on e.encounter_id = 
	(select top 1 e2.encounter_id from ncd_encounter e2
	where e2.emr_id = t.emr_id
	and e2.encounter_datetime <= t.reporting_date
	and e2.on_steroid_inhaler = 1);

-- APRI
update t 
set t.latest_APRI_datetime = e.specimen_collection_date
from ncd_monthly_summary_staging t
inner join labs_order_results e on e.encounter_id = 
	(select top 1 e2.encounter_id from labs_order_results e2
	where (e2.wellbody_emr_id = t.emr_id or e2.kgh_emr_id = t.emr_id)
	and e2.specimen_collection_date <= t.reporting_date
	and e2.test = 'APRI score'
	order by specimen_collection_date desc, encounter_id desc);

-- latest HBsAg datetime
update t 
set t.latest_HBsAg_datetime = e.specimen_collection_date
from ncd_monthly_summary_staging t
inner join labs_order_results e on e.encounter_id = 
	(select top 1 e2.encounter_id from labs_order_results e2
	where (e2.wellbody_emr_id = t.emr_id or e2.kgh_emr_id = t.emr_id)
	and e2.specimen_collection_date <= t.reporting_date
	and e2.test = 'Hepatitis B surface antigen test'
	order by specimen_collection_date desc, encounter_id desc);

-- latest_esophageal_varices_prophylaxis_datetime
update t 
set latest_esophageal_varices_prophylaxis_datetime = e.encounter_datetime
from ncd_monthly_summary_staging t
inner join ncd_encounter e on e.encounter_id = 
	(select top 1 e2.encounter_id from ncd_encounter e2
	where e2.emr_id = t.emr_id
	and e2.encounter_datetime <= t.reporting_date
	and e2.on_esophageal_varices_prophylaxis = 'Yes');

-- latest electrolytes panel datetime
update t 
set t.latest_electrolytes_panel_datetime = e.order_datetime
from ncd_monthly_summary_staging t
inner join labs_order_report e on e.order_number = 
	(select top 1 e2.order_number from labs_order_report e2
	where (e2.wellbody_emr_id = t.emr_id or e2.kgh_emr_id = t.emr_id)
	and e2.order_datetime <= t.reporting_date
	and e2.orderable in ('SL i-STAT CG4+ panel',
		'SL i-STAT CHEM8+ panel')
	order by order_datetime desc, order_number desc);


-- latest BP
update t 
set latest_diastolic_bp = bp_diastolic,
	latest_systolic_bp = bp_systolic
from ncd_monthly_summary_staging t
inner join all_vitals e on e.encounter_id = 
	(select top 1 e2.encounter_id from all_vitals e2
	where e2.emr_id = t.emr_id
	and e2.encounter_datetime <= t.reporting_date
	and e2.bp_systolic is not null
	order by encounter_datetime desc, encounter_id desc);

update t 
set latest_seizure_frequency = seizure_frequency,
	latest_seizure_frequency_datetime = e.encounter_datetime
from ncd_monthly_summary_staging t
inner join mh_encounters e on e.encounter_id = 
	(select top 1 e2.encounter_id from mh_encounters e2
	where e2.emr_id = t.emr_id
	and e2.encounter_datetime <= t.reporting_date
	and e2.seizure_frequency is not null
	order by encounter_datetime desc, encounter_id desc);

update t 
set t.latest_anti_epilepsy_prescription_datetime = m.order_date_activated
from ncd_monthly_summary_staging t
inner join all_medications_prescribed m on m.encounter_id = 
	(select top 1 m2.encounter_id from all_medications_prescribed m2
	where m2.emr_id = t.emr_id
	and m2.order_date_activated <= t.reporting_date
	and m2.order_drug in (  --  NOTE: NEED LIST OF ANTI-EPILEPSY DRUGS
	'Gabapentin')	
	order by order_date_activated desc, encounter_id desc)
	
-- data from all_patients
update t 
set t.dob = p.dob,
	t.gender = p.gender
from ncd_monthly_summary_staging t
	inner join all_patients p on p.emr_id = t.emr_id

-- ------------------------------------------------------------------------------------
DROP TABLE IF EXISTS ncd_monthly_summary;
EXEC sp_rename 'ncd_monthly_summary_staging', 'ncd_monthly_summary';
