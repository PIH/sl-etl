drop table if exists pregnancy_summary_staging;  -- change to pregnancy_program_summary_staging 
create  table pregnancy_summary_staging
(
-- columns in final table:
    emr_id                                     varchar(30),
    patient_id                                 varchar(50),
    pregnancy_program_id                       varchar(50),
    date_enrolled                              date,
    date_completed                             date,   
    pregnancy_status                           varchar(255),
    age_at_pregnancy_registration              int,
    danger_signs                               text,
    high_risk_factors                          text,    
    estimated_gestational_age                  float,    
    estimated_delivery_date                    date,
    actual_delivery_date                       date,
    delivery_location                          varchar(255),     
    delivery_outcome                           varchar(255),
    number_of_fetuses                          int,
    hiv_status                                 varchar(255),
    trimester_enrolled                         varchar(255),
    total_anc_visits                           int,
    total_anc_visits_recorded_in_emr           int,    
    iptp_sp_malaria_ever                       bit,
    nutrition_counseling_ever                  bit,
    hiv_counsel_and_test_ever                  bit,
    insecticide_treated_net_ever               bit,
    iron_ifa_ever                              bit,
    syphilis_test_ever                         bit,  
    arv_for_pmtct                              bit,
    muac_measured                              bit, 
    anc_visit1_weight_recorded                 bit,
    malaria_treatment_during_antenatal         bit, 
    birthdate                                  date,
    rdt_during_anc                             bit,
    anc_visit1_hiv_test                        bit,
    index_asc                                  int,
    index_desc                                 int,
-- columns used for calculations:
    outcome                                    varchar(255),
    current_state                              varchar(255),
    latest_lmp_entered                         date,
    estimated_delivery_date_entered            date, 
    delivery_num_alive                         int,
    delivery_num_fsb                           int,
    delivery_num_msb                           int,
    number_anc_visit_entered                   int,
    number_anc_visit_entered_datetime          datetime,
    total_anc_visits_since_entry               int,
    post_partum_state_date                     date,
    anc_state_date                             date
);

insert into pregnancy_summary_staging
	(pregnancy_program_id,
	patient_id,
	emr_id,
	date_enrolled,
	date_completed,
	outcome,
    current_state)
select 
	pregnancy_program_id,
	patient_id,
	emr_id,
	date_enrolled,
	date_completed,
	outcome,
    current_state
from mch_pregnancy_program pp;


update ps
set birthdate = p.birthdate
from pregnancy_summary_staging ps
inner join all_patients p on p.patient_id = ps.patient_id;

update ps
set age_at_pregnancy_registration = DATEDIFF(year, p.birthdate, date_enrolled)
from pregnancy_summary_staging ps
inner join all_patients p on p.patient_id = ps.patient_id;

-- danger signs
-- to get distinct danger signs for each program, we need to unpack the concatenated danger signs from the mch_anc_encounter table
-- and then repack the distinct danger signs into the target table 
drop table if exists #danger_signs_parsed;
select encounter_id,pregnancy_program_id, sign_number, sign
into #danger_signs_parsed
FROM
	(select encounter_id, pregnancy_program_id, 
		   parsename(REPLACE(cast(danger_signs as varchar(255)), ' | ', '.'), 1) "d1",
	       parsename(REPLACE(cast(danger_signs as varchar(255)), ' | ', '.'), 2) "d2",
	       parsename(REPLACE(cast(danger_signs as varchar(255)), ' | ', '.'), 3) "d3",
	       parsename(REPLACE(cast(danger_signs as varchar(255)), ' | ', '.'), 4) "d4",
	       parsename(REPLACE(cast(danger_signs as varchar(255)), ' | ', '.'), 5) "d5",
	       parsename(REPLACE(cast(danger_signs as varchar(255)), ' | ', '.'), 6) "d6",
	       parsename(REPLACE(cast(danger_signs as varchar(255)), ' | ', '.'), 7) "d7",
	       parsename(REPLACE(cast(danger_signs as varchar(255)), ' | ', '.'), 8) "d8",
	       parsename(REPLACE(cast(danger_signs as varchar(255)), ' | ', '.'), 9) "d9",
	       parsename(REPLACE(cast(danger_signs as varchar(255)), ' | ', '.'), 10) "d10",
	       parsename(REPLACE(cast(danger_signs as varchar(255)), ' | ', '.'), 11) "d11",
	       parsename(REPLACE(cast(danger_signs as varchar(255)), ' | ', '.'), 12) "d12",
	       parsename(REPLACE(cast(danger_signs as varchar(255)), ' | ', '.'), 13) "d13",
	       parsename(REPLACE(cast(danger_signs as varchar(255)), ' | ', '.'), 14) "d14",
	       parsename(REPLACE(cast(danger_signs as varchar(255)), ' | ', '.'), 15) "d15"      
	from mch_anc_encounter where pregnancy_program_id is not null) ds
