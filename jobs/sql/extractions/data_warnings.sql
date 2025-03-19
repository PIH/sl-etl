set @partition = '${partitionNum}';

select encounter_type_id into @registrationEncType from encounter_type where uuid = '873f968a-73a8-4f9c-ac78-9f4778b751b6';

drop temporary table if exists temp_warnings;
create temporary table temp_warnings
(
data_warning_id int(11) NOT NULL AUTO_INCREMENT, 
warning_type       varchar(50),  
event_type         varchar(255), 
patient_id         int(11),      
emr_id             varchar(50), 
encounter_id       int(11),      
patient_program_id int(11),      
encounter_datetime datetime,     
datetime_created   datetime,     
user_entered       text,         
other_details      text,         
PRIMARY KEY (data_warning_id));

-- --------------------------------------------------------- registration field warnings
drop temporary table if exists temp_reg;
create temporary table temp_reg
(patient_id        int(11),
warning_type       varchar(255),
datetime_created   datetime, 
creator            int(11),  
user_entered       text,
encounter_id       int(11),
encounter_datetime datetime);    

insert into temp_reg (patient_id,datetime_created, creator, warning_type)
select patient_id,date_created, creator, 'blank emr_id'
from patient p 
where p.voided = 0 and patient_identifier(patient_id, metadata_uuid('org.openmrs.module.emrapi', 'emr.primaryIdentifierType')) is null;

insert into temp_reg (patient_id, datetime_created, creator, warning_type)
select patient_id, p.date_created, p.creator, 'blank birthdate'
from patient p
inner join person ps on ps.person_id = p.patient_id
where p.voided = 0 and birthdate is null;

insert into temp_reg (patient_id, datetime_created, creator, warning_type)
select patient_id, p.date_created, p.creator, 'blank gender'
from patient p
inner join person ps on ps.person_id = p.patient_id
where p.voided = 0 and gender is null;

insert into temp_reg (patient_id, datetime_created, creator, warning_type)
select patient_id, p.date_created, p.creator, 'death date before birthdate'
from patient p
inner join person ps on ps.person_id = p.patient_id
where p.voided = 0 
and ps.death_date < birthdate;

insert into temp_reg (patient_id, datetime_created, creator, warning_type)
select patient_id, p.date_created, p.creator, 'blank address'
from patient p
where p.voided = 0 
and not exists 
	(select 1 from person_address pa 
	where pa.person_id = p.patient_id
	and pa.voided = 0);

insert into temp_reg (patient_id, datetime_created, creator, warning_type)
select patient_id, p.date_created, p.creator, 'blank name'
from patient p
where p.voided = 0 
and not exists 
	(select 1 from person_name pn 
	where pn.person_id = p.patient_id
	and pn.voided = 0);

update temp_reg t 
set user_entered = person_name_of_user(creator);

update temp_reg t 
inner join encounter e on e.encounter_id = 
	(select e2.encounter_id from encounter e2
	where e2.patient_id = t.patient_id
	and e2.encounter_type = @registrationEncType
	order by encounter_datetime asc, encounter_id asc
	limit 1)
set t.encounter_id = e.encounter_id,
	t.encounter_datetime = e.encounter_datetime;

insert into temp_warnings (patient_id,datetime_created, user_entered, encounter_id, encounter_datetime, warning_type, event_type)
select patient_id,datetime_created, user_entered, encounter_id, encounter_datetime, warning_type, 'patient registration' 
from temp_reg;

-- ------------------------ common fields
set @primary_emr_id_type_uuid =  metadata_uuid('org.openmrs.module.emrapi', 'emr.primaryIdentifierType');
update temp_warnings t 
set emr_id = patient_identifier(patient_id, @primary_emr_id_type_uuid)
where t.warning_type <> 'blank emr_id';

-- final select
select
	data_warning_id,
	warning_type,
	event_type,
	concat(@partition, '-', patient_id) as patient_id,
	emr_id,
	concat(@partition, '-', encounter_id) as encounter_id,
	concat(@partition, '-', patient_program_id) as patient_program_id,
	encounter_datetime,
	datetime_created,
	user_entered,
	other_details 
from temp_warnings;
