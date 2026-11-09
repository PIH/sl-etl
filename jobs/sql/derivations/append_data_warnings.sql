-- note that this script APPENDS to the data_warnings table that is created in an extract
-- avoid semicolons inside comments and strings: petl splits this file on the semicolon delimiter

-- --------------------------------------------------- remove any previously appended rows (SL-1481)
-- each site refresh replaces its own partition of data_warnings, but if a site failed to refresh
-- its old appended rows would still be there, so clear them first to avoid duplicates
delete from data_warnings
where warning_type in (
	'Followup without Intake',
	'Intake after Followup',
	'Duplicate encounters for patient',
	'Duplicate encounters within visit',
	'Duplicate encounters within program',
	'Inpatient encounters before admission',
	'Newborn Assessment without admission',
	'Duplicate emr_ids',
	'Blank program ID',
	'return_visit_date not in future');

drop table if exists #temp_data_warnings;
create table #temp_data_warnings
(
data_warning_id    int IDENTITY(1,1) primary key,
warning_type       varchar(255),
event_type         varchar(255),
event_datetime     datetime,
patient_id         varchar(50),
emr_id             varchar(50),
visit_id           varchar(50),
encounter_id       varchar(50),
patient_program_id varchar(50),
encounter_datetime datetime,
datetime_entered   datetime,
visit_date_started datetime,
visit_date_stopped datetime,
user_entered       text,
other_details      text,
site               varchar(100),
partition_num      int
);


-- -------------------------------------------------- first followup per program (SL-1481)
-- computed once and reused by both 'Followup without Intake' and 'Intake after Followup'.
-- encounters with no program id are skipped here (they are covered by 'Blank program ID')

-- anc
drop table if exists #first_anc_fu;
select x.patient_id, x.emr_id, x.visit_id, x.visit_type, x.encounter_id, x.pregnancy_program_id,
x.encounter_datetime, x.datetime_entered, x.user_entered, x.site, x.partition_num
into #first_anc_fu
from
	(select e.*,
		row_number() over (partition by e.pregnancy_program_id order by e.encounter_datetime, e.encounter_id) as rn
	from mch_anc_encounter e
	where e.visit_type = 'ANC Followup'
	and e.pregnancy_program_id is not null) x
where x.rn = 1;

-- ncd
drop table if exists #first_ncd_fu;
select x.patient_id, x.emr_id, x.visit_id, x.encounter_type, x.encounter_id, x.ncd_program_id,
x.encounter_datetime, x.datetime_entered, x.user_entered, x.site, x.partition_num
into #first_ncd_fu
from
	(select e.patient_id, e.emr_id, e.visit_id, e.encounter_type, e.encounter_id, e.ncd_program_id,
		e.encounter_datetime, e.datetime_entered, e.user_entered, e.site, e.partition_num,
		row_number() over (partition by e.ncd_program_id order by e.encounter_datetime, e.encounter_id) as rn
	from ncd_encounter e
	where e.encounter_type in ('NCD Followup Consult', 'NCD Followup Part 1 only', 'NCD Followup Part 2 only')
	and e.ncd_program_id is not null) x
where x.rn = 1;

-- mh
drop table if exists #first_mh_fu;
select x.patient_id, x.emr_id, x.visit_id, x.encounter_type, x.encounter_id, x.mh_program_id,
x.encounter_datetime, x.datetime_entered, x.user_entered, x.site, x.partition_num
into #first_mh_fu
from
	(select e.patient_id, e.emr_id, e.visit_id, e.encounter_type, e.encounter_id, e.mh_program_id,
		e.encounter_datetime, e.datetime_entered, e.user_entered, e.site, e.partition_num,
		row_number() over (partition by e.mh_program_id order by e.encounter_datetime, e.encounter_id) as rn
	from mh_encounter e
	where e.encounter_type = 'Mental Health Follow-up'
	and e.mh_program_id is not null) x
where x.rn = 1;

-- -------------------------------------------------- followup without intake
-- flags the first followup in each program when the program has no intake at all.
-- if the intake exists but came later, only the 'Intake after Followup' warning is raised (SL-1481)

-- anc followup
insert into #temp_data_warnings (warning_type, event_type, patient_id, emr_id, visit_id, encounter_id, patient_program_id,
encounter_datetime, datetime_entered, user_entered, site, partition_num)
select 'Followup without Intake', f.visit_type, f.patient_id, f.emr_id, f.visit_id, f.encounter_id, f.pregnancy_program_id,
f.encounter_datetime, f.datetime_entered, f.user_entered, f.site, f.partition_num
from #first_anc_fu f
where not exists
	(select 1 from mch_anc_encounter e2
	where e2.pregnancy_program_id = f.pregnancy_program_id
	and e2.visit_type = 'ANC Intake');