UNPIVOT
	(
	    sign for sign_number in (d1, d2, d3, d4, d5, d6, d7, d8, d9, d10, d11, d12, d13, d14, d15)
	) pt
;

drop table if exists #danger_signs;
select pregnancy_program_id, danger_signs = 
	stuff(
	(select distinct  '| ' + sign + ' '
	from #danger_signs_parsed d2 
	where d2.pregnancy_program_id = d1.pregnancy_program_id
	for XML PATH('')),1,1,'') 
into #danger_signs	
from #danger_signs_parsed d1;

update p 
set p.danger_signs = d.danger_signs
from pregnancy_summary_staging p 
inner join #danger_signs d on d.pregnancy_program_id = p.pregnancy_program_id;

-- high risk factors 
-- to get distinct risk factors for each program, we need to unpack the concatenated risk factors from the mch_anc_encounter table
-- and then repack the distinct risk factors into the target table 
drop table if exists #risk_factors_parsed;
select encounter_id, pregnancy_program_id, rf_number, rf
into #risk_factors_parsed
FROM
	(select encounter_id, pregnancy_program_id, 
		   parsename(REPLACE(cast(high_risk_factors as varchar(255)), ' | ', '.'), 1) "r1",
	       parsename(REPLACE(cast(high_risk_factors as varchar(255)), ' | ', '.'), 2) "r2",
	       parsename(REPLACE(cast(high_risk_factors as varchar(255)), ' | ', '.'), 3) "r3",
	       parsename(REPLACE(cast(high_risk_factors as varchar(255)), ' | ', '.'), 4) "r4",
	       parsename(REPLACE(cast(high_risk_factors as varchar(255)), ' | ', '.'), 5) "r5",
	       parsename(REPLACE(cast(high_risk_factors as varchar(255)), ' | ', '.'), 6) "r6",
	       parsename(REPLACE(cast(high_risk_factors as varchar(255)), ' | ', '.'), 7) "r7",
	       parsename(REPLACE(cast(high_risk_factors as varchar(255)), ' | ', '.'), 8) "r8",
	       parsename(REPLACE(cast(high_risk_factors as varchar(255)), ' | ', '.'), 9) "r9",
	       parsename(REPLACE(cast(high_risk_factors as varchar(255)), ' | ', '.'), 10) "r10",
	       parsename(REPLACE(cast(high_risk_factors as varchar(255)), ' | ', '.'), 11) "r11",
	       parsename(REPLACE(cast(high_risk_factors as varchar(255)), ' | ', '.'), 12) "r12",
	       parsename(REPLACE(cast(high_risk_factors as varchar(255)), ' | ', '.'), 13) "r13",
	       parsename(REPLACE(cast(high_risk_factors as varchar(255)), ' | ', '.'), 14) "r14",
	       parsename(REPLACE(cast(high_risk_factors as varchar(255)), ' | ', '.'), 15) "r15"      
	from mch_anc_encounter where pregnancy_program_id is not null) rfs
UNPIVOT
	(
	    rf for rf_number in (r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, r13, r14, r15)
	) pt
;

update r
set r.rf = concat(r.rf,': ', e.other_risk_factors)  
from #risk_factors_parsed r
inner join mch_anc_encounter e on e.encounter_id = r.encounter_id
where r.rf = 'Other';

drop table if exists #risk_factors;
select pregnancy_program_id, risk_factors = 
	stuff(
	(select distinct  '| ' + rf + ' '
	from #risk_factors_parsed r2 
	where r2.pregnancy_program_id = r1.pregnancy_program_id
	for XML PATH('')),1,1,'') 
into #risk_factors	
from #risk_factors_parsed r1
;

update p 
set p.high_risk_factors = r.risk_factors
from pregnancy_summary_staging p 
inner join #risk_factors r on r.pregnancy_program_id = p.pregnancy_program_id;


update p
set p.latest_lmp_entered = e.last_menstruation_date
from pregnancy_summary_staging p 
inner join mch_anc_encounter e on e.encounter_id =
    (select top 1 e2.encounter_id from mch_anc_encounter e2
    where e2.pregnancy_program_id = p.pregnancy_program_id
    and last_menstruation_date is not null
    order by e2.encounter_datetime desc, e2.encounter_id desc);

