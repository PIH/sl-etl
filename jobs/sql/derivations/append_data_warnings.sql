-- note that this script APPENDS to the data_warnings table that is created in an export

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

-- set data warning_id to continue from the current max 
declare @maxId int 
set @maxId = (select max(data_warning_id) + 1 from data_warnings)
dbcc checkident(#temp_data_warnings, reseed, @maxId);

-- -------------------------------------------------- followup without intake
-- anc followup
drop table if exists #temp_anc_encounter_latest;
select patient_id, emr_id, visit_id, visit_type, encounter_id, e.pregnancy_program_id, encounter_datetime, datetime_entered, user_entered, site, partition_num 
into #temp_anc_encounter_latest
from anc_encounter e where encounter_id =
(select top 1 encounter_id from anc_encounter e2
where e2.pregnancy_program_id = e.pregnancy_program_id
and e2.visit_type = e.visit_type 
order by encounter_datetime desc, encounter_id desc);


insert into #temp_data_warnings (warning_type, event_type, patient_id, emr_id, visit_id, encounter_id, patient_program_id, 
encounter_datetime, datetime_entered, user_entered, site, partition_num) 
select 'Followup without Intake', visit_type, patient_id, emr_id, visit_id, encounter_id, e.pregnancy_program_id, 
encounter_datetime, datetime_entered, user_entered, site, partition_num  
from #temp_anc_encounter_latest e
where e.visit_type = 'ANC Followup'
and not exists
	(select 1 from #temp_anc_encounter_latest e2
	where e2.pregnancy_program_id = e.pregnancy_program_id 
	and e2.encounter_datetime < e.encounter_datetime
	and e2.visit_type = 'ANC Intake');

-- ncd_followup
drop table if exists #temp_ncd_encounter_latest;
select patient_id, emr_id, visit_id, encounter_type, encounter_id, e.ncd_program_id, encounter_datetime, date_created, creator, site, partition_num 
into #temp_ncd_encounter_latest
from ncd_encounter e where encounter_id =
(select top 1 encounter_id from ncd_encounter e2
where e2.ncd_program_id = e.ncd_program_id
and e2.encounter_type = e.encounter_type 
order by encounter_datetime desc, encounter_id desc);

insert into #temp_data_warnings (warning_type, event_type, patient_id, emr_id, visit_id, encounter_id, patient_program_id, 
encounter_datetime, datetime_entered, user_entered, site, partition_num) 
select 'Followup without Intake', encounter_type, patient_id, emr_id, visit_id, encounter_id, e.ncd_program_id, 
encounter_datetime, date_created, creator, site, partition_num  
from #temp_ncd_encounter_latest e
where e.encounter_type = 'NCD Followup Consult'
and not exists
	(select 1 from #temp_ncd_encounter_latest e2
	where e2.ncd_program_id = e.ncd_program_id 
	and e2.encounter_datetime < e.encounter_datetime
	and e2.encounter_type = 'NCD Initial Consult');

-- mh_followup
drop table if exists #temp_mh_encounter_latest;
select patient_id, emr_id, visit_id, encounter_type, encounter_id, e.mh_program_id, encounter_datetime, date_created, user_entered, 
site, partition_num 
into #temp_mh_encounter_latest
from mh_encounters e where encounter_id =
(select top 1 encounter_id from mh_encounters e2
where e2.mh_program_id = e.mh_program_id
and e2.encounter_type = e.encounter_type 
order by encounter_datetime desc, encounter_id desc);

insert into #temp_data_warnings (warning_type, event_type, patient_id, emr_id, visit_id, encounter_id, patient_program_id, 
encounter_datetime, datetime_entered, user_entered, site, partition_num) 
select 'Followup without Intake', encounter_type, patient_id, emr_id, visit_id, encounter_id, e.mh_program_id, 
encounter_datetime, date_created, user_entered, site, partition_num  
from #temp_mh_encounter_latest e
where e.encounter_type = 'Mental Health Follow-up'
and not exists
	(select 1 from #temp_mh_encounter_latest e2
	where e2.mh_program_id = e.mh_program_id 
	and e2.encounter_datetime < e.encounter_datetime
	and e2.encounter_type = 'Mental Health Consult');

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
e.encounter_datetime, e.date_entered, e.user_entered, e.site, e.partition_num, 
concat('number of encounters: ', t.count)
from all_encounters e
inner join #temp_dup_encounters t on t.max_encounter_id = e.encounter_id;

-- -------------------------------------------------- duplicate encounters within visit

