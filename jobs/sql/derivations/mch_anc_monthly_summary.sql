drop table if exists mch_anc_monthly_summary_staging;
create table mch_anc_monthly_summary_staging
(emr_id  varchar(50),
patient_id varchar(50),
reporting_date date,
pregnancy_program_id varchar(50),
age_at_reporting_date float,
hiv_status varchar(255),
birthdate date,                            
age_category varchar(255),
date_enrolled date,
program_outcome_date date,
program_outcome varchar(255),
delivered_this_month bit,
anc_encounters_this_month int,
total_anc_visits int, 
ipt_doses_to_date int, 
albendazole_to_date int, 
iron_doses_to_date int,
anc_visit1 bit,
anc_visit2 bit, 
anc_visit3 bit,
anc_visit4 bit,
anc_visit5 bit,
anc_visit6 bit,
anc_visit7 bit,
anc_visit8 bit,
anc_visit9plus bit,
latest_hiv_result_this_month varchar(255),
anc_visit1_hiv_test bit,
anc_visit1_hiv_positive bit,
anc_visit1_iron bit,
ipt_dose1 bit,
ipt_dose2 bit,
ipt_dose3 bit,
anc_visit1_llin bit,
anc_visit1_albendazole bit,
anc_visit2_albendazole bit,
anc_albendazole_this_month bit,
anc_visit1_haemoglobin bit,
anc_visit1_syphilis bit,
malaria_rdt varchar(255),
malaria_treatment bit,
counsel_for_danger_signs bit,
iron_dose3 bit,
iron_this_month bit,
syphilis_test bit,
arv_medication bit,
muac_measured bit,
anc_visit1_weight bit,
site varchar(100)
);

-- create list of reporting_months (since 2023)
drop table if exists #reporting_months;
select distinct FirstDayOfQuarter as quarter_start_date, FirstDayOfMonth as month_start_date, LastDayOfMonth as month_end_date
into #reporting_months
from dim_date dd
where LastDayOfMonth >= '2023-01-01'
and LastDayOfMonth <= '2025-03-31' -- CHANGE THIS to GETDATE()!
;

-- enter a row for every month-end the patient was active in the program
-- if the patient had multiple qualifying enrollments, set date_enrolled to the most recent
insert into mch_anc_monthly_summary_staging (patient_id, emr_id, reporting_date, pregnancy_program_id, date_enrolled, program_outcome_date, program_outcome, site)
select  distinct pp.patient_id, pp.emr_id, r.month_end_date, pp.pregnancy_program_id,pp.date_enrolled, pp.date_completed, pp.outcome, pp.site
from    mch_pregnancy_program pp
inner join mch_pregnancy_state ps on ps.pregnancy_program_id = pp.pregnancy_program_id and state = 'Antenatal'
inner join #reporting_months r
	on ps.state_start_date <= r.month_end_date
	and     (ps.state_end_date is null or ps.state_end_date >= r.month_start_date);

create index mch_anc_monthly_summary_staging_pi on mch_anc_monthly_summary_staging(patient_id);

update a
set birthdate = p.birthdate
from mch_anc_monthly_summary_staging a
inner join all_patients p on p.patient_id = a.patient_id;

update a
set age_at_reporting_date = DATEDIFF(year, birthdate, reporting_date)
from mch_anc_monthly_summary_staging a;

update a
set age_category = 
CASE
	when age_at_reporting_date < 15 then '<15 years'
	when age_at_reporting_date >= 15 and age_at_reporting_date <= 49 then '15-49 years'
	else '50+ years'
END
from mch_anc_monthly_summary_staging a;

update a
set hiv_status = l.result
from mch_anc_monthly_summary_staging a
inner join all_lab_results l on lab_obs_id = 
	(select top 1 lab_obs_id
	from all_lab_results l2
	where l2.patient_id = a.patient_id 
	and l2.test in ('Rapid test for HIV','HIV test result')
	and l2.specimen_collection_date <= a.reporting_date
	order by l2.specimen_collection_date desc);

update a 
set hiv_status = 'Indeterminate'
from mch_anc_monthly_summary_staging a
where hiv_status is null;

