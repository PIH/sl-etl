
-- All Programs 
set @partition = '${partitionNum}';
SELECT patient_identifier_type_id INTO @identifier_type FROM patient_identifier_type pit WHERE uuid ='1a2acce0-7426-11e5-a837-0800200c9a66';
SELECT patient_identifier_type_id INTO @kgh_identifier_type FROM patient_identifier_type pit WHERE uuid ='c09a1d24-7162-11eb-8aa6-0242ac110002';

DROP temporary TABLE IF EXISTS all_programs;
create temporary table all_programs(
patient_id int,
wellbody_emr_id varchar(50),
kgh_emr_id varchar(50),
program_name varchar(50),
date_enrolled date,
date_completed date,
final_program_status varchar(100),
created_by varchar(50)
);

insert into all_programs(patient_id,program_name,date_enrolled,date_completed,final_program_status,created_by)
select  pp.patient_id,
		p.name program_name,
		pp.date_enrolled,
		pp.date_completed,
		cn.name final_program_status,
		u.username created_by
from patient_program pp
left outer join program p on pp.program_id =p.program_id 
left outer join users u on pp.creator =u.user_id
left outer join concept_name cn on pp.outcome_concept_id = cn.concept_id and cn.voided=0 and cn.locale='en'
where pp.voided=0 ;

UPDATE all_programs ae
SET ae.wellbody_emr_id=patient_identifier(ae.patient_id,'1a2acce0-7426-11e5-a837-0800200c9a66');

UPDATE all_programs ae
SET ae.kgh_emr_id=patient_identifier(ae.patient_id,'c09a1d24-7162-11eb-8aa6-0242ac110002');

delete from all_programs 
where wellbody_emr_id is null and kgh_emr_id is null;

select 
concat(@partition,"-",patient_id) patient_id,
wellbody_emr_id,
kgh_emr_id ,
COALESCE(wellbody_emr_id, kgh_emr_id) emr_id,
program_name,
date_enrolled , 
date_completed ,
final_program_status,
created_by as user_entered
from all_programs;