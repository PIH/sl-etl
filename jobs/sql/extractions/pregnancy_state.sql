set @partition = '${partitionNum}';
set @locale = global_property_value('default_locale', 'en');
select program_id into @pregnancyProgramId from program p where uuid = '6a5713c2-3fd5-46e7-8f25-36a0f7871e12';

drop temporary table if exists temp_ps;
create temporary table temp_ps
(pregnancy_program_state_id int(11) NOT NULL AUTO_INCREMENT, 
emr_id                      varchar(50),  
patient_id                  int(11),      
pregnancy_program_id        int(11),      
state_id                    int(11),      
state                       varchar(255), 
creator                     int(11),      
user_entered                varchar(255), 
date_entered                datetime,     
state_start_date            date,     
state_end_date              date,     
program_enrollment_date     datetime,         
program_completion_date     datetime,     
index_asc                   int,          
index_desc                  int,       
index_asc_patient_program   int,          
index_desc_patient_program  int,          
PRIMARY KEY (pregnancy_program_state_id)
);

insert into temp_ps (
	patient_id,
	pregnancy_program_id,
	state_id,
	creator,
	date_entered,
	state_start_date,
	state_end_date,
	program_enrollment_date,
	program_completion_date)
select pp.patient_id, 
	pp.patient_program_id, 
	ps.state, 
	ps.creator, 
	ps.date_created, 
	ps.start_date, 
	ps.end_date, 
	pp.date_enrolled, 
	pp.date_completed 
from patient_state ps
inner join patient_program pp on pp.patient_program_id = ps.patient_program_id 
	and pp.program_id  = @pregnancyProgramId
	and pp.voided = 0
where ps.voided = 0;

update temp_ps SET emr_id = patient_identifier(patient_id, 'c09a1d24-7162-11eb-8aa6-0242ac110002');

update temp_ps SET user_entered = person_name_of_user(creator);

update temp_ps t
inner join  program_workflow_state pws on t.state_id = pws.program_workflow_state_id
set state = concept_name(concept_id, @locale);

select
pregnancy_program_state_id,
emr_id,
concat(@partition, '-', patient_id) as patient_id,
concat(@partition, '-', pregnancy_program_id) as pregnancy_program_id,
state,
user_entered,
date_entered,
state_start_date,
state_end_date,
program_enrollment_date,
program_completion_date,
index_asc_patient,          
index_desc_patient,       
index_asc_patient_program,          
index_desc_patient_program
from temp_ps;