update a
set delivered_this_month = 1 
from mch_anc_monthly_summary_staging a
where exists 
	(select 1 from mch_labor_summary_encounter l
	where l.patient_id = a.patient_id 
	and month(l.encounter_datetime) = month(a.reporting_date));

update a
set delivered_this_month = 0 
from mch_anc_monthly_summary_staging a
where delivered_this_month is null;

update a
set anc_encounters_this_month = 
	(select count(e.encounter_id) from mch_anc_encounter e
	where e.patient_id = a.patient_id
	and month(a.reporting_date) = month(e.encounter_datetime)
	and year(a.reporting_date) = year(e.encounter_datetime)
	and e.encounter_datetime >= a.date_enrolled 
	and (e.encounter_datetime <= a.program_outcome_date or a.program_outcome_date is null))  
from mch_anc_monthly_summary_staging a;


update a
set total_anc_visits = 
	(select count(e.encounter_id) from mch_anc_encounter e
	where e.patient_id = a.patient_id
	and month(a.reporting_date) >= month(e.encounter_datetime)
	and year(a.reporting_date) >= year(e.encounter_datetime)
	and e.encounter_datetime >= a.date_enrolled 
	and (e.encounter_datetime <= a.program_outcome_date or a.program_outcome_date is null))  
from mch_anc_monthly_summary_staging a;

update a
set anc_visit1 = iif(encounter_id is null, 0,1)
from mch_anc_monthly_summary_staging a 
left outer join mch_anc_encounter e on e.pregnancy_program_id = a.pregnancy_program_id 
	and e.index_asc_patient_program = 1
	and month(e.encounter_datetime) = month(a.reporting_date);

update a
set anc_visit2 = iif(encounter_id is null, 0,1)
from mch_anc_monthly_summary_staging a 
left outer join mch_anc_encounter e on e.pregnancy_program_id = a.pregnancy_program_id 
	and e.index_asc_patient_program = 2
	and month(e.encounter_datetime) = month(a.reporting_date);

update a
set anc_visit3 = iif(encounter_id is null, 0,1)
from mch_anc_monthly_summary_staging a 
left outer join mch_anc_encounter e on e.pregnancy_program_id = a.pregnancy_program_id 
	and e.index_asc_patient_program = 3
	and month(e.encounter_datetime) = month(a.reporting_date);

update a
set anc_visit4 = iif(encounter_id is null, 0,1)
from mch_anc_monthly_summary_staging a 
left outer join mch_anc_encounter e on e.pregnancy_program_id = a.pregnancy_program_id 
	and e.index_asc_patient_program = 4
	and month(e.encounter_datetime) = month(a.reporting_date);
update a
set anc_visit5 = iif(encounter_id is null, 0,1)
from mch_anc_monthly_summary_staging a 
left outer join mch_anc_encounter e on e.pregnancy_program_id = a.pregnancy_program_id 
	and e.index_asc_patient_program = 5
	and month(e.encounter_datetime) = month(a.reporting_date);

update a
set anc_visit6 = iif(encounter_id is null, 0,1)
from mch_anc_monthly_summary_staging a 
left outer join mch_anc_encounter e on e.pregnancy_program_id = a.pregnancy_program_id 
	and e.index_asc_patient_program = 6
	and month(e.encounter_datetime) = month(a.reporting_date);

update a
set anc_visit7 = iif(encounter_id is null, 0,1)
from mch_anc_monthly_summary_staging a 
left outer join mch_anc_encounter e on e.pregnancy_program_id = a.pregnancy_program_id 
	and e.index_asc_patient_program = 7
	and month(e.encounter_datetime) = month(a.reporting_date);

update a
set anc_visit8 = iif(encounter_id is null, 0,1)
from mch_anc_monthly_summary_staging a 
left outer join mch_anc_encounter e on e.pregnancy_program_id = a.pregnancy_program_id 
	and e.index_asc_patient_program = 8
	and month(e.encounter_datetime) = month(a.reporting_date);

update a
set anc_visit9plus = 1
from mch_anc_monthly_summary_staging a 
where exists 
	(select 1 from mch_anc_encounter e 
	where e.pregnancy_program_id = a.pregnancy_program_id 
	and e.index_asc_patient_program > 8
	and month(e.encounter_datetime) = month(a.reporting_date));
