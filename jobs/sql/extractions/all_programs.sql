
-- All Programs 
SELECT patient_identifier_type_id INTO @identifier_type FROM patient_identifier_type pit WHERE uuid ='1a2acce0-7426-11e5-a837-0800200c9a66';
SELECT patient_identifier_type_id INTO @kgh_identifier_type FROM patient_identifier_type pit WHERE uuid ='c09a1d24-7162-11eb-8aa6-0242ac110002';

drop table if exists all_programs;
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
inner join  (
	 SELECT patient_id, identifier
	 FROM patient_identifier 
	 WHERE identifier_type =@identifier_type 
	 AND voided=0
	 group by patient_id 
) x on x.patient_id=ae.patient_id
SET ae.wellbody_emr_id=x.identifier;

UPDATE all_programs ae
inner join  (
	 SELECT patient_id, identifier
	 FROM patient_identifier 
	 WHERE identifier_type =@kgh_identifier_type 
	 AND voided=0
	 group by patient_id 
) x on x.patient_id=ae.patient_id
SET ae.kgh_emr_id=x.identifier;

delete from all_programs 
where wellbody_emr_id is null and kgh_emr_id is null;

select 
wellbody_emr_id,
kgh_emr_id ,
program_name,
date_enrolled , 
date_completed ,
final_program_status,
created_by
from all_programs;