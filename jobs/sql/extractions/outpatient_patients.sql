
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
inner join 
 (
 SELECT identifier,patient_id
 FROM patient_identifier 
 WHERE identifier_type =@identifier_type
 AND voided=0
 group by patient_id
) x 
on  x.patient_id=dp.patient_id
SET dp.wellbody_emr_id= x.identifier;


UPDATE outpatient_patients dp 
inner join 
 (
 SELECT identifier,patient_id
 FROM patient_identifier 
 WHERE identifier_type =@kgh_identifier_type
 AND voided=0
 group by patient_id
) x 
on  x.patient_id=dp.patient_id
SET dp.kgh_emr_id= x.identifier;


Update outpatient_patients dp 
inner join (
	select true as weight_loss, -- max(case when o.value_coded=1407 then true else false end) as weight_loss, 
	encounter_id, person_id
	from obs o
	where value_coded=1407
	group by encounter_id, person_id 
) x 
on  x.encounter_id = dp.encounter_id  
and x.person_id = dp.patient_id 
set dp.weight_loss = x.weight_loss;


Update outpatient_patients dp 
inner join (
	select true as obesity, 
	encounter_id, person_id
	from obs o
	where value_coded=753
	group by encounter_id, person_id 
) x 
on  x.encounter_id = dp.encounter_id  
and x.person_id = dp.patient_id 
set dp.obesity = x.obesity;


Update outpatient_patients dp 
inner join (
	select true as jaundice, 
	encounter_id, person_id
	from obs o
	where value_coded=759
	group by encounter_id, person_id 
) x 
on  x.encounter_id = dp.encounter_id  
and x.person_id = dp.patient_id 
set dp.jaundice = x.jaundice;


Update outpatient_patients dp 
inner join (
	select true as depression, 
	encounter_id, person_id
	from obs o
	where value_coded=717
	group by encounter_id, person_id 
) x 
on  x.encounter_id = dp.encounter_id  
and x.person_id = dp.patient_id 
set dp.depression = x.depression;

Update outpatient_patients dp 
inner join (
	select true as rash, 
	encounter_id, person_id
	from obs o
	where value_coded=260
	group by encounter_id, person_id 
) x 
on  x.encounter_id = dp.encounter_id  
and x.person_id = dp.patient_id 
set dp.rash = x.rash;

Update outpatient_patients dp 
inner join (
	select true as pallor, 
	encounter_id, person_id
	from obs o
	where value_coded=726
	group by encounter_id, person_id 
) x 
on  x.encounter_id = dp.encounter_id  
and x.person_id = dp.patient_id 
set dp.pallor = x.pallor;

Update outpatient_patients dp 
inner join (
	select true as cardiac_murmur, 
	encounter_id, person_id
	from obs o
	where value_coded=750
	group by encounter_id, person_id 
) x 
on  x.encounter_id = dp.encounter_id  
and x.person_id = dp.patient_id 
set dp.cardiac_murmur = x.cardiac_murmur;


Update outpatient_patients dp 
inner join (
	select true as tachycardia, 
	encounter_id, person_id
	from obs o
	where value_coded=740
	group by encounter_id, person_id 
) x 
on  x.encounter_id = dp.encounter_id  
and x.person_id = dp.patient_id 
set dp.tachycardia = x.tachycardia;


Update outpatient_patients dp 
inner join (
	select true as splenomegaly, 
	encounter_id, person_id
	from obs o
	where value_coded=651
	group by encounter_id, person_id 
) x 
on  x.encounter_id = dp.encounter_id  
and x.person_id = dp.patient_id 
set dp.splenomegaly = x.splenomegaly;


Update outpatient_patients dp 
inner join (
	select true as hepatomegaly, 
	encounter_id, person_id
	from obs o
	where value_coded=650
	group by encounter_id, person_id 
) x 
on  x.encounter_id = dp.encounter_id  
and x.person_id = dp.patient_id 
set dp.hepatomegaly = x.hepatomegaly;


