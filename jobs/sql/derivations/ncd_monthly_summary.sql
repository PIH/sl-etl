drop table if exists ncd_monthly_summary_staging;
create table ncd_monthly_summary_staging
(
    patient_id                                     varchar(50),
    emr_id                                         varchar(20),
    gender                                         varchar(50),
    birthdate                                            date,
    date_enrolled                                  date,
    date_completed                                 date,
    outcome                                        varchar(255),
    latest_ncd_encounter_id                        varchar(50),
    latest_ncd_encounter_datetime                  datetime,
    ever_missed_school_this_month                  bit,
    latest_days_lost_schooling_this_quarter        float,
    total_days_lost_schooling_this_quarter         float,
    social_support_this_quarter                    bit,
    on_insulin_latest_encounter                    bit,
    home_glucometer                                bit,
    latest_a1c_test_date                           datetime,
    latest_a1c_result                              varchar(255),
    latest_echocardiogram_date                     date,
    cardiomyopathy                                 bit,
    on_beta_blocker                                bit,
    on_ace_inhibitor                               bit,
    secondary_antibiotic_prophylaxis               bit,
    latest_inr_datetime                            datetime,
    latest_warfarin_prescription_datetime          datetime,
    latest_nyha_classification                     varchar(255),
    latest_referred_to_surgery_datetime            datetime,
    on_hydroxurea_latest_visit                     bit,
    latest_penicillen_prescription_datetime        datetime,
    latest_folic_acid_prescription_datetime        datetime,
    latest_transfusion_date                        date,
    latest_number_hospitalizations_last_12_months  float,
    latest_number_hospitalizations_datetime        datetime,
    latest_on_saba_datetime                        datetime,
    latest_on_oral_salbutamol_datetime             datetime,
    latest_on_steroid_inhaler_datetime             datetime,
    nighttime_waking_asthma                        bit,
    asthma_control_GINA                            varchar(255),
    latest_APRI_datetime                           datetime,
    latest_HBsAg_datetime                          datetime,
    latest_esophageal_varices_prophylaxis_datetime datetime,
    latest_electrolytes_panel_datetime             datetime,
    most_recent_bp_diastolic                            float,
    most_recent_bp_systolic                             float,
    latest_seizure_frequency_datetime              datetime,
    latest_seizure_frequency                       float,
    latest_anti_epilepsy_prescription_datetime     datetime,
    last_diabetes_type                             varchar(255),
    type_1_diabetes                                bit,
    type_2_diabetes                                bit,
    gestational_diabetes                           bit,
    diabetes                                       bit,
    hypertension                                   bit,
    heart_failure                                  bit,
    chronic_lung_disease                           bit,
    chronic_kidney_disease                         bit,
    liver_disease                                  bit,
    palliative_care                                bit,
    sickle_cell                                    bit,
    rheumatic_heart_disease                        bit,
    congenital_heart_disease                       bit,
    first_day_of_quarter                           date,
    reporting_date                                 date
);

-- create list of reporting_months (since 2023)
drop table if exists #reporting_months;
select distinct FirstDayOfQuarter as quarter_start_date, FirstDayOfMonth as month_start_date, LastDayOfMonth as month_end_date
into #reporting_months
from dim_date dd
where LastDayOfMonth >= '2023-01-01'
and LastDayOfMonth <= GETDATE()
;

-- enter a row for every month-end the patient was active in the program
-- if the patient had multiple qualifying enrollments, set date_enrolled to the most recent
insert into ncd_monthly_summary_staging (patient_id, emr_id, first_day_of_quarter, reporting_date, date_enrolled)
select  np.patient_id, np.emr_id, r.quarter_start_date, r.month_end_date, max(np.date_enrolled)
from    ncd_program np, #reporting_months r
where   np.date_enrolled <= r.month_end_date
and     (np.date_completed is null or np.date_completed >= r.month_start_date)
group by np.patient_id, np.emr_id, r.quarter_start_date, r.month_end_date
;

create index ncd_monthly_summary_staging_ei on ncd_monthly_summary_staging(patient_id);
create index ncd_monthly_summary_staging_c1 on ncd_monthly_summary_staging(patient_id, reporting_date);