-- ncd_followup
insert into #temp_data_warnings (warning_type, event_type, patient_id, emr_id, visit_id, encounter_id, patient_program_id,
encounter_datetime, datetime_entered, user_entered, site, partition_num)
select 'Followup without Intake', f.encounter_type, f.patient_id, f.emr_id, f.visit_id, f.encounter_id, f.ncd_program_id,
f.encounter_datetime, f.datetime_entered, f.user_entered, f.site, f.partition_num
from #first_ncd_fu f
where not exists
	(select 1 from ncd_encounter e2
	where e2.ncd_program_id = f.ncd_program_id
	and e2.encounter_type in ('NCD Initial Consult','NCD Initial Part 1 only','NCD Initial Part 2 only'));

-- mh_followup
insert into #temp_data_warnings (warning_type, event_type, patient_id, emr_id, visit_id, encounter_id, patient_program_id,
encounter_datetime, datetime_entered, user_entered, site, partition_num)
select 'Followup without Intake', f.encounter_type, f.patient_id, f.emr_id, f.visit_id, f.encounter_id, f.mh_program_id,
f.encounter_datetime, f.datetime_entered, f.user_entered, f.site, f.partition_num
from #first_mh_fu f
where not exists
	(select 1 from mh_encounter e2
	where e2.mh_program_id = f.mh_program_id
	and e2.encounter_type = 'Mental Health Consult');

-- -------------------------------------------------- intake after followup (SL-1481)
-- every intake that has a followup before it in the same program.
-- other_details shows the earliest followup that came before the intake

-- anc
insert into #temp_data_warnings (warning_type, event_type, patient_id, emr_id, visit_id, encounter_id, patient_program_id,
encounter_datetime, datetime_entered, user_entered, site, partition_num, other_details)
select 'Intake after Followup', e.visit_type, e.patient_id, e.emr_id, e.visit_id, e.encounter_id, e.pregnancy_program_id,
e.encounter_datetime, e.datetime_entered, e.user_entered, e.site, e.partition_num,
concat('earlier followup: ', f.encounter_datetime, ' (encounter_id ', f.encounter_id, ')')
from mch_anc_encounter e
inner join #first_anc_fu f on f.pregnancy_program_id = e.pregnancy_program_id
	and f.encounter_datetime < e.encounter_datetime
where e.visit_type = 'ANC Intake';

-- ncd
insert into #temp_data_warnings (warning_type, event_type, patient_id, emr_id, visit_id, encounter_id, patient_program_id,
encounter_datetime, datetime_entered, user_entered, site, partition_num, other_details)
select 'Intake after Followup', e.encounter_type, e.patient_id, e.emr_id, e.visit_id, e.encounter_id, e.ncd_program_id,
e.encounter_datetime, e.datetime_entered, e.user_entered, e.site, e.partition_num,
concat('earlier followup: ', f.encounter_datetime, ' (encounter_id ', f.encounter_id, ')')
from ncd_encounter e
inner join #first_ncd_fu f on f.ncd_program_id = e.ncd_program_id
	and f.encounter_datetime < e.encounter_datetime
where e.encounter_type in ('NCD Initial Consult','NCD Initial Part 1 only','NCD Initial Part 2 only');

-- mh
insert into #temp_data_warnings (warning_type, event_type, patient_id, emr_id, visit_id, encounter_id, patient_program_id,
encounter_datetime, datetime_entered, user_entered, site, partition_num, other_details)
select 'Intake after Followup', e.encounter_type, e.patient_id, e.emr_id, e.visit_id, e.encounter_id, e.mh_program_id,
e.encounter_datetime, e.datetime_entered, e.user_entered, e.site, e.partition_num,
concat('earlier followup: ', f.encounter_datetime, ' (encounter_id ', f.encounter_id, ')')
from mh_encounter e
inner join #first_mh_fu f on f.mh_program_id = e.mh_program_id
	and f.encounter_datetime < e.encounter_datetime
where e.encounter_type = 'Mental Health Consult';

-- -------------------------------------------------- duplicate encounters ever
drop table if exists #temp_dup_encounters;
select e.patient_id, max(e.encounter_id) max_encounter_id, count(*) count
into #temp_dup_encounters
from all_encounters e
where e.encounter_type in ('Newborn Assessment')
group by e.patient_id
having count(*) > 1;

