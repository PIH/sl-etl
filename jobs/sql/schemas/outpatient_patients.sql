create table outpatient_patients (
wellbody_emr_id varchar(50),
kgh_emr_id varchar(50),
patient_id int,
encounter_id int,
visit_date date,
visit_type varchar(50),
weight_loss bit,
obesity bit,
jaundice bit,
depression bit,
rash bit,
pallor bit,
cardiac_murmur bit,
tachycardia bit,
splenomegaly bit,
hepatomegaly bit,
ascites bit,
abdominal_mass bit,
abdominal_pain bit,
seizure bit,
hemiplegia bit,
effusion_of_joint bit,
oedema bit,
muscle_pain bit,
hiv_testing bit,
family_planning bit,
disposition_comment text,
next_visit_date date
);