-- if the patient had multiple qualifying enrollments, set date_completed associated with the date_enrolled, if completed during the given month
update s
set s.date_completed = (
    select max(p.date_completed)
    from ncd_program p
    where s.patient_id = p.patient_id
    and s.date_enrolled = p.date_enrolled
    and (YEAR(p.date_completed) = YEAR(s.reporting_date)) and (MONTH(p.date_completed) = MONTH(s.reporting_date))
)
from ncd_monthly_summary_staging s
;

-- if the patient had multiple qualifying enrollments, set outcome to the one associated with the enrollment chosen
update s
set s.outcome = (
    select p.final_program_status
    from ncd_program p
    where s.patient_id = p.patient_id
    and s.date_enrolled = p.date_enrolled
    and s.date_completed = p.date_completed
)
from ncd_monthly_summary_staging s
;

-- set latest ncd encounter before reporting date for each row
update t 
set latest_ncd_encounter_id = e.encounter_id,
	latest_ncd_encounter_datetime = e.encounter_datetime
from ncd_monthly_summary_staging t
inner join ncd_encounter e on e.encounter_id = (
    select top 1 e2.encounter_id from ncd_encounter e2
	where e2.patient_id = t.patient_id
	and cast(e2.encounter_datetime as DATE) <= t.reporting_date
    order by e2.encounter_datetime desc, e2.encounter_id desc
);

-- update data that is needed from the latest ncd encounter
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

-- update data needed from ncd_patient
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
inner join ncd_patient e on e.patient_id = t.patient_id;

-- update diabetes type from the last time that question was answered before the reporting date
update t 
set t.last_diabetes_type = e.diabetes_type
from ncd_monthly_summary_staging t
inner join ncd_encounter e on e.encounter_id = (
    select top 1 e2.encounter_id from ncd_encounter e2
	where e2.patient_id = t.patient_id
	and cast(e2.encounter_datetime as DATE) <= t.reporting_date
	and e2.diabetes_type is not null
	order by encounter_datetime desc, encounter_id desc
);

-- decode diabetes type into booleans
update t
set type_1_diabetes = iif(last_diabetes_type = 'Type 1 diabetes',1,null)
from ncd_monthly_summary_staging t;

update t
set type_2_diabetes = iif(last_diabetes_type = 'Type 2 diabetes',1,null)
from ncd_monthly_summary_staging t;

update t
set gestational_diabetes = iif(last_diabetes_type = 'Gestational diabetes',1,null)
from ncd_monthly_summary_staging t;

-- set missed school to true if it had ever been true during the reporting month
update t 
set t.ever_missed_school_this_month =  1
from ncd_monthly_summary_staging t
where EXISTS (
    select 1 from ncd_encounter e
	where e.patient_id = t.patient_id
	and year(e.encounter_datetime) = year(t.reporting_date)
	and month(e.encounter_datetime) = month(t.reporting_date)
	and e.missed_school = 1
);

insert into ncd_monthly_summary_staging (patient_id, emr_id, first_day_of_quarter, reporting_date, date_enrolled)
select  np.patient_id, np.emr_id, r.quarter_start_date, r.month_end_date, max(np.date_enrolled)
from    ncd_program np, #reporting_months r
where   np.date_enrolled <= r.month_end_date
and     (np.date_completed is null or np.date_completed >= r.month_start_date)
group by np.patient_id, np.emr_id, r.quarter_start_date, r.month_end_date;

-- days lost schooling 
drop table if exists #latest_days_lost_schooling;
select t.patient_id, t.reporting_date, max(e.encounter_datetime) max_encounter_datetime 
into #latest_days_lost_schooling
from ncd_monthly_summary_staging t
inner join ncd_encounter e on e.patient_id = t.patient_id
	and cast(e.encounter_datetime as DATE) <= t.reporting_date
    and e.encounter_datetime >= t.first_day_of_quarter
	and e.days_lost_schooling is not null
group by t.patient_id, t.reporting_date
;

create index latest_days_lost_schooling_c1 on #latest_days_lost_schooling(patient_id, reporting_date);

update t 
set  t.latest_days_lost_schooling_this_quarter = e.days_lost_schooling
from ncd_monthly_summary_staging t
inner join #latest_days_lost_schooling l on l.patient_id = t.patient_id 
	and l.reporting_date = t.reporting_date 
inner join ncd_encounter e on e.patient_id = t.patient_id 
	and e.encounter_datetime = l.max_encounter_datetime;