update p
set p.estimated_delivery_date_entered = e.estimated_delivery_date
from pregnancy_summary_staging p 
inner join mch_anc_encounter e on e.encounter_id =
    (select top 1 e2.encounter_id from mch_anc_encounter e2
    where e2.pregnancy_program_id = p.pregnancy_program_id
    and estimated_delivery_date is not null
    order by e2.encounter_datetime desc, e2.encounter_id desc);

update p
set estimated_delivery_date =
	CASE
		when latest_lmp_entered is not null then dateadd(week, 40, latest_lmp_entered)
	    else estimated_delivery_date_entered 
	END
from pregnancy_summary_staging p; 

update p 
set actual_delivery_date =
	(select min(birthdate) from mch_delivery_summary_encounter d
	where d.pregnancy_program_id = p.pregnancy_program_id)
from pregnancy_summary_staging p; 

update p
set p.delivery_location = site
from pregnancy_summary_staging p 
inner join mch_delivery_summary_encounter e on e.encounter_id =
    (select top 1 e2.encounter_id from mch_delivery_summary_encounter e2
    where e2.pregnancy_program_id = p.pregnancy_program_id
    order by e2.encounter_datetime desc, e2.encounter_id desc);

-- calculate estimated_gestational_age in this function using the actual delivery date and latest lmp entered on forms
update p
set estimated_gestational_age = dbo.estimated_gestational_age(p.pregnancy_program_id, p.actual_delivery_date, p.latest_lmp_entered)
from pregnancy_summary_staging p;

update p
set pregnancy_status = 
CASE
	when current_state = 'Miscarried' then 'Miscarried'
	when actual_delivery_date is not null 
	     or current_state = 'Postpartum' then 'Delivered'
	when estimated_gestational_age > 45
	  or datediff(week, date_enrolled, getdate()) > 45 then 'Presumed Postpartum'
	else 'Antenatal'
END
from pregnancy_summary_staging p;

update p 
set number_of_fetuses = 
	(select count(*) from mch_delivery_summary_encounter d
	where d.pregnancy_program_id = p.pregnancy_program_id)
from pregnancy_summary_staging p; 

update p 
set number_of_fetuses = 1 
from pregnancy_summary_staging p 
where number_of_fetuses = 0 ; 

update p 
set delivery_num_alive = 
	(select count(*) from mch_delivery_summary_encounter d
	where d.pregnancy_program_id = p.pregnancy_program_id
	and d.outcome = 'Livebirth')
from pregnancy_summary_staging p; 

update p 
set delivery_num_fsb = 
	(select count(*) from mch_delivery_summary_encounter d
	where d.pregnancy_program_id = p.pregnancy_program_id
	and d.outcome = 'Fresh stillbirth')
from pregnancy_summary_staging p; 

update p 
set delivery_num_msb = 
	(select count(*) from mch_delivery_summary_encounter d
	where d.pregnancy_program_id = p.pregnancy_program_id
	and d.outcome = 'Macerated stillbirth')
from pregnancy_summary_staging p; 

update p 
set delivery_outcome = 
	case
		when delivery_num_alive > 0 and delivery_num_fsb = 0 and delivery_num_msb = 0
			then 'Alive'
		when delivery_num_alive = 0 and (delivery_num_fsb > 0 or delivery_num_msb > 0)
			then 'Stillbirth'	
		when delivery_num_alive > 0 and (delivery_num_fsb > 0 or delivery_num_msb > 0)
		then 'Multiple outcome'
	end
from pregnancy_summary_staging p
where actual_delivery_date is not null; 


update p 
set total_anc_visits_recorded_in_emr = 
	(select count(*) from mch_anc_encounter e
	where e.pregnancy_program_id = p.pregnancy_program_id)
from pregnancy_summary_staging p; 

update p
set p.number_anc_visit_entered = e.number_anc_visit,
	number_anc_visit_entered_datetime = e.encounter_datetime
from pregnancy_summary_staging p 
inner join mch_anc_encounter e on e.encounter_id =
    (select top 1 e2.encounter_id from mch_anc_encounter e2
    where e2.pregnancy_program_id = p.pregnancy_program_id
    and number_anc_visit is not null
    order by e2.encounter_datetime desc, e2.encounter_id desc);

update p 
set total_anc_visits_since_entry = 
	(select count(*) from mch_anc_encounter e
	where e.pregnancy_program_id = p.pregnancy_program_id
	and e.encounter_datetime > p.number_anc_visit_entered_datetime
	)
from pregnancy_summary_staging p; 

update p 
set total_anc_visits = 
case
	when number_anc_visit_entered is null then total_anc_visits_recorded_in_emr
	else iif(total_anc_visits_recorded_in_emr > number_anc_visit_entered + total_anc_visits_since_entry, total_anc_visits_recorded_in_emr, number_anc_visit_entered + total_anc_visits_since_entry)