update a 
set anc_visit9plus = 0
from mch_anc_monthly_summary_staging a where anc_visit9plus is null; 

update a
set latest_hiv_result_this_month = r.result
from mch_anc_monthly_summary_staging a 
inner join all_lab_results r on r.lab_obs_id = 
	(select top 1 r2.lab_obs_id from all_lab_results r2
	where r2.patient_id = a.patient_id
	and r2.test in ('Rapid test for HIV','HIV test result')
	and month(r2.specimen_collection_date) = month(a.reporting_date)
	order by specimen_collection_date desc);	
	
update a
set anc_visit1_hiv_test =
	CASE
		when latest_hiv_result_this_month is not null and  anc_visit1 = 1 then 1
		when latest_hiv_result_this_month is null and  anc_visit1 = 1 then 0
	END
from mch_anc_monthly_summary_staging a ;

update a
set anc_visit1_hiv_positive =
	CASE
		when latest_hiv_result_this_month = 'Positive' and anc_visit1 = 1 then 1
		when latest_hiv_result_this_month is not null and latest_hiv_result_this_month <> 'Positive' and  anc_visit1 = 1 then 0
	END
from mch_anc_monthly_summary_staging a ;

-- create temp dispensing table with pregancy_program_id
drop table if exists #pregnancy_dispensing;
select d.patient_id, pp.pregnancy_program_id, d.encounter_datetime, d.drug_name  
into #pregnancy_dispensing
from all_medication_dispensing d  
inner join mch_pregnancy_program pp on pp.patient_id = d.patient_id
    and pp.date_enrolled <= CAST(d.encounter_datetime AS date)
    and (pp.date_completed >= CAST(d.encounter_datetime AS date) or pp.date_completed is null);

-- columns regarding iron dispensed
-- create an index of all iron dispensings
drop table if exists #iron_indexes;
select  patient_id,
		pregnancy_program_id,
 		encounter_datetime,
        ROW_NUMBER() over (PARTITION by pregnancy_program_id order by encounter_datetime) as index_asc,
        ROW_NUMBER() over (PARTITION by pregnancy_program_id order by encounter_datetime DESC) as index_desc
into    #iron_indexes
from #pregnancy_dispensing 
where drug_name in ('Ferrous sulfate 200mg + folic acid 250 microgram tablet',
					'Ferrous sulfate, 200mg (eq. 65mg elemental Fe) + folic acid 400 microgram tablet',
					'Ferrous sulfate, 200mg (eq. 65mg elemental Fe) tablet');

-- iron_doses_to_date
update a
set iron_doses_to_date = (select count(*) from #iron_indexes i 
	where i.pregnancy_program_id = a.pregnancy_program_id
	and i.encounter_datetime < a.reporting_date)   
from mch_anc_monthly_summary_staging a;
update a set iron_doses_to_date = 0 from mch_anc_monthly_summary_staging a where iron_doses_to_date is null;

-- anc_visit1_iron
update a
set anc_visit1_iron = 1 
from mch_anc_monthly_summary_staging a
where anc_visit1 = 1
and exists
	(select 1 from mch_anc_encounter e
	inner join all_visits v on v.visit_id = e.visit_id
	inner join #iron_indexes i on i.pregnancy_program_id = a.pregnancy_program_id
		and i.encounter_datetime >= v.visit_date_started 
		and (i.encounter_datetime <= v.visit_date_stopped or v.visit_date_stopped is null)
	where e.pregnancy_program_id = a.pregnancy_program_id 
	and e.index_asc_patient_program = 1);
update a set anc_visit1_iron = 0 from mch_anc_monthly_summary_staging a where anc_visit1_iron is null;

-- iron_dose3
update a
set iron_dose3 = 1
from mch_anc_monthly_summary_staging a 
where exists
	(select 1 from #iron_indexes i
	where i.pregnancy_program_id = a.pregnancy_program_id
	and i.index_asc = 3
	and month(i.encounter_datetime) = month(a.reporting_date))
update a set iron_dose3 = 0 from mch_anc_monthly_summary_staging a where iron_dose3 is null;

