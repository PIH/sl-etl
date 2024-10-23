drop table if exists maternity_patient_staging;
create table maternity_patient_staging
(
emr_id varchar(50),
patient_id varchar(100),
dob date,
currently_pregnant bit,
most_recent_gravida int,
most_recent_parity int,
most_recent_abortus int,
most_recent_living int,
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

insert into maternity_patient_staging(emr_id, patient_id)
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
'Postpartum progress'); 

-- all_patient fields
update m
set dob = p.dob,
	dead = p.dead,
	death_date = p.death_date,
	cause_of_death = p.cause_of_death 
from maternity_patient_staging m
inner join all_patients p on p.patient_id  = m.patient_id;

update m
set currently_pregnant = 1
from maternity_patient_staging m;

-- this is necessary because estimated_gestational_age currently contains the string "<45" sometimes:
update m 
set m.estimated_gestational_age = 
	  case
	  	when ISNUMERIC(pp.estimated_gestational_age)=1 then pp.estimated_gestational_age
	  	else null
	  end,
 m.current_pregnancy_state = pp.current_state,
 m.pregnancy_outcome = pp.outcome
from maternity_patient_staging m
inner join pregnancy_program pp on pp.pregnancy_program_id = 
	(select top 1 pp2.pregnancy_program_id from pregnancy_program pp2
	where pp2.patient_id = m.patient_id
	order by date_enrolled desc);

update m
set currently_pregnant = iif(estimated_gestational_age < 45.0 and current_pregnancy_state <> 'Postpartum' and pregnancy_outcome is null ,1,0)
from maternity_patient_staging m;

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
inner join maternity_patient_staging m on m.patient_id = x.patient_id;

insert into #maternity_encounters (patient_id, encounter_id, encounter_type, height, weight, bp_systolic, bp_diastolic, gravida, parity, abortus, living, encounter_datetime )
select x.patient_id, x.encounter_id, x.visit_type,x.height, x.weight, x.bp_systolic, x.bp_diastolic, x.gravida, x.parity, x.abortus, x.living, x.encounter_datetime  
from anc_encounter x
inner join maternity_patient_staging m on m.patient_id = x.patient_id;

insert into #maternity_encounters (patient_id, encounter_id, encounter_type, encounter_datetime )
select x.mother_patient_id,x.encounter_id, 'Labor and Delivery Summary', x.encounter_datetime  
from delivery_summary_encounter x
inner join maternity_patient_staging m on m.patient_id = x.mother_patient_id;

insert into #maternity_encounters (patient_id, encounter_id, encounter_type, encounter_datetime )
select x.patient_id, x.encounter_id, 'Labor and Delivery Summary',  x.encounter_datetime  
from labor_summary_encounter x
inner join maternity_patient_staging m on m.patient_id = x.patient_id;

insert into #maternity_encounters (patient_id, encounter_id, encounter_type, bp_systolic, bp_diastolic, gravida, parity, encounter_datetime )
select x.patient_id, x.encounter_id, 'Labour Progress', x.bp_systolic, x.bp_diastolic, x.gravida, x.parity, x.encounter_datetime  
from labor_progress_encounter x
inner join maternity_patient_staging m on m.patient_id = x.patient_id;

insert into #maternity_encounters (patient_id, encounter_id, encounter_type, bp_systolic, bp_diastolic, encounter_datetime )
select x.patient_id, x.encounter_id, 'Postpartum progress', x.bp_systolic, x.bp_diastolic, x.encounter_datetime  
from postpartum_daily_encounter x
inner join maternity_patient_staging m on m.patient_id = x.patient_id;

insert into #maternity_encounters (patient_id, encounter_id, encounter_type, encounter_datetime )
select x.patient_id, x.encounter_id, x.encounter_type, x.encounter_datetime  
from all_encounters x
inner join maternity_patient_staging m on m.patient_id = x.patient_id
where x.encounter_type in 
('Sierra Leone Maternal Check-in',
'Maternal Discharge',
'Sierra Leone Maternal Admission',
'Sierra Leone MCH Triage');