drop table if exists #temp_dup_encounters;
select e.patient_id, visit_id, encounter_type, max(e.encounter_id) max_encounter_id, count(*) count
into #temp_dup_encounters
from all_encounters e
where e.encounter_type in
('ANC Followup',
'Check-In',
'Emergency Triage',
'Maternal Discharge',
'Mental Health Initial Consult',
'Mental Health Follow-up',
'NCD Followup Consult',
'NCD Initial Consult',
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
e.encounter_datetime, e.date_entered, e.user_entered, e.site, e.partition_num, 
concat('number of encounters: ', t.count)
from all_encounters e
inner join #temp_dup_encounters t on t.max_encounter_id = e.encounter_id;

-- -------------------------------------------------- duplicate encounters within program
-- anc intake
drop table if exists #temp_dup_encounters;
select e.patient_id, pregnancy_program_id, max(e.encounter_id) max_encounter_id, count(*) count
into #temp_dup_encounters
from anc_encounter e
where e.visit_type in ('ANC Intake')
group by e.patient_id, e.pregnancy_program_id
having count(*) > 1;

insert into #temp_data_warnings (warning_type, event_type, patient_id, emr_id, visit_id, encounter_id, patient_program_id,
encounter_datetime, datetime_entered, user_entered, site, partition_num, other_details) 
select 'Duplicate encounters within program', e.visit_type, e.patient_id, e.emr_id, e.visit_id, e.encounter_id, e.pregnancy_program_id,  
e.encounter_datetime, e.datetime_entered, e.user_entered, e.site, e.partition_num, 
concat('number of encounters: ', t.count)
from anc_encounter e
inner join #temp_dup_encounters t on t.max_encounter_id = e.encounter_id;

-- labor and delivery summary
drop table if exists #temp_dup_encounters;
select e.patient_id, pregnancy_program_id, max(e.encounter_id) max_encounter_id, count(*) count
into #temp_dup_encounters
from labor_summary_encounter e
group by e.patient_id, e.pregnancy_program_id
having count(*) > 1;


insert into #temp_data_warnings (warning_type, event_type, patient_id, emr_id, visit_id, encounter_id, patient_program_id,
encounter_datetime, datetime_entered, user_entered, site, partition_num, other_details) 
select 'Duplicate encounters within program', 'Labor and Delivery Summary', e.patient_id, e.emr_id, e.visit_id, e.encounter_id, e.pregnancy_program_id,  
e.encounter_datetime, e.datetime_entered, e.user_entered, e.site, e.partition_num,
concat('number of encounters: ', t.count)
from labor_summary_encounter e
inner join #temp_dup_encounters t on t.max_encounter_id = e.encounter_id;

-- mch delivery
drop table if exists #temp_dup_encounters;
select e.patient_id, pregnancy_program_id, max(e.encounter_id) max_encounter_id, count(*) count
into #temp_dup_encounters
from mch_delivery e
group by e.patient_id, e.pregnancy_program_id
having count(*) > 1;

insert into #temp_data_warnings (warning_type, event_type, patient_id, emr_id,  visit_id, 
encounter_id, encounter_datetime, patient_program_id, datetime_entered, user_entered, 
site, partition_num, other_details) 
select 'Duplicate encounters within program', 'MCH Delivery', e.patient_id, e.emr_id, e.visit_id, 
e.encounter_id, encounter_datetime, e.pregnancy_program_id, e.date_created, e.user_entered, e.site, e.partition_num,
concat('number of encounters: ', t.count)
from mch_delivery e
inner join #temp_dup_encounters t on t.max_encounter_id = e.encounter_id;

-- -------------------------------------------------- inpatient encounters without admission
drop table if exists #temp_all_encounters_latest
select patient_id, emr_id, visit_id, encounter_type, encounter_id, encounter_datetime, date_entered, user_entered, site, partition_num 
into #temp_all_encounters_latest
from all_encounters e where encounter_id =
(select top 1 encounter_id from all_encounters e2
where e2.visit_id = e.visit_id
and encounter_type in
('Labour Progress',
'Labour and Delivery Summary',
'Postpartum Daily Progress',
'Maternal Discharge',
'Newborn Assessment',
'Newborn Initial',
'Newborn Daily Progress',
'Newborn Discharge')
order by encounter_datetime desc, encounter_id desc);


insert into #temp_data_warnings (warning_type, event_type, patient_id, emr_id, visit_id, encounter_id, 
encounter_datetime, datetime_entered, user_entered, site, partition_num) 
select 'Inpatient encounters without admission', encounter_type, patient_id, emr_id, visit_id, encounter_id,
encounter_datetime, date_entered, user_entered, site, partition_num  
from #temp_all_encounters_latest e
where not exists
	(select 1 from all_encounters e2
	where e2.visit_id = e.visit_id 
	and e2.encounter_datetime < e.encounter_datetime
	and e2.encounter_type = 'Admission');

-- -------------------------------------------------- duplicate emr_id
insert into #temp_data_warnings (warning_type, event_type, patient_id, emr_id, encounter_datetime, datetime_entered,
user_entered, site, partition_num, other_details) 
select 'Duplicate emr_ids', 'patient_registration',p.patient_id, p.emr_id, p.registration_date, p.date_registration_entered,
p.user_entered, p.site, p.partition_num, concat('other patient_id: ',p2.patient_id)
from all_patients p
inner join all_patients p2 on p2.emr_id = p.emr_id and p2.patient_id <> p.patient_id;

-- -------------------------------------------------- visit details
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
	data_warning_id, 
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