-- iron_this_month
update a
set iron_this_month = 1
from mch_anc_monthly_summary_staging a 
where exists
	(select 1 from #iron_indexes i
	where i.pregnancy_program_id = a.pregnancy_program_id
	and month(i.encounter_datetime) = month(a.reporting_date))
update a set iron_this_month = 0 from mch_anc_monthly_summary_staging a where iron_this_month is null;

-- create an index of all ipt dispensings
drop table if exists #ipt_indexes;
select  patient_id,
		pregnancy_program_id,
 		encounter_datetime,
        ROW_NUMBER() over (PARTITION by pregnancy_program_id order by encounter_datetime) as index_asc,
        ROW_NUMBER() over (PARTITION by pregnancy_program_id order by encounter_datetime DESC) as index_desc
into    #ipt_indexes
from #pregnancy_dispensing 
where drug_name = 'Sulfadoxine (S) 500mg + Pyrimethamine (P) 25mg tablet';

-- ipt_doses_to_date
update a
set ipt_doses_to_date = (select count(*) from #ipt_indexes i where i.pregnancy_program_id = a.pregnancy_program_id and i.encounter_datetime <= a.reporting_date )   
from mch_anc_monthly_summary_staging a;
update a set ipt_doses_to_date = 0 from mch_anc_monthly_summary_staging a where ipt_doses_to_date is null;

-- ipt_dose1
update a
set ipt_dose1 = 1
from mch_anc_monthly_summary_staging a 
where exists
	(select 1 from #ipt_indexes i
	where i.pregnancy_program_id = a.pregnancy_program_id
	and i.index_asc = 1
	and month(i.encounter_datetime) = month(a.reporting_date))
update a set ipt_dose1 = 0 from mch_anc_monthly_summary_staging a where ipt_dose1 is null;

-- ipt_dose2
update a
set ipt_dose2 = 1
from mch_anc_monthly_summary_staging a 
where exists
	(select 1 from #ipt_indexes i
	where i.pregnancy_program_id = a.pregnancy_program_id
	and i.index_asc = 2
	and month(i.encounter_datetime) = month(a.reporting_date))
update a set ipt_dose2 = 0 from mch_anc_monthly_summary_staging a where ipt_dose2 is null;

-- ipt_dose3
update a
set ipt_dose3 = 1
from mch_anc_monthly_summary_staging a 
where exists
	(select 1 from #ipt_indexes i
	where i.pregnancy_program_id = a.pregnancy_program_id
	and i.index_asc = 3
	and month(i.encounter_datetime) = month(a.reporting_date))
update a set ipt_dose3 = 0 from mch_anc_monthly_summary_staging a where ipt_dose3 is null;

-- create an index of all albendazole dispensings
drop table if exists #albendazole_indexes;
select  patient_id,
		pregnancy_program_id,
 		encounter_datetime,
        ROW_NUMBER() over (PARTITION by pregnancy_program_id order by encounter_datetime) as index_asc,
        ROW_NUMBER() over (PARTITION by pregnancy_program_id order by encounter_datetime DESC) as index_desc
into    #albendazole_indexes
from #pregnancy_dispensing 
where drug_name in ('Albendazole, 200mg chewable tablet',
					'Albendazole, 400mg chewable tablet');

-- albendazole_to_date
update a
set albendazole_to_date = (select count(*) from #albendazole_indexes i 
	where i.pregnancy_program_id = a.pregnancy_program_id
	and i.encounter_datetime < a.reporting_date)   
from mch_anc_monthly_summary_staging a;
update a set albendazole_to_date = 0 from mch_anc_monthly_summary_staging a where albendazole_to_date is null;

-- anc_visit1_albendazole
update a
set anc_visit1_albendazole = 1 
from mch_anc_monthly_summary_staging a
where anc_visit1 = 1
and exists
	(select 1 from mch_anc_encounter e
	inner join all_visits v on v.visit_id = e.visit_id
	inner join #albendazole_indexes i on i.pregnancy_program_id = a.pregnancy_program_id
		and i.encounter_datetime >= v.visit_date_started 
		and (i.encounter_datetime <= v.visit_date_stopped or v.visit_date_stopped is null)
	where e.pregnancy_program_id = a.pregnancy_program_id 
	and e.index_asc_patient_program = 1);
update a set anc_visit1_albendazole = 0 from mch_anc_monthly_summary_staging a where anc_visit1_albendazole is null;

-- anc_visit2_albendazole
update a
set anc_visit2_albendazole = 1 
from mch_anc_monthly_summary_staging a
where anc_visit2 = 1
and exists
	(select 1 from mch_anc_encounter e
	inner join all_visits v on v.visit_id = e.visit_id
	inner join #albendazole_indexes i on i.pregnancy_program_id = a.pregnancy_program_id
		and i.encounter_datetime >= v.visit_date_started 
		and (i.encounter_datetime <= v.visit_date_stopped or v.visit_date_stopped is null)
	where e.pregnancy_program_id = a.pregnancy_program_id 
	and e.index_asc_patient_program = 2);
update a set anc_visit2_albendazole = 0 from mch_anc_monthly_summary_staging a where anc_visit2_albendazole is null;

-- anc_albendazole_this_month
update a
set anc_albendazole_this_month = 1
from mch_anc_monthly_summary_staging a 
where exists
	(select 1 from #albendazole_indexes i
	where i.pregnancy_program_id = a.pregnancy_program_id
	and month(i.encounter_datetime) = month(a.reporting_date))
update a set anc_albendazole_this_month = 0 from mch_anc_monthly_summary_staging a where anc_albendazole_this_month is null;

update a
set anc_visit1_llin = 1 
from mch_anc_monthly_summary_staging a
where anc_visit1 = 1
and exists
	(select 1 from mch_anc_encounter e
	inner join all_visits v on v.visit_id = e.visit_id
	where e.pregnancy_program_id = a.pregnancy_program_id
	and e.llin = 1
		and e.index_asc_patient_program = 1)
update a set anc_visit1_llin = 0 from mch_anc_monthly_summary_staging a where anc_visit1_llin is null;

update a
set anc_visit1_haemoglobin = 1 
from mch_anc_monthly_summary_staging a
where anc_visit1 = 1
and exists
	(select 1 from mch_anc_encounter e
	inner join all_visits v on v.visit_id = e.visit_id
	inner join all_lab_results l on l.specimen_collection_date >= v.visit_date_started 
		and (l.specimen_collection_date <= v.visit_date_stopped or v.visit_date_stopped is null)
		and l.test = 'Hemoglobin'
	where e.pregnancy_program_id = a.pregnancy_program_id 
	and e.index_asc_patient_program = 1);
update a set anc_visit1_haemoglobin = 0 from mch_anc_monthly_summary_staging a where anc_visit1_haemoglobin is null;

update a
set anc_visit1_syphilis = 1 
from mch_anc_monthly_summary_staging a
where anc_visit1 = 1
and exists
	(select 1 from mch_anc_encounter e
	inner join all_visits v on v.visit_id = e.visit_id
	inner join all_lab_results l on l.patient_id = e.patient_id 
		and l.specimen_collection_date >= v.visit_date_started 
		and (l.specimen_collection_date <= v.visit_date_stopped or v.visit_date_stopped is null)
		and l.test = 'Rapid syphilis test'
	where e.pregnancy_program_id = a.pregnancy_program_id 
	and e.index_asc_patient_program = 1);
update a set anc_visit1_syphilis = 0 from mch_anc_monthly_summary_staging a where anc_visit1_syphilis is null;

update a
set malaria_rdt = iif(l.result like 'Positive%', 'Positive',l.result)
from mch_anc_monthly_summary_staging a
inner join all_lab_results l on l.lab_obs_id = 
	(select top 1 l2.lab_obs_id from all_lab_results l2
	where l2.patient_id = a.patient_id
	and month(l2.specimen_collection_date) = month(reporting_date)
	and l2.test = 'Malaria RDT'
	order by l2.specimen_collection_date desc);

update a
set syphilis_test = 1
from mch_anc_monthly_summary_staging a
where exists
	(select 1 from all_lab_results l
	where l.patient_id = a.patient_id 
	and l.test = 'Rapid syphilis test'
	and month(l.specimen_collection_date) = month(reporting_date));
update a set syphilis_test = 0 from mch_anc_monthly_summary_staging a where syphilis_test is null;

update a
set counsel_for_danger_signs = 1
from mch_anc_monthly_summary_staging a
where exists
	(select 1 from mch_anc_encounter e
	where e.pregnancy_program_id = a.pregnancy_program_id 
	and e.counseled_danger_signs = 1
	and month(e.encounter_datetime) = month(reporting_date));
update a set counsel_for_danger_signs = 0 from mch_anc_monthly_summary_staging a where counsel_for_danger_signs is null;


/* NOTE: for these medication columns, it is not ideal that these meds are hardcoded.
 Eventually drug sets should be on the warehouse and these queries would use the 
 antimalarial and arv sets 
  */
update a
set malaria_treatment = 1
from mch_anc_monthly_summary_staging a
where exists
	(select 1 from all_medication_dispensing d
	where d.patient_id = a.patient_id 
	and month(d.encounter_datetime) = month(reporting_date)
	and drug_name in 
		('Doxycycline, 100mg tablet',
		'Artesunate, 60mg powder for reconstitution, with 5mL sodium chloride and 1mL sodium bicarbonate 5%',
		'Quinine di-hydrochloride, Solution for injection, 300mg/mL, 2mL ampoule',
		'Quinine sulfate, 300mg tablet'));
update a set malaria_treatment = 0 from mch_anc_monthly_summary_staging a where malaria_treatment is null;		
	
update a
set arv_medication = 1
from mch_anc_monthly_summary_staging a
where exists
	(select 1 from all_medication_dispensing d
	where d.patient_id = a.patient_id 
	and month(d.encounter_datetime) = month(reporting_date)
	and drug_name in 
		('Efavirenz (EFV), 200mg tablet',
		'Efavirenz (EFV), 600mg tablet',
		'Lopinavir (LPV) 100mg + Ritonavir (r) 25mg tablet',
		'Lopinavir (LPV) 200mg + Ritonavir (r) 50mg tablet',
		'Lopinavir (LPV) 80mg/mL + Ritonavir (r) 20mg/mL, Oral suspension, 160mL bottle',
		'Emtricitabine (FTC) 200mg + Tenofovir disoproxil fumarate (TDF) 245mg tablet',
		'Lamivudine (3TC) 150mg + Zidovudine (AZT) 300mg tablet',
		'Lamivudine (3TC) 30mg + Zidovudine (AZT) 60mg tablet',
		'Nevirapine (NVP), 50mg dispersible tablet',
		'Nevirapine (NVP), Oral suspension, 100mL bottle',
		'Tenofovir disoproxil fumarate (TDF) 300mg + Lamivudine (3TC) 300mg + Efavirenz (EFV) 600mg tablet',
		'Lamivudine (3TC) 150mg + Nevirapine (NVP) 200mg + Zidovudine (AZT) 300mg tablet',
		'Lamivudine (3TC) 30mg + Nevirapine (NVP) 50mg + Zidovudine (AZT) 60mg dispersible tablet'));
update a set arv_medication = 0 from mch_anc_monthly_summary_staging a where arv_medication is null;	

update a
set muac_measured = 1
from mch_anc_monthly_summary_staging a
where exists
	(select 1 from all_vitals v
	where v.patient_id = a.patient_id 
	and muac_mm is not null
	and month(v.encounter_datetime) = month(reporting_date));
update a set muac_measured = 0 from mch_anc_monthly_summary_staging a where muac_measured is null;

update a
set anc_visit1_weight = 1
from mch_anc_monthly_summary_staging a
where anc_visit1 = 1
and exists
	(select 1 from mch_anc_encounter e
	inner join all_visits v on v.visit_id = e.visit_id
	inner join all_vitals vit on vit.encounter_datetime >= v.visit_date_started 
		and (vit.encounter_datetime <= v.visit_date_stopped or v.visit_date_stopped is null)
		and vit.weight is not null
	where e.pregnancy_program_id = a.pregnancy_program_id 
	and e.index_asc_patient_program = 1);
update a set anc_visit1_weight = 0 from mch_anc_monthly_summary_staging a where anc_visit1_weight is null;

-- -------------------------------------
DROP TABLE IF EXISTS mch_anc_monthly_summary;
EXEC sp_rename 'mch_anc_monthly_summary_staging', 'mch_anc_monthly_summary';