end
from pregnancy_summary_staging p; 

-- nutrition_counseling_ever
update p 
set nutrition_counseling_ever = 1
from pregnancy_summary_staging p
where exists
	(select 1 from mch_anc_encounter e 
	where e.pregnancy_program_id = p.pregnancy_program_id
	and nutrition_counseling = 1);
update p set nutrition_counseling_ever = 0 from pregnancy_summary_staging p where total_anc_visits_recorded_in_emr > 0 and nutrition_counseling_ever is null;

-- hiv_counsel_and_test_ever
update p 
set hiv_counsel_and_test_ever = 1
from pregnancy_summary_staging p
where exists
	(select 1 from mch_anc_encounter e 
	where e.pregnancy_program_id = p.pregnancy_program_id
	and hiv_counsel_and_test = 1);
update p set hiv_counsel_and_test_ever = 0 from pregnancy_summary_staging p where total_anc_visits_recorded_in_emr > 0 and hiv_counsel_and_test_ever is null;

-- insecticide_treated_net_ever
update p 
set insecticide_treated_net_ever = 1
from pregnancy_summary_staging p
where exists
	(select 1 from mch_anc_encounter e 
	where e.pregnancy_program_id = p.pregnancy_program_id
	and llin = 1);
update p set insecticide_treated_net_ever = 0 from pregnancy_summary_staging p where total_anc_visits_recorded_in_emr > 0 and insecticide_treated_net_ever is null;

-- fields from dispensing
-- iptp_sp_malaria_ever
update p 
set iptp_sp_malaria_ever = 1
from pregnancy_summary_staging p
where exists
	(select 1 from all_medication_dispensing d 
	where d.patient_id = p.patient_id
	and (cast(d.encounter_datetime as date) >= date_enrolled
		and cast(d.encounter_datetime as date) <= date_completed or date_completed is null)
	and drug_name = 'Sulfadoxine (S) 500mg + Pyrimethamine (P) 25mg tablet');
update p set iptp_sp_malaria_ever = 0 from pregnancy_summary_staging p where total_anc_visits_recorded_in_emr > 0 and iptp_sp_malaria_ever is null;

-- iron_ifa_ever
update p 
set iron_ifa_ever = 1
from pregnancy_summary_staging p
where exists
	(select 1 from all_medication_dispensing d 
	where d.patient_id = p.patient_id
	and (cast(d.encounter_datetime as date) >= date_enrolled
		and cast(d.encounter_datetime as date) <= date_completed or date_completed is null)
	and drug_name in ('Ferrous sulfate 200mg + folic acid 250 microgram tablet',
					'Ferrous sulfate, 200mg (eq. 65mg elemental Fe) + folic acid 400 microgram tablet',
					'Ferrous sulfate, 200mg (eq. 65mg elemental Fe) tablet'));
update p set iron_ifa_ever = 0 from pregnancy_summary_staging p where total_anc_visits_recorded_in_emr > 0 and iron_ifa_ever is null;