-- sum days lost schooling this quarter from the beginning of the quarter until the reporting date
update t
set t.total_days_lost_schooling_this_quarter = (
    select SUM(days_lost_schooling) from ncd_encounter e
	where e.patient_id = t.patient_id
	and cast(e.encounter_datetime as DATE) <= t.reporting_date
	and e.encounter_datetime >= t.first_day_of_quarter
)
from ncd_monthly_summary_staging t;

-- set update social_support_this_quarter to true if it had been checked since the beginning of the quarter to the reporting date
update t 
set t.social_support_this_quarter =  1
from ncd_monthly_summary_staging t
where EXISTS (
    select 1 from ncd_encounter e
	where e.patient_id = t.patient_id
	and cast(e.encounter_datetime as DATE) <= t.reporting_date
	and e.encounter_datetime >= first_day_of_quarter
	and e.social_support = 1
);

-- update on_insulin_latest_encounter based on whether insulin was prescribed (all_medications_prescribed) on the latest ncd encounter 
update t 
set t.on_insulin_latest_encounter = 1
from ncd_monthly_summary_staging t
where EXISTS (
    select 1 from all_medications_prescribed m
	where m.encounter_id = t.latest_ncd_encounter_id
	and m.order_drug in (
        'Insulin, lente',
        'Insulin (Mixtard) 70/30',
        'Rapid insulin',
        'Insulin glargine',
        'Insulin, zinc, human',
        'Insulin, human, regular',
        'Insulin, Isophane, human',
        'Insulin',
        'Insulin glulisine'
	)
);

-- set missed home_glucometer to true if it had ever been set before the reporting date
update t 
set t.home_glucometer =  1
from ncd_monthly_summary_staging t
where EXISTS (
    select 1 from ncd_encounter e
	where e.patient_id = t.patient_id
	and cast(e.encounter_datetime as DATE) <= t.reporting_date
	and e.diabetes_home_glucometer = 1
);

-- set a1c result and test date based on the last time there was a test result before the reporting date
update t 
set t.latest_a1c_test_date = e.specimen_collection_date,
	t.latest_a1c_result = e.result
from ncd_monthly_summary_staging t
inner join all_lab_results e on e.encounter_id = (
    select top 1 e2.encounter_id from all_lab_results e2
	where e2.patient_id= t.patient_id
	and cast(e2.specimen_collection_date as DATE) <= t.reporting_date
	and e2.test = 'HbA1c'
	order by e2.specimen_collection_date desc, e2.encounter_id desc
);

-- set latest_echocardiogram_date to the most recent echocardiogram date entered on encounters before the reporting date
update t
set t.latest_echocardiogram_date = (
    select MAX(echocardiogram_datetime) from ncd_encounter e
	where e.patient_id = t.patient_id
	and cast(e.encounter_datetime as DATE) <= t.reporting_date
)
from ncd_monthly_summary_staging t;

-- set latest_inr_datetime to the last time there was a test result before the reporting date
update t 
set t.latest_inr_datetime = e.specimen_collection_date
from ncd_monthly_summary_staging t
inner join all_lab_results e on e.encounter_id = (
    select top 1 e2.encounter_id from all_lab_results e2
	where e2.patient_id = t.patient_id
	and cast(e2.specimen_collection_date as DATE) <= t.reporting_date
	and e2.test = 'International Normalized Ratio'
	order by e2.specimen_collection_date desc, e2.encounter_id desc
);

-- set latest_warfarin_prescription_datetime to the latest date warfarin was prescribed (all_medications_prescribed)
update t 
set t.latest_warfarin_prescription_datetime = m.order_date_activated
from ncd_monthly_summary_staging t
inner join all_medications_prescribed m on m.encounter_id = (
    select top 1 m2.encounter_id from all_medications_prescribed m2
	where m2.patient_id = t.patient_id
	and cast(m2.order_date_activated as DATE) <= t.reporting_date
	and m2.order_drug in ('Warfarin sodium', 'Warfarin')
	order by m2.order_date_activated desc, m2.encounter_id desc
);

-- set latest_referred_to_surgery_datetime to the datetime the last time referred to surgery for heart failure was checked on an ncd encounter
update t 
set latest_referred_to_surgery_datetime = e.encounter_datetime
from ncd_monthly_summary_staging t
inner join ncd_encounter e on e.encounter_id = (
    select top 1 e2.encounter_id from ncd_encounter e2
	where e2.patient_id = t.patient_id
	and cast(e2.encounter_datetime as DATE) <= t.reporting_date
	and e2.referred_to_surgery_for_heart_failure is not null
);