insert into #temp_data_warnings (warning_type, event_type, patient_id, emr_id, visit_id, encounter_id,
encounter_datetime, datetime_entered, user_entered, site, partition_num, other_details)
select 'Duplicate encounters for patient', e.encounter_type, e.patient_id, e.emr_id, e.visit_id, e.encounter_id,
e.encounter_datetime, e.datetime_entered, e.user_entered, e.site, e.partition_num,
concat('number of encounters: ', t.count)
from all_encounters e
inner join #temp_dup_encounters t on t.max_encounter_id = e.encounter_id;

-- -------------------------------------------------- duplicate encounters within visit
-- (SL-1481) added Admission and ANC Intake, corrected the MH intake name, skip encounters with no visit
drop table if exists #temp_dup_encounters;
select e.patient_id, visit_id, encounter_type, max(e.encounter_id) max_encounter_id, count(*) count
into #temp_dup_encounters
from all_encounters e
where e.visit_id is not null
and e.encounter_type in
('Admission',
'ANC Intake',
'ANC Followup',
'Check-In',
'Emergency Triage',
'Maternal Discharge',
'Mental Health Consult',
'Mental Health Follow-up',
'NCD Followup Consult',
'NCD Followup Part 1 only',
'NCD Followup Part 2 only',
'NCD Initial Consult',
'NCD Initial Part 1 only',
'NCD Initial Part 2 only',
'Newborn Discharge',
'Newborn Initial',
'NICU Triage',
'Sierra Leone Maternal Admission',
'Sierra Leone Maternal Check-in',
'Sierra Leone MCH Triage',
'Sierra Leone Outpatient Followup',
'Sierra Leone Outpatient Initial',
'Exit from Inpatient Care')
group by e.patient_id, e.visit_id, encounter_type
having count(*) > 1;


insert into #temp_data_warnings (warning_type, event_type, patient_id, emr_id, visit_id, encounter_id,
encounter_datetime, datetime_entered, user_entered, site, partition_num, other_details)
select 'Duplicate encounters within visit', e.encounter_type, e.patient_id, e.emr_id, e.visit_id, e.encounter_id,
e.encounter_datetime, e.datetime_entered, e.user_entered, e.site, e.partition_num,
concat('number of encounters: ', t.count)
from all_encounters e
inner join #temp_dup_encounters t on t.max_encounter_id = e.encounter_id;

-- -------------------------------------------------- duplicate encounters within program
-- encounters with no program id are skipped (they are covered by 'Blank program ID') (SL-1481)
-- anc intake
drop table if exists #temp_dup_encounters;
select e.patient_id, pregnancy_program_id, max(e.encounter_id) max_encounter_id, count(*) count
into #temp_dup_encounters
from mch_anc_encounter e
where e.visit_type in ('ANC Intake')
and e.pregnancy_program_id is not null
group by e.patient_id, e.pregnancy_program_id
having count(*) > 1;

insert into #temp_data_warnings (warning_type, event_type, patient_id, emr_id, visit_id, encounter_id, patient_program_id,
encounter_datetime, datetime_entered, user_entered, site, partition_num, other_details)
select 'Duplicate encounters within program', e.visit_type, e.patient_id, e.emr_id, e.visit_id, e.encounter_id, e.pregnancy_program_id,
e.encounter_datetime, e.datetime_entered, e.user_entered, e.site, e.partition_num,
concat('number of encounters: ', t.count)
from mch_anc_encounter e
inner join #temp_dup_encounters t on t.max_encounter_id = e.encounter_id;

-- labor and delivery summary
drop table if exists #temp_dup_encounters;
select e.patient_id, pregnancy_program_id, max(e.encounter_id) max_encounter_id, count(*) count
into #temp_dup_encounters
from mch_labor_summary_encounter e
where e.pregnancy_program_id is not null
group by e.patient_id, e.pregnancy_program_id
having count(*) > 1;


insert into #temp_data_warnings (warning_type, event_type, patient_id, emr_id, visit_id, encounter_id, patient_program_id,
encounter_datetime, datetime_entered, user_entered, site, partition_num, other_details)
select 'Duplicate encounters within program', 'Labor and Delivery Summary', e.patient_id, e.emr_id, e.visit_id, e.encounter_id, e.pregnancy_program_id,
e.encounter_datetime, e.datetime_entered, e.user_entered, e.site, e.partition_num,
concat('number of encounters: ', t.count)
from mch_labor_summary_encounter e
inner join #temp_dup_encounters t on t.max_encounter_id = e.encounter_id;

