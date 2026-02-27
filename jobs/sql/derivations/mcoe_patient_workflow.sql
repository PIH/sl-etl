drop table if exists mcoe_patient_workflow_staging 
create table mcoe_patient_workflow_staging
(visit_id                  varchar(50),  
patient_id                 varchar(50),  
age_at_admission           int,          
newborn                    bit,          
inborn                     bit,          
first_mcoe_datetime        datetime,     
first_mcoe_location        varchar(255), 
first_mcoe_encounter_type  varchar(255), 
location_before_mcoe       varchar(255), 
encounter_type_before_mcoe varchar(255)  
);

insert into mcoe_patient_workflow_staging(visit_id, patient_id, first_mcoe_datetime) 
select visit_id, patient_id, min(encounter_datetime)
from all_encounters 
where mcoe_location = 1
and inpatient_location = 1
group by visit_id, patient_id 
having min(encounter_datetime) >= '2026-02-14';

update m 
set m.age_at_admission = datediff(year, p.birthdate, first_mcoe_datetime)
from mcoe_patient_workflow_staging m
inner join all_patients p on p.patient_id = m.patient_id ;

update m 
set m.newborn = 
case age_at_admission 
	when 0 then 1 else 0 
end
from mcoe_patient_workflow_staging m;
 
update m 
set m.inborn = 1 
from mcoe_patient_workflow_staging m
inner join mch_delivery_summary_encounter d on d.patient_id = m.patient_id; 

update m set m.inborn = 0 from mcoe_patient_workflow_staging m where m.inborn is null;

update m
set m.first_mcoe_location = e.encounter_location,
	m.first_mcoe_encounter_type = e.encounter_type
from mcoe_patient_workflow_staging m
inner join all_encounters e on e.encounter_id = 
 	(select top 1 e2.encounter_id
 	from all_encounters e2
 	where  e2.encounter_datetime = m.first_mcoe_datetime
 	and e2.mcoe_location = 1
 	and e2.inpatient_location = 1
 	order by e2.encounter_datetime );

update m
set m.location_before_mcoe = e.encounter_location,
	m.encounter_type_before_mcoe = e.encounter_type
from mcoe_patient_workflow_staging m
inner join all_encounters e on e.encounter_id = 
 	(select top 1 e2.encounter_id
 	from all_encounters e2
 	where  e2.encounter_datetime < m.first_mcoe_datetime
 	and e2.visit_id = m.visit_id
 	order by e2.encounter_datetime desc);

DROP TABLE IF EXISTS mcoe_patient_workflow;
EXEC sp_rename 'mcoe_patient_workflow_staging', 'mcoe_patient_workflow';
