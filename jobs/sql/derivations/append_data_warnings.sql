drop table if exists #temp_data_warnings;
create table #temp_data_warnings
(
data_warning_id    int IDENTITY(1, 1) primary key,          
warning_type       varchar(255), 
event_type         varchar(255), 
patient_id         varchar(50),  
emr_id             varchar(50),  
visit_id           varchar(50),
encounter_id       varchar(50),  
patient_program_id varchar(50),  
encounter_datetime datetime,     
datetime_created   datetime,
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

-- --------------------------------------------------anc followup without intake
-- create temp table of latest encounters by type 
drop table if exists #temp_anc_encounter_latest;
select patient_id, emr_id, visit_id, visit_type, encounter_id, e.pregnancy_program_id, encounter_datetime, datetime_created, user_entered, site, partition_num 
into #temp_anc_encounter_latest
from anc_encounter e where encounter_id =
(select top 1 encounter_id from anc_encounter e2
where e2.pregnancy_program_id = e.pregnancy_program_id
and e2.visit_type = e.visit_type 
order by encounter_datetime desc, encounter_id desc);


insert into #temp_data_warnings (warning_type, event_type, patient_id, emr_id, visit_id, encounter_id, patient_program_id, 
encounter_datetime, datetime_created, user_entered, site, partition_num) 
select 'Followup without Intake', visit_type, patient_id, emr_id, visit_id, encounter_id, e.pregnancy_program_id, 
encounter_datetime, datetime_created, user_entered, site, partition_num  
from #temp_anc_encounter_latest e
where e.visit_type = 'ANC Followup'
and not exists
	(select 1 from #temp_anc_encounter_latest e2
	where e2.pregnancy_program_id = e.pregnancy_program_id 
	and e2.visit_type = 'ANC Intake');

-- visit details
update t
set t.visit_date_started = v.visit_date_started,
	t.visit_date_stopped = v.visit_date_stopped
from #temp_data_warnings t
inner join all_visits v on v.visit_id = t.visit_id;

insert into data_warnings
	(data_warning_id,
	warning_type,
	event_type,
	patient_id,
	emr_id,
	visit_id,
	encounter_id,
	patient_program_id,
	encounter_datetime,
	datetime_created,
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
	patient_id,
	emr_id,
	visit_id,
	encounter_id,
	patient_program_id,
	encounter_datetime,
	datetime_created,
	visit_date_started,
	visit_date_stopped,
	user_entered,
	other_details,
	site, 
	partition_num
from #temp_data_warnings;