-- mch delivery
drop table if exists #temp_dup_encounters;
select e.patient_id, pregnancy_program_id, max(e.encounter_id) max_encounter_id, count(*) count
into #temp_dup_encounters
from mch_delivery e
where e.pregnancy_program_id is not null
group by e.patient_id, e.pregnancy_program_id
having count(*) > 1;

insert into #temp_data_warnings (warning_type, event_type, patient_id, emr_id,  visit_id,
encounter_id, encounter_datetime, patient_program_id, datetime_entered, user_entered,
site, partition_num, other_details)
select 'Duplicate encounters within program', 'MCH Delivery', e.patient_id, e.emr_id, e.visit_id,
e.encounter_id, encounter_datetime, e.pregnancy_program_id, e.datetime_entered, e.user_entered, e.site, e.partition_num,
concat('number of encounters: ', t.count)
from mch_delivery e
inner join #temp_dup_encounters t on t.max_encounter_id = e.encounter_id;

-- -------------------------------------------------- inpatient encounters without admission
-- find the earliest encounter for each visit of the specified types
-- (SL-1481) added Exit from Inpatient Care and Transfer, and uses row_number instead of a
-- per-row correlated subquery (all_encounters has no indexes, so that was a full scan per row)
drop table if exists #temp_all_encounters_earliest;
select x.patient_id, x.emr_id, x.visit_id, x.encounter_type, x.encounter_id, x.encounter_datetime,
x.datetime_entered, x.user_entered, x.site, x.partition_num
into #temp_all_encounters_earliest
from
	(select e.patient_id, e.emr_id, e.visit_id, e.encounter_type, e.encounter_id, e.encounter_datetime,
		e.datetime_entered, e.user_entered, e.site, e.partition_num,
		row_number() over (partition by e.visit_id order by e.encounter_datetime, e.encounter_id) as rn
	from all_encounters e
	where e.visit_id is not null
	and e.encounter_type in
	('Labour Progress',
	'Labour and Delivery Summary',
	'Postpartum Daily Progress',
	'Maternal Discharge',
	'Newborn Initial',
	'Newborn Daily Progress',
	'Newborn Discharge',
	'Exit from Inpatient Care',
	'Transfer')) x
where x.rn = 1;

--  flag if there is no admission encounter on or before the encounter we found previously
insert into #temp_data_warnings (warning_type, event_type, patient_id, emr_id, visit_id, encounter_id,
encounter_datetime, datetime_entered, user_entered, site, partition_num)
select 'Inpatient encounters before admission', encounter_type, patient_id, emr_id, visit_id, encounter_id,
encounter_datetime, datetime_entered, user_entered, site, partition_num
from #temp_all_encounters_earliest e
where not exists
	(select 1 from all_encounters e2
	where e2.visit_id = e.visit_id
	and e2.encounter_datetime <= e.encounter_datetime
	and e2.encounter_type = 'Admission');

-- flag any newborn encounters without admission encounter in the same visit
insert into #temp_data_warnings (warning_type, event_type, patient_id, emr_id, visit_id, encounter_id,
                                 encounter_datetime, datetime_entered, user_entered, site, partition_num)
select 'Newborn Assessment without admission' , 'Newborn Assessment', patient_id, emr_id, visit_id, encounter_id,
encounter_datetime, datetime_entered, user_entered, site, partition_num
from all_encounters e
where encounter_type = 'Newborn Assessment'
and not exists
	(select 1 from all_encounters e2
	where e2.visit_id = e.visit_id
	and e2.encounter_type = 'Admission'
	);


-- -------------------------------------------------- duplicate emr_id
insert into #temp_data_warnings (warning_type, event_type, patient_id, emr_id, encounter_datetime, datetime_entered,
user_entered, site, partition_num, other_details)
select 'Duplicate emr_ids', 'patient_registration',p.patient_id, p.emr_id, p.registration_date, p.date_registration_entered,
p.user_entered, p.site, p.partition_num, concat('other patient_id: ',p2.patient_id)
from all_patients p
inner join all_patients p2 on p2.emr_id = p.emr_id and p2.patient_id <> p.patient_id
where p.emr_id is not null; -- (SL-1481)

