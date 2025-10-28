-- Last reviewed MS 8/1/2024

set @partition = '${partitionNum}';
SELECT program_id  INTO @ncd_program FROM program p WHERE uuid = '515796ec-bf3a-11e7-abc4-cec278b6b50a';
select program_workflow_id into @ncdWorkflow from program_workflow where uuid = '51579bce-bf3a-11e7-abc4-cec278b6b50a';
SET @locale='en';

DROP TABLE IF EXISTS ncd_program;
CREATE TEMPORARY TABLE ncd_program
(
    patient_id           int,
    patient_program_id   int,
    emr_id               varchar(30),
    program_name         varchar(50),
    date_enrolled        date,
    date_completed       date,
    final_program_status varchar(100),
    clinical_status      varchar(50),
    user_entered         varchar(50),
    index_asc            int,
    index_desc           int
);

insert into ncd_program(patient_id, patient_program_id, emr_id, program_name, date_enrolled, date_completed, final_program_status, clinical_status, user_entered)
select  pp.patient_id,
        pp.patient_program_id,
        patient_identifier(pp.patient_id, metadata_uuid('org.openmrs.module.emrapi', 'emr.primaryIdentifierType')),
		p.name,
		pp.date_enrolled,
		pp.date_completed,
		concept_name(pp.outcome_concept_id, @locale),
		currentProgramState(pp.patient_program_id, @ncdWorkflow, @locale),
		username(pp.creator)
from patient_program pp
inner join program p on pp.program_id = p.program_id
where pp.voided = 0
AND pp.program_id = @ncd_program;

select 
	if(@partition REGEXP '^[0-9]+$' = 1,concat(@partition,'-',patient_program_id),patient_program_id) "ncd_program_id",
	if(@partition REGEXP '^[0-9]+$' = 1,concat(@partition,'-',patient_id),patient_id) "patient_id",
       emr_id,
       program_name,
       date_enrolled,
       date_completed,
       final_program_status,
       clinical_status,
       user_entered,
       index_asc,
       index_desc
from ncd_program;
