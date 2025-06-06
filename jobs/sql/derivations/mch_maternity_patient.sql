drop table if exists mch_maternity_patient_staging;
create table mch_maternity_patient_staging
(
emr_id varchar(50),
patient_id varchar(100),
most_recent_pregnancy_program_id varchar(50),
most_recent_date_enrolled date,
birthdate date,
currently_pregnant bit,
most_recent_gravida int,
most_recent_parity int,
most_recent_abortus int,
most_recent_living int,
actual_delivery_date date,
latest_lmp_entered date,
estimated_gestational_age float,
current_pregnancy_state varchar(255),
pregnancy_outcome varchar(255),
most_recent_height float,
most_recent_weight float, 
most_recent_bp_systolic int,
most_recent_bp_diastolic int,
latest_maternity_encounter_type varchar(255),
latest_maternity_encounter_date datetime,
most_recent_hiv_status varchar(255),
dead bit,
death_date datetime,
cause_of_death varchar(255)
);

insert into mch_maternity_patient_staging(emr_id, patient_id)
select DISTINCT emr_id, patient_id
from all_encounters ae 
where encounter_type in
('Sierra Leone Maternal Check-in',
'Maternal Discharge',
'ANC Followup',
'MCH Delivery',
'Labor and Delivery Summary',
'Sierra Leone Maternal Admission',
'ANC Intake',
'Sierra Leone MCH Triage',
'Labour Progress',
'Postpartum progress')
union
select DISTINCT emr_id, patient_id 
from mch_pregnancy_program ; 

-- all_patient fields
update m
set birthdate = p.birthdate,
	dead = p.dead,
	death_date = p.death_date,
	cause_of_death = p.cause_of_death 
from mch_maternity_patient_staging m
inner join all_patients p on p.patient_id  = m.patient_id;

-- most_recent_pregnancy_program_id
update m
set most_recent_pregnancy_program_id = pp.pregnancy_program_id,
	most_recent_date_enrolled = pp.date_enrolled
from mch_maternity_patient_staging m
inner join mch_pregnancy_program pp on pp.pregnancy_program_id = 
	(select top 1 pp2.pregnancy_program_id 
	from mch_pregnancy_program pp2
	where pp2.patient_id = m.patient_id
	order by date_enrolled desc, pregnancy_program_id desc);

update m
set m.latest_lmp_entered = e.last_menstruation_date
from mch_maternity_patient_staging m 
inner join mch_anc_encounter e on e.encounter_id =
    (select top 1 e2.encounter_id from mch_anc_encounter e2
    where e2.patient_id = m.patient_id
    and last_menstruation_date is not null
    order by e2.encounter_datetime desc, e2.encounter_id desc);

-- calculate estimated_gestational_age in this function using the actual delivery date and latest lmp entered on forms
update m
set estimated_gestational_age = dbo.estimated_gestational_age(m.most_recent_pregnancy_program_id, m.actual_delivery_date, m.latest_lmp_entered)
from mch_maternity_patient_staging m;

-- this is necessary because estimated_gestational_age currently contains the string "<45" sometimes:
update m 
set m.current_pregnancy_state = pp.current_state,
 m.pregnancy_outcome = pp.outcome
from mch_maternity_patient_staging m
inner join mch_pregnancy_program pp on pp.pregnancy_program_id = 
	(select top 1 pp2.pregnancy_program_id from mch_pregnancy_program pp2
	where pp2.patient_id = m.patient_id
	order by date_enrolled desc);

update m
set currently_pregnant = 
case	
	when current_pregnancy_state = 'Antenatal' 
		and (estimated_gestational_age <= 45 or (estimated_gestational_age is null and datediff(week, most_recent_date_enrolled, getdate()) <= 45))
		then 1
	else 0	
end
from mch_maternity_patient_staging m;

-- most recent observations from maternity forms
drop table if exists #maternity_encounters;
create table #maternity_encounters
(patient_id varchar(100),
encounter_id varchar(50),
encounter_type varchar(255),
gravida int,
parity int,
abortus int,
living int,
height float,
weight float,
bp_systolic int,
bp_diastolic int,
hiv_status varchar(255),
encounter_datetime datetime
);

insert into #maternity_encounters (patient_id, encounter_id, encounter_type, height, weight, bp_systolic, bp_diastolic, encounter_datetime )
select x.patient_id, x.encounter_id, 'vitals',x.height, x.weight, x.bp_systolic, x.bp_diastolic, x.encounter_datetime  
from all_vitals x
inner join mch_maternity_patient_staging m on m.patient_id = x.patient_id;

insert into #maternity_encounters (patient_id, encounter_id, encounter_type, height, weight, bp_systolic, bp_diastolic, gravida, parity, abortus, living, encounter_datetime )
select x.patient_id, x.encounter_id, iif(x.visit_type='ANC Intake','ANC Initial',x.visit_type),x.height, x.weight, x.bp_systolic, x.bp_diastolic, x.gravida, x.parity, x.abortus, x.living, x.encounter_datetime  
from mch_anc_encounter x
inner join mch_maternity_patient_staging m on m.patient_id = x.patient_id;

insert into #maternity_encounters (patient_id, encounter_id, encounter_type, encounter_datetime )
select x.mother_patient_id,x.encounter_id, 'Labor and Delivery Summary', x.encounter_datetime  
from mch_delivery_summary_encounter x
inner join mch_maternity_patient_staging m on m.patient_id = x.mother_patient_id;

insert into #maternity_encounters (patient_id, encounter_id, encounter_type, encounter_datetime )
select x.patient_id, x.encounter_id, 'Labor and Delivery Summary',  x.encounter_datetime  
from mch_labor_summary_encounter x
inner join mch_maternity_patient_staging m on m.patient_id = x.patient_id;

