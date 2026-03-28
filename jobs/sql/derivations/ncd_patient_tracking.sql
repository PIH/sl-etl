drop table if exists ncd_patient_tracking_staging;
select
p.patient_id,
p.emr_id,
concat(name, ' ', family_name) "name", 
datediff(year, p.birthdate, GETDATE()) "current_age", 
full_address,
district,
telephone_number,
primary_contact_name,
primary_contact_number,
local_contact_name,
local_contact_number,
referred_from,
all_conditions,
most_recent_visit_date,
first_ncd_visit_date,
next_appointment_date,
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
date_enrolled,
DATEDIFF(day, COALESCE(first_ncd_visit_date, date_enrolled), GETDATE()) "days_since_first_visit",
DATEDIFF(day, COALESCE(most_recent_visit_date, date_enrolled), GETDATE()) "days_since_last_visit",
DATEDIFF(day, COALESCE(next_appointment_date, date_enrolled, n.first_ncd_visit_date), GETDATE()) "days_late_for_appointment"
into ncd_patient_tracking_staging
from all_patients p 
inner join ncd_patient n on n.patient_id = p.patient_id 
	and n.calculated_reporting_outcome = 'Lost to followup';

alter table ncd_patient_tracking_staging
add days_since_ltfu int,
	chd_diagnosis   bit,
	rhd_diagnosis   bit,
	dhd_diagnosis   bit,
	hhd_diagnosis   bit;

update n 
set days_since_ltfu = 
case
	when (days_since_last_visit - 180) > (days_late_for_appointment - 90) then (days_since_last_visit - 180)
	else (days_late_for_appointment - 90)
end
from ncd_patient_tracking_staging n;

update n 
set n.chd_diagnosis = 1
from ncd_patient_tracking_staging n
inner join all_diagnosis d on d.patient_id = n.patient_id
	and d.diagnosis_coded_en = 'Congenital heart disease';

update n 
set n.rhd_diagnosis = 1
from ncd_patient_tracking_staging n
inner join all_diagnosis d on d.patient_id = n.patient_id
	and d.diagnosis_coded_en = 'Rheumatic heart disease';

update n 
set n.hhd_diagnosis = 1
from ncd_patient_tracking_staging n
inner join all_diagnosis d on d.patient_id = n.patient_id
	and d.diagnosis_coded_en = 'Hypertensive heart disease';

update n 
set n.dhd_diagnosis = 1
from ncd_patient_tracking_staging n
inner join all_diagnosis d on d.patient_id = n.patient_id
	and d.diagnosis_coded_en = 'Degenerative heart disease';

DROP TABLE IF EXISTS ncd_patient_tracking;
EXEC sp_rename 'ncd_patient_tracking_staging', 'ncd_patient_tracking';