Update outpatient_patients dp 
inner join (
	select true as ascites, 
	encounter_id, person_id
	from obs o
	where value_coded=658
	group by encounter_id, person_id 
) x 
on  x.encounter_id = dp.encounter_id  
and x.person_id = dp.patient_id 
set dp.ascites = x.ascites;

Update outpatient_patients dp 
inner join (
	select true as abdominal_mass, 
	encounter_id, person_id
	from obs o
	where value_coded=664
	group by encounter_id, person_id 
) x 
on  x.encounter_id = dp.encounter_id  
and x.person_id = dp.patient_id 
set dp.abdominal_mass = x.abdominal_mass;



Update outpatient_patients dp 
inner join (
	select true as abdominal_pain, 
	encounter_id, person_id
	from obs o
	where value_coded=374
	group by encounter_id, person_id 
) x 
on  x.encounter_id = dp.encounter_id  
and x.person_id = dp.patient_id 
set dp.abdominal_pain = x.abdominal_pain;


Update outpatient_patients dp 
inner join (
	select true as seizure, 
	encounter_id, person_id
	from obs o
	where value_coded=335
	group by encounter_id, person_id 
) x 
on  x.encounter_id = dp.encounter_id  
and x.person_id = dp.patient_id 
set dp.seizure = x.seizure;


Update outpatient_patients dp 
inner join (
	select true as hemiplegia, 
	encounter_id, person_id
	from obs o
	where value_coded=711
	group by encounter_id, person_id 
) x 
on  x.encounter_id = dp.encounter_id  
and x.person_id = dp.patient_id 
set dp.hemiplegia = x.hemiplegia;


Update outpatient_patients dp 
inner join (
	select true as effusion_of_joint, 
	encounter_id, person_id
	from obs o
	where value_coded=683
	group by encounter_id, person_id 
) x 
on  x.encounter_id = dp.encounter_id  
and x.person_id = dp.patient_id 
set dp.effusion_of_joint = x.effusion_of_joint;


Update outpatient_patients dp 
inner join (
	select true as oedema, 
	encounter_id, person_id
	from obs o
	where value_coded=684
	group by encounter_id, person_id 
) x 
on  x.encounter_id = dp.encounter_id  
and x.person_id = dp.patient_id 
set dp.oedema = x.oedema;


Update outpatient_patients dp 
inner join (
	select true as muscle_pain, 
	encounter_id, person_id
	from obs o
	where value_coded=2292
	group by encounter_id, person_id 
) x 
on  x.encounter_id = dp.encounter_id  
and x.person_id = dp.patient_id 
set dp.muscle_pain = x.muscle_pain;

Update outpatient_patients dp 
inner join 
(
	select max(case when o.value_coded=1 then true 
					when o.value_coded=2 then false 
					else false end) as hiv_testing,encounter_id, person_id
	from obs o
	where o.concept_id= 1382
	group by encounter_id, person_id 
) x  
on  x.encounter_id = dp.encounter_id  
and x.person_id = dp.patient_id 
set dp.hiv_testing=x.hiv_testing;

Update outpatient_patients dp 
inner join 
(
	select max(case when o.value_coded=1 then true 
					when o.value_coded=2 then false 
					else false end) as family_planning,encounter_id, person_id
	from obs o
	where o.concept_id= 3781
	group by encounter_id, person_id 
) x  
on  x.encounter_id = dp.encounter_id  
and x.person_id = dp.patient_id 
set dp.family_planning=x.family_planning;


Update outpatient_patients dp 
inner join (
	select value_text as disposition_comment, 
	encounter_id, person_id
	from obs o
	where o.concept_id= 1400
	group by encounter_id, person_id 
) x 
on  x.encounter_id = dp.encounter_id  
and x.person_id = dp.patient_id 
set dp.disposition_comment = x.disposition_comment;

Update outpatient_patients dp 
inner join (
	select distinct cast(value_datetime as date) as next_visit_date, 
	encounter_id, person_id
	from obs o
	where o.concept_id= 2924
	group by encounter_id, person_id 
) x 
on  x.encounter_id = dp.encounter_id  
and x.person_id = dp.patient_id 
set dp.next_visit_date = x.next_visit_date;


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