
-- --------- outpatient table 
SELECT patient_identifier_type_id INTO @identifier_type FROM patient_identifier_type pit WHERE uuid ='1a2acce0-7426-11e5-a837-0800200c9a66';
SELECT patient_identifier_type_id INTO @kgh_identifier_type FROM patient_identifier_type pit WHERE uuid ='c09a1d24-7162-11eb-8aa6-0242ac110002';
SELECT patient_identifier_type_id INTO @hiv_identifier_type FROM patient_identifier_type pit WHERE uuid ='139766e8-15f5-102d-96e4-000c29c2a5d7';

drop table if exists outpatient_patients;
create table outpatient_patients (
wellbody_emr_id varchar(50),
kgh_emr_id varchar(50),
patient_id int, 
encounter_id int,
visit_date date,
visit_type varchar(50),
weight_loss boolean,
obesity boolean,
jaundice boolean,
depression boolean,
rash boolean,
pallor boolean,
cardiac_murmur boolean,
tachycardia boolean,
splenomegaly boolean,
hepatomegaly boolean,
ascites boolean,
abdominal_mass boolean,
abdominal_pain boolean,
seizure boolean,
hemiplegia boolean,
effusion_of_joint boolean,
oedema boolean,
muscle_pain boolean,
hiv_testing boolean,
family_planning boolean,
disposition_comment text,
next_visit_date date
);

INSERT INTO outpatient_patients (patient_id,encounter_id,visit_type,visit_date ) 
select patient_id, encounter_id, 'Initial' as visit_type, cast(encounter_datetime as date) as visit_date
from encounter e where encounter_type = 39 and e.voided=0;

INSERT INTO outpatient_patients (patient_id,encounter_id,visit_type,visit_date ) 
select patient_id, encounter_id, 'Follow-Up' as visit_type, cast(encounter_datetime as date) as visit_date
from encounter e where encounter_type = 40 and e.voided=0;


UPDATE outpatient_patients dp 
SET dp.wellbody_emr_id= (
 SELECT identifier
 FROM patient_identifier 
 WHERE identifier_type =@identifier_type
 AND patient_id=dp.patient_id
 AND voided=0
 ORDER BY preferred desc, date_created desc limit 1
);

UPDATE outpatient_patients dp 
SET dp.kgh_emr_id= (
 SELECT identifier
 FROM patient_identifier 
 WHERE identifier_type =@kgh_identifier_type
 AND patient_id=dp.patient_id
 AND voided=0
 ORDER BY preferred desc, date_created desc limit 1
);

Update outpatient_patients dp 
set dp.weight_loss = (
	select max(case when o.value_coded=1407 then true else false end) as weight_loss
	from obs o
	where o.encounter_id = dp.encounter_id  
	and o.person_id = dp.patient_id 
);

Update outpatient_patients dp 
set dp.obesity = (
	select max(case when o.value_coded=753 then true else false end) as weight_loss
	from obs o
	where o.encounter_id = dp.encounter_id  
	and o.person_id = dp.patient_id 
);

Update outpatient_patients dp 
set dp.jaundice  = (
	select max(case when o.value_coded=759 then true else false end) as weight_loss
	from obs o
	where o.encounter_id = dp.encounter_id  
	and o.person_id = dp.patient_id 
);

Update outpatient_patients dp 
set dp.depression  = (
	select max(case when o.value_coded=717 then true else false end) as weight_loss
	from obs o
	where o.encounter_id = dp.encounter_id  
	and o.person_id = dp.patient_id 
);

Update outpatient_patients dp 
set dp.rash = (
	select max(case when o.value_coded=260 then true else false end) as weight_loss
	from obs o
	where o.encounter_id = dp.encounter_id  
	and o.person_id = dp.patient_id 
);

Update outpatient_patients dp 
set dp.pallor  = (
	select max(case when o.value_coded=726 then true else false end) as weight_loss
	from obs o
	where o.encounter_id = dp.encounter_id  
	and o.person_id = dp.patient_id 
);

Update outpatient_patients dp 
set dp.cardiac_murmur = (
	select max(case when o.value_coded=750 then true else false end) as weight_loss
	from obs o
	where o.encounter_id = dp.encounter_id  
	and o.person_id = dp.patient_id 
);


Update outpatient_patients dp 
set dp.tachycardia  = (
	select max(case when o.value_coded=740 then true else false end) as weight_loss
	from obs o
	where o.encounter_id = dp.encounter_id  
	and o.person_id = dp.patient_id 
);

