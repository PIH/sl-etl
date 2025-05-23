SET sql_safe_updates = 0;
SET SESSION group_concat_max_len = 100000;
set @partition = '${partitionNum}';

select program_workflow_state_id into @postpartum_state from program_workflow_state where uuid = 'a735b5f6-0b63-4d9a-ae2e-70d08c947aed';
select program_workflow_state_id into @anc_state from program_workflow_state where uuid = 'a83896bf-9094-4a3c-b843-e75509a52b32';
set @pregnancy_program_id = program('Pregnancy');
set @type_of_tx_workflow_id = (select program_workflow_id from program_workflow where uuid = '9a3f8252-1588-4f7b-b02c-9e99c437d4ef');
select program_workflow_state_id into @postpartum_state from program_workflow_state where uuid = 'a735b5f6-0b63-4d9a-ae2e-70d08c947aed';
select program_workflow_state_id into @anc_state from program_workflow_state where uuid = 'a83896bf-9094-4a3c-b843-e75509a52b32';


drop temporary table if exists temp_pregnancy_program;
create temporary table temp_pregnancy_program
(   patient_program_id                         int,
    emr_id                                     varchar(30),
    patient_id                                 int,    
    location_id                                int,
    reg_location                               varchar(255),
    date_enrolled                              date,
    date_completed                             date,
    outcome_concept_id                         int,
    outcome                                    varchar(255),
    current_state_concept_id                   int,
    current_state                              varchar(255),
	anc_start_date                             date,
	anc_end_date                               date,
	postpartum_start_date                      date,
	postpartum_end_date                        date,
	index_asc                                  int,
	index_desc                                 int);

insert into temp_pregnancy_program 
(patient_program_id, patient_id, location_id, date_enrolled, date_completed, outcome_concept_id)
select patient_program_id, patient_id, location_id, date_enrolled, date_completed, outcome_concept_id
from patient_program pp 
where pp.program_id = @pregnancy_program_id
and voided = 0;

update temp_pregnancy_program set emr_id = patient_identifier(patient_id, metadata_uuid('org.openmrs.module.emrapi', 'emr.primaryIdentifierType'));
update temp_pregnancy_program set reg_location = location_name(location_id);
update temp_pregnancy_program set outcome = concept_name(outcome_concept_id, 'en');

update temp_pregnancy_program p set p.current_state_concept_id = (
    select pws.concept_id
    from patient_state ps inner join program_workflow_state pws on ps.state = pws.program_workflow_state_id and pws.program_workflow_id = @type_of_tx_workflow_id
    where ps.patient_program_id = p.patient_program_id
    and ps.voided = 0
    and (ps.end_date is null or ps.end_date = p.date_completed)
    order by ps.start_date desc
    limit 1
);

update temp_pregnancy_program p set p.current_state = concept_name(current_state_concept_id, @locale); 

update temp_pregnancy_program p
set anc_start_date = 
	(select max(start_date) from patient_state ps
	where ps.patient_program_id = p.patient_program_id
	and ps.state = @anc_state 
	and ps.voided = 0);

update temp_pregnancy_program p
set anc_end_date = 
	(select max(end_date) from patient_state ps
	where ps.patient_program_id = p.patient_program_id
	and ps.state = @anc_state 
	and ps.voided = 0);

update temp_pregnancy_program p
set postpartum_start_date = 
	(select max(start_date) from patient_state ps
	where ps.patient_program_id = p.patient_program_id
	and ps.state = @postpartum_state 
	and ps.voided = 0);

update temp_pregnancy_program p
set postpartum_end_date = 
	(select max(end_date) from patient_state ps
	where ps.patient_program_id = p.patient_program_id
	and ps.state = @postpartum_state 
	and ps.voided = 0);

select
concat(@partition,'-',patient_program_id) as pregnancy_program_id,
emr_id,
concat(@partition,'-',patient_id) as patient_id,
reg_location,
date_enrolled,
date_completed,
outcome,
current_state,
anc_start_date,
anc_end_date,
postpartum_start_date,
postpartum_end_date,
index_asc,
index_desc
from temp_pregnancy_program;