-- set latest_penicillen_prescription_datetime to the latest date penicillen was prescribed (all_medications_prescribed) 
update t 
set t.latest_penicillen_prescription_datetime = m.order_date_activated
from ncd_monthly_summary_staging t
inner join all_medications_prescribed m on m.encounter_id = (
    select top 1 m2.encounter_id from all_medications_prescribed m2
	where m2.patient_id = t.patient_id
	and cast(m2.order_date_activated as DATE) <= t.reporting_date
	and m2.order_drug in (
        'Penicillin',
        'Phenoxymethylpenicillin',
        'Benzylpenicillin',
        'Benzathine penicillin',
        'Benzylpenicillin procaine',
        'Benzylpenicillin Sodium'
	)
	order by m2.order_date_activated desc, m2.encounter_id desc
);

--set latest_folic_acid_prescription_datetime to the latest date folic acid was prescribed (all_medications_prescribed) 
update t 
set t.latest_folic_acid_prescription_datetime = m.order_date_activated
from ncd_monthly_summary_staging t
inner join all_medications_prescribed m on m.encounter_id = (
    select top 1 m2.encounter_id from all_medications_prescribed m2
	where m2.patient_id = t.patient_id
	and cast(m2.order_date_activated as DATE) <= t.reporting_date
	and m2.order_drug in (
	    'Folic acid',
	    'Ferrous sulphate + Folic acid'
	)
	order by order_date_activated desc, encounter_id desc
);

-- -- set latest_transfusion_date to the most recent transfusion date entered on ncd encounters before the reporting date
update t
set t.latest_transfusion_date = (
    select MAX(transfusion_date) from ncd_encounter e
	where e.patient_id = t.patient_id
	and cast(e.encounter_datetime as DATE) <= t.reporting_date
)
from ncd_monthly_summary_staging t;

-- update number of hospitalizations column based on last time question was answered on ncd encounter before the reporting date 
update t 
set latest_number_hospitalizations_last_12_months = e.number_hospitalizations_last_12_months,
	latest_number_hospitalizations_datetime = e.encounter_datetime
from ncd_monthly_summary_staging t
inner join ncd_encounter e on e.encounter_id = (
    select top 1 e2.encounter_id from ncd_encounter e2
	where e2.patient_id = t.patient_id
	and cast(e2.encounter_datetime as DATE) <= t.reporting_date
	and e2.number_hospitalizations_last_12_months is not null
);

-- update latest_on_saba_datetime to latest time this option was checked on ncd encounter (before reporting date)
update t 
set latest_on_saba_datetime = e.encounter_datetime
from ncd_monthly_summary_staging t
inner join ncd_encounter e on e.encounter_id = (
    select top 1 e2.encounter_id from ncd_encounter e2
	where e2.patient_id = t.patient_id
	and cast(e2.encounter_datetime as DATE) <= t.reporting_date
	and e2.on_saba is not null
);

-- update latest_on_oral_salbutamol_datetime to latest time this option was checked on ncd encounter (before reporting date)
update t 
set latest_on_oral_salbutamol_datetime = e.encounter_datetime
from ncd_monthly_summary_staging t
inner join ncd_encounter e on e.encounter_id = (
    select top 1 e2.encounter_id from ncd_encounter e2
	where e2.patient_id = t.patient_id
	and cast(e2.encounter_datetime as DATE) <= t.reporting_date
	and e2.on_oral_salbutamol = 1
);

-- update latest_on_steroid_inhaler_datetime to latest time this option was checked on ncd encounter (before reporting date)
update t 
set latest_on_steroid_inhaler_datetime = e.encounter_datetime
from ncd_monthly_summary_staging t
inner join ncd_encounter e on e.encounter_id = (
    select top 1 e2.encounter_id from ncd_encounter e2
	where e2.patient_id = t.patient_id
	and cast(e2.encounter_datetime as DATE) <= t.reporting_date
	and e2.on_steroid_inhaler = 1
);

-- set latest_APRI_datetime to the last time there was a test result before the reporting date
update t 
set t.latest_APRI_datetime = e.specimen_collection_date
from ncd_monthly_summary_staging t
inner join all_lab_results e on e.encounter_id = (
    select top 1 e2.encounter_id from all_lab_results e2
	where e2.patient_id = t.patient_id
	and cast(e2.specimen_collection_date as DATE) <= t.reporting_date
	and e2.test = 'APRI score'
	order by e2.specimen_collection_date desc, e2.encounter_id desc
);