-- arv_for_pmtct
update p 
set arv_for_pmtct = 1
from pregnancy_summary_staging p
where exists
	(select 1 from all_medication_dispensing d 
	where d.patient_id = p.patient_id
	and (cast(d.encounter_datetime as date) >= date_enrolled
		and cast(d.encounter_datetime as date) <= date_completed or date_completed is null)
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
update p set arv_for_pmtct = 0 from pregnancy_summary_staging p where total_anc_visits_recorded_in_emr > 0 and arv_for_pmtct is null;

-- malaria_treatment_during_antenatal
update p 
set malaria_treatment_during_antenatal = 1
from pregnancy_summary_staging p
where exists
	(select 1 from all_medication_dispensing d 
	where d.patient_id = p.patient_id
	and (cast(d.encounter_datetime as date) >= date_enrolled
		and cast(d.encounter_datetime as date) <= date_completed or date_completed is null)
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
update p set malaria_treatment_during_antenatal = 0 from pregnancy_summary_staging p where total_anc_visits_recorded_in_emr > 0 and malaria_treatment_during_antenatal is null;

-- fields from tests
update p 
set syphilis_test_ever = 1
from pregnancy_summary_staging p
where exists
	(select 1 from all_lab_results  l
	where l.patient_id = p.patient_id
	and (cast(l.specimen_collection_date as date) >= date_enrolled
		and cast(l.specimen_collection_date as date) <= date_completed or date_completed is null)
	and test = 'Rapid syphilis test');
update p set syphilis_test_ever = 0 from pregnancy_summary_staging p where total_anc_visits_recorded_in_emr > 0 and syphilis_test_ever is null;

update p 
set rdt_during_anc = 1
from pregnancy_summary_staging p
where exists
	(select 1 from all_lab_results  l
	where l.patient_id = p.patient_id
	and (cast(l.specimen_collection_date as date) >= date_enrolled
		and cast(l.specimen_collection_date as date) <= date_completed or date_completed is null)
	and test = 'Malaria RDT');
update p set rdt_during_anc = 0 from pregnancy_summary_staging p where total_anc_visits_recorded_in_emr > 0 and rdt_during_anc is null;

-- anc_visit1_weight_recorded
update p
set anc_visit1_weight_recorded = 1
from pregnancy_summary_staging p
where exists
	(select 1 from mch_anc_encounter e
	inner join all_visits v on v.visit_id = e.visit_id
	inner join all_vitals vit on vit.encounter_datetime >= v.visit_date_started 
		and (vit.encounter_datetime <= v.visit_date_stopped or v.visit_date_stopped is null)
		and vit.weight is not null
	where e.pregnancy_program_id = p.pregnancy_program_id 
	and e.index_asc_patient_program = 1);
update a set anc_visit1_weight_recorded = 0 from pregnancy_summary_staging a where total_anc_visits_recorded_in_emr > 0 and anc_visit1_weight_recorded is null;

update p 
set muac_measured = 1
from pregnancy_summary_staging p
where exists
	(select 1 from all_vitals  v
	where v.patient_id = p.patient_id
	and (cast(v.encounter_datetime as date) >= date_enrolled
		and cast(v.encounter_datetime as date) <= date_completed or date_completed is null)
	and muac_mm is not null);
update p set muac_measured = 0 from pregnancy_summary_staging p where total_anc_visits_recorded_in_emr > 0 and muac_measured is null;

-- hiv_result
update p 
set hiv_status = result
from pregnancy_summary_staging p 
inner join all_lab_results l on l.lab_obs_id =
    (select top 1 l2.lab_obs_id from all_lab_results l2
    where l2.patient_id = p.patient_id
    and test in ('HIV test result','Rapid test for HIV')
    order by l2.specimen_collection_date desc, l2.lab_obs_id desc);


-- anc_visit1_hiv_test
update p
set anc_visit1_hiv_test = 1
from pregnancy_summary_staging p
where exists
	(select 1 from mch_anc_encounter e
	inner join all_visits v on v.visit_id = e.visit_id
	inner join all_lab_results l on l.specimen_collection_date >= v.visit_date_started 
		and (l.specimen_collection_date <= v.visit_date_stopped or v.visit_date_stopped is null)
		and l.test in ('Rapid test for HIV','HIV test result')
	where e.pregnancy_program_id = p.pregnancy_program_id 
	and e.index_asc_patient_program = 1);
update a set anc_visit1_hiv_test = 0 from pregnancy_summary_staging a where total_anc_visits_recorded_in_emr > 0  and anc_visit1_hiv_test is null;

update p
set p.trimester_enrolled = e.trimester_enrolled
from pregnancy_summary_staging p 
inner join mch_anc_encounter e on e.encounter_id =
    (select top 1 e2.encounter_id from mch_anc_encounter e2
    where e2.pregnancy_program_id = p.pregnancy_program_id
    and trimester_enrolled is not null
    order by e2.encounter_datetime desc, e2.encounter_id desc);

-- update index asc/desc on appointments table
drop table if exists #derived_indexes;
select  pregnancy_program_id,
        ROW_NUMBER() over (PARTITION by patient_id order by date_enrolled, pregnancy_program_id) as index_asc,
        ROW_NUMBER() over (PARTITION by patient_id order by date_enrolled DESC, pregnancy_program_id DESC) as index_desc
into    #derived_indexes
from    pregnancy_summary_staging;

update t
set t.index_asc = i.index_asc,
    t.index_desc = i.index_desc
from pregnancy_summary_staging t inner join #derived_indexes i on i.pregnancy_program_id = t.pregnancy_program_id;

ALTER TABLE pregnancy_summary_staging
DROP COLUMN 
outcome,
current_state,
latest_lmp_entered,
estimated_delivery_date_entered,
delivery_num_alive,
delivery_num_fsb,
delivery_num_msb,
number_anc_visit_entered,
number_anc_visit_entered_datetime,
total_anc_visits_since_entry,
post_partum_state_date,
anc_state_date;

DROP TABLE IF EXISTS mch_pregnancy_summary;
EXEC sp_rename 'pregnancy_summary_staging', 'mch_pregnancy_summary';