insert into #maternity_encounters (patient_id, encounter_id, encounter_type, bp_systolic, bp_diastolic, gravida, parity, encounter_datetime )
select x.patient_id, x.encounter_id, 'Labour Progress', x.bp_systolic, x.bp_diastolic, x.gravida, x.parity, x.encounter_datetime  
from mch_labor_progress_encounter x
inner join mch_maternity_patient_staging m on m.patient_id = x.patient_id;

insert into #maternity_encounters (patient_id, encounter_id, encounter_type, bp_systolic, bp_diastolic, encounter_datetime )
select x.patient_id, x.encounter_id, 'Postpartum progress', x.bp_systolic, x.bp_diastolic, x.encounter_datetime  
from mch_postpartum_daily_encounter x
inner join mch_maternity_patient_staging m on m.patient_id = x.patient_id;

insert into #maternity_encounters (patient_id, encounter_id, encounter_type, encounter_datetime )
select x.patient_id, x.encounter_id, x.encounter_type, x.encounter_datetime  
from all_encounters x
inner join mch_maternity_patient_staging m on m.patient_id = x.patient_id
where x.encounter_type in 
('Sierra Leone Maternal Check-in',
'Maternal Discharge',
'Sierra Leone Maternal Admission',
'Sierra Leone MCH Triage',
'MCH Delivery');

update m
set most_recent_height = e.height
from mch_maternity_patient_staging m
inner join #maternity_encounters e on e.encounter_id = 
	(select top 1 e2.encounter_id from #maternity_encounters e2
	where e2.patient_id = m.patient_id
	and e2.height is not NULL 
	order by e2.encounter_datetime desc);

update m
set most_recent_weight = e.weight
from mch_maternity_patient_staging m
inner join #maternity_encounters e on e.encounter_id = 
	(select top 1 e2.encounter_id from #maternity_encounters e2
	where e2.patient_id = m.patient_id
	and e2.weight is not NULL 
	order by e2.encounter_datetime desc);

update m
set most_recent_bp_systolic = e.bp_systolic
from mch_maternity_patient_staging m
inner join #maternity_encounters e on e.encounter_id = 
	(select top 1 e2.encounter_id from #maternity_encounters e2
	where e2.patient_id = m.patient_id
	and e2.bp_systolic is not NULL 
	order by e2.encounter_datetime desc);

update m
set most_recent_bp_diastolic = e.bp_diastolic
from mch_maternity_patient_staging m
inner join #maternity_encounters e on e.encounter_id = 
	(select top 1 e2.encounter_id from #maternity_encounters e2
	where e2.patient_id = m.patient_id
	and e2.bp_diastolic is not NULL 
	order by e2.encounter_datetime desc);

update m
set most_recent_gravida = e.gravida
from mch_maternity_patient_staging m
inner join #maternity_encounters e on e.encounter_id = 
	(select top 1 e2.encounter_id from #maternity_encounters e2
	where e2.patient_id = m.patient_id 
	and e2.gravida is not NULL 
	order by e2.encounter_datetime desc);

update m
set most_recent_parity = e.parity
from mch_maternity_patient_staging m
inner join #maternity_encounters e on e.encounter_id = 
	(select top 1 e2.encounter_id from #maternity_encounters e2
	where e2.patient_id = m.patient_id
	and e2.parity is not NULL 
	order by e2.encounter_datetime desc);

update m
set most_recent_abortus = e.abortus
from mch_maternity_patient_staging m
inner join #maternity_encounters e on e.encounter_id = 
	(select top 1 e2.encounter_id from #maternity_encounters e2
	where e2.patient_id = m.patient_id
	and e2.abortus is not NULL 
	order by e2.encounter_datetime desc);

update m
set most_recent_living = e.living
from mch_maternity_patient_staging m
inner join #maternity_encounters e on e.encounter_id = 
	(select top 1 e2.encounter_id from #maternity_encounters e2
	where e2.patient_id = m.patient_id
	and e2.living is not NULL 
	order by e2.encounter_datetime desc);

update m
set m.latest_maternity_encounter_date = (select max(e.encounter_datetime) from #maternity_encounters e where e.patient_id = m.patient_id and e.encounter_type <> 'vitals') 
from mch_maternity_patient_staging m;

update m
set m.latest_maternity_encounter_type = (select max(e.encounter_type) from #maternity_encounters e where e.patient_id = m.patient_id and e.encounter_datetime = m.latest_maternity_encounter_date) 
from mch_maternity_patient_staging m;
update m
set m.latest_maternity_encounter_type = iif(latest_maternity_encounter_date is null, 'enrollment only',latest_maternity_encounter_type )
from mch_maternity_patient_staging m;

update m
set most_recent_hiv_status = l.result
from mch_maternity_patient_staging m
inner join all_lab_results l on l.lab_obs_id = 
	(select top 1 l2.lab_obs_id from all_lab_results l2
	where l2.patient_id = m.patient_id
	and l2.test in ('HIV test result','Rapid test for HIV')
	order by l2.specimen_collection_date desc);

update m
set m.most_recent_hiv_status = 
	CASE 
 		when most_recent_hiv_status	is null then 'Unknown'
		when most_recent_hiv_status	= 'Indeterminate' then 'Unknown'
	    else most_recent_hiv_status
	 END   
from mch_maternity_patient_staging m;

-- --------------------------
ALTER TABLE mch_maternity_patient_staging DROP COLUMN estimated_gestational_age, current_pregnancy_state, pregnancy_outcome, actual_delivery_date, latest_lmp_entered;

DROP TABLE IF EXISTS mch_maternity_patient;
EXEC sp_rename 'mch_maternity_patient_staging', 'mch_maternity_patient';