-- -------------------------------------------------- blank program ID (SL-1479)
-- MCH encounters that are not linked to a pregnancy program (e.g. ANC followup entered without an intake)
-- one row per encounter, union de-duplicates encounters that appear in more than one MCH table
drop table if exists #temp_blank_program_encounters;
select encounter_id into #temp_blank_program_encounters from mch_anc_encounter where pregnancy_program_id is null
union select encounter_id from mch_pnc_encounter where pregnancy_program_id is null
union select encounter_id from mch_labor_progress_encounter where pregnancy_program_id is null
union select encounter_id from mch_labor_summary_encounter where pregnancy_program_id is null
union select encounter_id from mch_delivery_summary_encounter where pregnancy_program_id is null
union select encounter_id from mch_delivery where pregnancy_program_id is null
union select encounter_id from mch_postpartum_daily_encounter where pregnancy_program_id is null;

insert into #temp_data_warnings (warning_type, event_type, patient_id, emr_id, visit_id, encounter_id,
encounter_datetime, datetime_entered, user_entered, site, partition_num)
select 'Blank program ID', e.encounter_type, e.patient_id, e.emr_id, e.visit_id, e.encounter_id,
e.encounter_datetime, e.datetime_entered, e.user_entered, e.site, e.partition_num
from all_encounters e
inner join #temp_blank_program_encounters t on t.encounter_id = e.encounter_id;

-- --------------------------------------------------- return_visit_date not in future
insert into #temp_data_warnings (warning_type, event_type, patient_id, emr_id, visit_id, encounter_id,
encounter_datetime, datetime_entered, user_entered, site, partition_num)
select 'return_visit_date not in future', visit_type, patient_id, emr_id, visit_id, encounter_id,
encounter_datetime, datetime_entered, user_entered, site, partition_num
from mch_anc_encounter
where return_visit_date <= encounter_datetime;

insert into #temp_data_warnings (warning_type, event_type, patient_id, emr_id, visit_id, encounter_id,
encounter_datetime, datetime_entered, user_entered, site, partition_num)
select 'return_visit_date not in future', encounter_type, patient_id, emr_id, visit_id, encounter_id,
encounter_datetime, datetime_entered, user_entered, site, partition_num
from mh_encounter
where return_visit_date <= encounter_datetime;

insert into #temp_data_warnings (warning_type, event_type, patient_id, emr_id, visit_id, encounter_id,
encounter_datetime, datetime_entered, user_entered, site, partition_num)
select 'return_visit_date not in future', encounter_type, patient_id, emr_id, visit_id, encounter_id,
encounter_datetime, datetime_entered, user_entered, site, partition_num
from ncd_encounter
where next_appointment_date <= encounter_datetime;

insert into #temp_data_warnings (warning_type, event_type, patient_id, emr_id, visit_id, encounter_id,
encounter_datetime, datetime_entered, user_entered, site, partition_num)
select 'return_visit_date not in future', 'Maternal Discharge', patient_id, emr_id, visit_id, encounter_id,
encounter_datetime, datetime_entered, user_entered, site, partition_num
from mch_maternal_discharge_encounter
where next_appointment_date <= encounter_datetime;

insert into #temp_data_warnings (warning_type, event_type, patient_id, emr_id, visit_id, encounter_id,
encounter_datetime, datetime_entered, user_entered, site, partition_num)
select 'return_visit_date not in future', encounter_type, patient_id, emr_id, visit_id, encounter_id,
encounter_datetime, datetime_entered, user_entered, site, partition_num
from outpatient_encounters
where next_visit_date <= encounter_datetime;

-- -------------------------------------------------- visit details
-- (SL-1481) moved after all inserts so return_visit_date warnings also get visit dates
update t
set t.visit_date_started = v.visit_date_started,
	t.visit_date_stopped = v.visit_date_stopped
from #temp_data_warnings t
inner join all_visits v on v.visit_id = t.visit_id;

-- -------------------------------------------------- event datetime
update t
set t.event_datetime =
CASE
	when encounter_datetime is not null then encounter_datetime
	when visit_date_started is not null then visit_date_started
	else datetime_entered
END
from  #temp_data_warnings t;

-- --------------------------------------------------- Final insert
insert into data_warnings
	(data_warning_id,
	warning_type,
	event_type,
	event_datetime,
	patient_id,
	emr_id,
	visit_id,
	encounter_id,
	patient_program_id,
	encounter_datetime,
	datetime_entered,
	visit_date_started,
	visit_date_stopped,
	user_entered,
	other_details,
	site,
	partition_num)
select
	(select isnull(max(data_warning_id), 0) from data_warnings) + data_warning_id,
	warning_type,
	event_type,
	event_datetime,
	patient_id,
	emr_id,
	visit_id,
	encounter_id,
	patient_program_id,
	encounter_datetime,
	datetime_entered,
	visit_date_started,
	visit_date_stopped,
	user_entered,
	other_details,
	site,
	partition_num
from #temp_data_warnings;
