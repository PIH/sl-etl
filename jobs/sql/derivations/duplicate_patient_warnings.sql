drop table if exists duplicate_patient_staging;
create table duplicate_patient_staging
(warning_type                       text,         
siblings                            bit,          
patient_1_patient_id                varchar(30),  
patient_2_patient_id                varchar(30),  
patient_1_telephone_number          text,         
patient_2_telephone_number          text,         
patient_1_name                      text,         
patient_2_name                      text,         
patient_1_mothers_first_name        text,         
patient_2_mothers_first_name        text,         
patient_1_date_registration_entered datetime,     
patient_2_date_registration_entered datetime,     
patient_1_user_entered              text,         
patient_2_user_entered              text,         
patient_1_site                      varchar(100), 
patient_2_site                      varchar(100)
);

-- populate table with all pairs of candidates based on same telephone number
insert into duplicate_patient_staging(patient_1_patient_id, patient_2_patient_id)
select 
p1.patient_id,
p2.patient_id
from 
all_patients p1
inner join all_patients p2
on p1.patient_id < p2.patient_id
and replace(replace(p1.telephone_number,' ',''),'-','') = replace(replace(p2.telephone_number,' ',''),'-','')
where p1.telephone_number > '0';

-- remove candidates where name doesn't match
delete t 
from duplicate_patient_staging t
inner join all_patients p1 on p1.patient_id = t.patient_1_patient_id
inner join all_patients p2 on p2.patient_id = t.patient_2_patient_id
where lower(replace(p1.name,' ','')) <> lower(replace(p2.name,' ',''));

-- remove candidates where family_name doesn't match
delete t 
from duplicate_patient_staging t
inner join all_patients p1 on p1.patient_id = t.patient_1_patient_id
inner join all_patients p2 on p2.patient_id = t.patient_2_patient_id
where lower(replace(p1.family_name,' ','')) <> lower(replace(p2.family_name,' ',''));

-- remove candidates where mothers_first_name doesn't match
delete t 
from duplicate_patient_staging t
inner join all_patients p1 on p1.patient_id = t.patient_1_patient_id
inner join all_patients p2 on p2.patient_id = t.patient_2_patient_id
where lower(replace(p1.mothers_first_name,' ','')) <> lower(replace(p2.mothers_first_name,' ',''));

-- populate all remaining fields
update t
set patient_1_telephone_number = p1.telephone_number,
	patient_1_name = concat(p1.name,' ',p1.family_name),
	patient_1_mothers_first_name = p1.mothers_first_name,
	patient_1_date_registration_entered = p1.date_registration_entered,
	patient_1_user_entered = p1.user_entered, 
	patient_1_site = p1.site
from duplicate_patient_staging t
inner join all_patients p1 on p1.patient_id = t.patient_1_patient_id;
	
update t
set patient_2_telephone_number = p2.telephone_number,
	patient_2_name = concat(p2.name,' ',p2.family_name),
	patient_2_mothers_first_name = p2.mothers_first_name,
	patient_2_date_registration_entered = p2.date_registration_entered,
	patient_2_user_entered = p2.user_entered ,	
	patient_2_site = p2.site
from duplicate_patient_staging t
inner join all_patients p2 on p2.patient_id = t.patient_2_patient_id;

update t
set t.warning_type = 
case
	when patient_1_site = patient_2_site then 'duplicate patients on same EMR'
	else 'duplicate patients on different EMRs'
end
from duplicate_patient_staging t;

update t
set t.siblings = 1
from duplicate_patient_staging t
inner join mother_child_relationship r1 on r1.patient_id = t.patient_1_patient_id 
inner join mother_child_relationship r2 on r2.patient_id = t.patient_2_patient_id 
	and r1.emr_id_mother = r2.emr_id_mother; 

DROP TABLE IF EXISTS duplicate_patient_warnings;
EXEC sp_rename 'duplicate_patient_staging', 'duplicate_patient_warnings';