Update outpatient_patients dp 
set dp.splenomegaly  = (
	select max(case when o.value_coded=651 then true else false end) as weight_loss
	from obs o
	where o.encounter_id = dp.encounter_id  
	and o.person_id = dp.patient_id 
);

Update outpatient_patients dp 
set dp.hepatomegaly  = (
	select max(case when o.value_coded=650 then true else false end) as weight_loss
	from obs o
	where o.encounter_id = dp.encounter_id  
	and o.person_id = dp.patient_id 
);

Update outpatient_patients dp 
set dp.ascites  = (
	select max(case when o.value_coded=658 then true else false end) as weight_loss
	from obs o
	where o.encounter_id = dp.encounter_id  
	and o.person_id = dp.patient_id 
);

Update outpatient_patients dp 
set dp.abdominal_mass  = (
	select max(case when o.value_coded=664 then true else false end) as weight_loss
	from obs o
	where o.encounter_id = dp.encounter_id  
	and o.person_id = dp.patient_id 
);

Update outpatient_patients dp 
set dp.abdominal_pain  = (
	select max(case when o.value_coded=374 then true else false end) as weight_loss
	from obs o
	where o.encounter_id = dp.encounter_id  
	and o.person_id = dp.patient_id 
);

Update outpatient_patients dp 
set dp.seizure  = (
	select max(case when o.value_coded=335 then true else false end) as weight_loss
	from obs o
	where o.encounter_id = dp.encounter_id  
	and o.person_id = dp.patient_id 
);

Update outpatient_patients dp 
set dp.hemiplegia  = (
	select max(case when o.value_coded=711 then true else false end) as weight_loss
	from obs o
	where o.encounter_id = dp.encounter_id  
	and o.person_id = dp.patient_id 
);

Update outpatient_patients dp 
set dp.effusion_of_joint  = (
	select max(case when o.value_coded=683 then true else false end) as weight_loss
	from obs o
	where o.encounter_id = dp.encounter_id  
	and o.person_id = dp.patient_id 
);

Update outpatient_patients dp 
set dp.oedema  = (
	select max(case when o.value_coded=684 then true else false end) as weight_loss
	from obs o
	where o.encounter_id = dp.encounter_id  
	and o.person_id = dp.patient_id 
);

Update outpatient_patients dp 
set dp.muscle_pain  = (
	select max(case when o.value_coded=2292 then true else false end) as weight_loss
	from obs o
	where o.encounter_id = dp.encounter_id  
	and o.person_id = dp.patient_id 
);

Update outpatient_patients dp 
set dp.hiv_testing  = (
	select max(case when o.value_coded=1 then true 
					when o.value_coded=2 then false 
					else false end) as hiv_testing
	from obs o
	where o.encounter_id = dp.encounter_id  
	and o.person_id = dp.patient_id 
	and o.concept_id= 1382
);

Update outpatient_patients dp 
set dp.family_planning  = (
	select max(case when o.value_coded=1 then true 
					when o.value_coded=2 then false 
					else false end) as hiv_testing
	from obs o
	where o.encounter_id = dp.encounter_id  
	and o.person_id = dp.patient_id 
	and o.concept_id= 3781
);


Update outpatient_patients dp 
set dp.disposition_comment = (
	select value_text
	from obs o
	where o.encounter_id = dp.encounter_id  
	and o.person_id = dp.patient_id 
	and o.concept_id= 1400
	order by o.obs_datetime desc 
	limit 1
);
	
Update outpatient_patients dp 
set dp.next_visit_date  = (
	select distinct cast(value_datetime as date)
	from obs o
	where o.encounter_id = dp.encounter_id  
	and o.person_id = dp.patient_id 
	and o.concept_id= 2924
	order by o.obs_datetime desc 
	limit 1);


select 
wellbody_emr_id,
kgh_emr_id,
patient_id, 
encounter_id,
visit_date,
visit_type,
weight_loss ,
obesity ,
jaundice ,
depression ,
rash ,
pallor ,
cardiac_murmur ,
tachycardia ,
splenomegaly ,
hepatomegaly ,
ascites ,
abdominal_mass,
abdominal_pain ,
seizure ,
hemiplegia ,
effusion_of_joint ,
oedema ,
muscle_pain ,
hiv_testing ,
family_planning ,
disposition_comment ,
next_visit_date 
from outpatient_patients;