update m
set most_recent_height = e.height
from maternity_patient_staging m
inner join #maternity_encounters e on e.encounter_id = 
	(select top 1 e2.encounter_id from #maternity_encounters e2
	where e2.patient_id = m.patient_id
	and e2.height is not NULL 
	order by e2.encounter_datetime desc);

update m
set most_recent_weight = e.weight
from maternity_patient_staging m
inner join #maternity_encounters e on e.encounter_id = 
	(select top 1 e2.encounter_id from #maternity_encounters e2
	where e2.patient_id = m.patient_id
	and e2.weight is not NULL 
	order by e2.encounter_datetime desc);

update m
set most_recent_bp_systolic = e.bp_systolic
from maternity_patient_staging m
inner join #maternity_encounters e on e.encounter_id = 
	(select top 1 e2.encounter_id from #maternity_encounters e2
	where e2.patient_id = m.patient_id
	and e2.bp_systolic is not NULL 
	order by e2.encounter_datetime desc);

update m
set most_recent_bp_diastolic = e.bp_diastolic
from maternity_patient_staging m
inner join #maternity_encounters e on e.encounter_id = 
	(select top 1 e2.encounter_id from #maternity_encounters e2
	where e2.patient_id = m.patient_id
	and e2.bp_diastolic is not NULL 
	order by e2.encounter_datetime desc);

update m
set most_recent_gravida = e.gravida
from maternity_patient_staging m
inner join #maternity_encounters e on e.encounter_id = 
	(select top 1 e2.encounter_id from #maternity_encounters e2
	where e2.patient_id = m.patient_id 
	and e2.gravida is not NULL 
	order by e2.encounter_datetime desc);

update m
set most_recent_parity = e.parity
from maternity_patient_staging m
inner join #maternity_encounters e on e.encounter_id = 
	(select top 1 e2.encounter_id from #maternity_encounters e2
	where e2.patient_id = m.patient_id
	and e2.parity is not NULL 
	order by e2.encounter_datetime desc);

update m
set most_recent_abortus = e.abortus
from maternity_patient_staging m
inner join #maternity_encounters e on e.encounter_id = 
	(select top 1 e2.encounter_id from #maternity_encounters e2
	where e2.patient_id = m.patient_id
	and e2.abortus is not NULL 
	order by e2.encounter_datetime desc);

update m
set most_recent_living = e.living
from maternity_patient_staging m
inner join #maternity_encounters e on e.encounter_id = 
	(select top 1 e2.encounter_id from #maternity_encounters e2
	where e2.patient_id = m.patient_id
	and e2.living is not NULL 
	order by e2.encounter_datetime desc);

update m
set m.latest_maternity_encounter_date = (select max(e.encounter_datetime) from #maternity_encounters e where e.patient_id = m.patient_id) 
from maternity_patient_staging m;

update m
set m.latest_maternity_encounter_type = (select max(e.encounter_type) from #maternity_encounters e where e.patient_id = m.patient_id and e.encounter_datetime = m.latest_maternity_encounter_date) 
from maternity_patient_staging m;

update m
set most_recent_hiv_status = pp.hiv_status
from maternity_patient_staging m
inner join pregnancy_program pp on pp.pregnancy_program_id = 
	(select top 1 pp2.pregnancy_program_id from pregnancy_program pp2
	where pp2.patient_id = m.patient_id
	and pp2.hiv_status is not NULL 
	order by pp2.date_enrolled desc);

-- --------------------------
ALTER TABLE maternity_patient_staging DROP COLUMN estimated_gestational_age, current_pregnancy_state,pregnancy_outcome;
DROP TABLE IF EXISTS maternity_patient;
EXEC sp_rename 'maternity_patient_staging', 'maternity_patient';