-- set latest_HBsAg_datetime to the last time there was a test result before the reporting date
update t 
set t.latest_HBsAg_datetime = e.specimen_collection_date
from ncd_monthly_summary_staging t
inner join all_lab_results e on e.encounter_id = (
    select top 1 e2.encounter_id from all_lab_results e2
	where e2.patient_id = t.patient_id
	and cast(e2.specimen_collection_date as DATE) <= t.reporting_date
	and e2.test = 'Hepatitis B surface antigen test'
	order by e2.specimen_collection_date desc, e2.encounter_id desc
);

-- update latest_esophageal_varices_prophylaxis_datetime to latest time this was answered yes on ncd encounter (before reporting date)
update t 
set latest_esophageal_varices_prophylaxis_datetime = e.encounter_datetime
from ncd_monthly_summary_staging t
inner join ncd_encounter e on e.encounter_id = (
    select top 1 e2.encounter_id from ncd_encounter e2
	where e2.patient_id = t.patient_id
	and cast(e2.encounter_datetime as DATE) <= t.reporting_date
	and e2.on_esophageal_varices_prophylaxis = 'Yes'
);

-- set latest_electrolytes_panel_datetime to the last time the electrolytes (i-Stat) panel was ordered before the reporting date
update t 
set t.latest_electrolytes_panel_datetime = e.order_datetime
from ncd_monthly_summary_staging t
inner join all_lab_orders e on e.order_number = (
    select top 1 e2.order_number from all_lab_orders e2
	where e2.patient_id = t.patient_id
	and cast(e2.order_datetime as DATE) <= t.reporting_date
	and e2.orderable in (
	    'SL i-STAT CG4+ panel',
		'SL i-STAT CHEM8+ panel'
	)
	order by e2.order_datetime desc, e2.order_number desc
);

-- update the BP info to the values collected (all_vitals) most recently before the reporting date
update t 
set most_recent_bp_diastolic = bp_diastolic,
	most_recent_bp_systolic = bp_systolic
from ncd_monthly_summary_staging t
inner join all_vitals e on e.encounter_id = (
    select top 1 e2.encounter_id from all_vitals e2
	where e2.patient_id = t.patient_id
	and cast(e2.encounter_datetime as DATE) <= t.reporting_date
	and e2.bp_systolic is not null
	order by e2.encounter_datetime desc, e2.encounter_id desc
);

-- update seizure frequency columns based on last time that question was answered on mh encounter before the reporting date 
update t 
set latest_seizure_frequency = seizure_frequency,
	latest_seizure_frequency_datetime = e.encounter_datetime
from ncd_monthly_summary_staging t
inner join mh_encounter e on e.encounter_id = (
    select top 1 e2.encounter_id from mh_encounter e2
	where e2.patient_id = t.patient_id
	and cast(e2.encounter_datetime as DATE) <= t.reporting_date
	and e2.seizure_frequency is not null
	order by e2.encounter_datetime desc, e2.encounter_id desc
);

-- set latest_anti_epilepsy_prescription_datetime to the latest date an anti epilepsy drug was prescribed (all_medications_prescribed)
-- NOTE:  NEED LIST OF DRUGS 
update t 
set t.latest_anti_epilepsy_prescription_datetime = m.order_date_activated
from ncd_monthly_summary_staging t
inner join all_medications_prescribed m on m.encounter_id = (
    select top 1 m2.encounter_id from all_medications_prescribed m2
	where m2.patient_id = t.patient_id
	and cast(m2.order_date_activated as DATE) <= t.reporting_date
	and m2.order_drug in (  --  NOTE: NEED LIST OF ANTI-EPILEPSY DRUGS
	    'Gabapentin'
	)
	order by m2.order_date_activated desc, m2.encounter_id desc
);
	
-- birthdate and gender data from all_patients
update t 
set t.birthdate = p.birthdate,
	t.gender = p.gender
from ncd_monthly_summary_staging t
inner join all_patients p on p.patient_id = t.patient_id
;

-- ------------------------------------------------------------------------------------
DROP TABLE IF EXISTS ncd_monthly_summary;
EXEC sp_rename 'ncd_monthly_summary_staging', 'ncd_monthly_summary';
