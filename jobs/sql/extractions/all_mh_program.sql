SET sql_safe_updates = 0;

DROP TEMPORARY TABLE IF EXISTS temp_mentalhealth_program;

SET SESSION group_concat_max_len = 100000;

set @program_id = program('Mental Health');
set @latest_diagnosis = concept_from_mapping('PIH', 'Mental health diagnosis');
set @encounter_type = encounter_type('Mental Health Consult');
set @zlds_score = concept_from_mapping('CIEL', '163225');
set @whodas_score = concept_from_mapping('CIEL', '163226');
set @seizures = concept_from_mapping('PIH', 'Number of seizures in the past month');
set @medication = concept_from_mapping('PIH', 'Mental health medication');
set @return_visit_date = concept_from_mapping('PIH', 'RETURN VISIT DATE');


create temporary table temp_mentalhealth_program
(
patient_id int,
patient_program_id int,
prog_location_id int,
emr_id varchar(255),
gender varchar(50),
age double,
assigned_chw text,
location_when_registered_in_program varchar(255),
date_enrolled date,
date_completed date,
number_of_days_in_care double,
program_status_outcome varchar(255),
encounter_id int,
encounter_datetime datetime,
latest_diagnosis_encounter_id int,
latest_diagnosis text,
latest_seizure_number double,
latest_seizure_date date,
previous_seizure_number double,
previous_seizure_date date,
baseline_seizure_number double,
baseline_seizure_date date,
latest_medication_given text,
latest_medication_date date,
last_visit_date date,
next_scheduled_visit_date date,
patient_came_within_14_days_appt varchar(50),
three_months_since_latest_return_date varchar(50),
six_months_since_latest_return_date varchar(50)
);

insert into temp_mentalhealth_program (patient_id, patient_program_id, prog_location_id, emr_id, gender, date_enrolled, date_completed, number_of_days_in_care, program_status_outcome)
select patient_id,
	   patient_program_id,
       location_id,
	   patient_identifier(patient_id, metadata_uuid('org.openmrs.module.emrapi', 'emr.primaryIdentifierType')),
       gender(patient_id),
	   date(date_enrolled),
       date(date_completed),
       If(date_completed is null, datediff(now(), date_enrolled), datediff(date_completed, date_enrolled)),
       concept_name(outcome_concept_id, 'fr')
       from patient_program where program_id = @program_id and voided = 0
     ;

-- exclude test patients
delete from temp_mentalhealth_program where
patient_id IN (SELECT person_id FROM person_attribute WHERE value = 'true' AND person_attribute_type_id = (select
person_attribute_type_id from person_attribute_type where name = "Test Patient")
                         AND voided = 0)
;

-- age
update temp_mentalhealth_program tmhp
left join person p on person_id = patient_id and p.voided = 0
set tmhp.age = CAST(CONCAT(timestampdiff(YEAR, p.birthdate, NOW()), '.', MOD(timestampdiff(MONTH, p.birthdate, NOW()), 12) ) as CHAR);

-- relationship
update temp_mentalhealth_program tmhp
inner join (select patient_program_id, patient_id, person_a, GROUP_CONCAT(' ',CONCAT(pn.given_name,' ',pn.family_name)) chw  from patient_program join relationship r on person_b = patient_id and program_id = @program_id
and r.voided = 0 and relationship = relation_type('Community Health Worker') join person_name pn on person_a = pn.person_id and pn.voided = 0 group by patient_program_id) relationship
on relationship.patient_id = tmhp.patient_id and tmhp.patient_program_id = relationship.patient_program_id
set tmhp.assigned_chw = relationship.chw;

-- location registered in Program
update temp_mentalhealth_program tmhp
left join location l on location_id = tmhp.prog_location_id and l.retired = 0
set tmhp.location_when_registered_in_program = l.name;

-- latest diagnosis
-- The approach below in finding the latest diagnosis is to:
-- create a temp table with all of the encounters in the correct date range for each patient-program 
-- duplicate that table (because MYSQL doesn't allow for a temp table to be opened twice in a query)
-- index that table and use that to join back into the main temp table in this query

drop temporary table if exists temp_obs;
CREATE TEMPORARY TABLE temp_obs
(	temp_id int(11) AUTO_INCREMENT,
	patient_program_id int(11),
	patient_id int(11),
	encounter_id int(11),
	encounter_datetime datetime,
	value_coded int(11),
	PRIMARY KEY (temp_id) );

insert into  temp_obs (patient_program_id, patient_id,encounter_id,encounter_datetime,value_coded)
SELECT 	t.patient_program_id,
		t.patient_id,
		e.encounter_id,
		e.encounter_datetime,
		o.value_coded 
from temp_mentalhealth_program t
inner join encounter e on e.patient_id = t.patient_id and e.encounter_type = @encounter_type and e.voided = 0
	and date(e.encounter_datetime) >= date(t.date_enrolled) and (date(e.encounter_datetime) <= date(t.date_completed) or t.date_completed is null)
inner join obs o on o.encounter_id  = e.encounter_id and o.voided = 0 
	and o.concept_id in (@latest_diagnosis) -- , @zlds_score,@whodas_score,@seizures,@medication)
;

drop temporary table if exists temp_obs_dup;
CREATE TEMPORARY TABLE temp_obs_dup
select * from temp_obs;

create index t_encounter_datetime_index on temp_obs_dup (encounter_datetime);
create index t_obs_id_temp_id on temp_obs_dup (temp_id);

update temp_mentalhealth_program tmh
inner join temp_obs t on t.temp_id =
	(select temp_id from temp_obs_dup t2 
	where t2.patient_program_id = tmh.patient_program_id
  	order by t2.encounter_datetime desc limit 1)
set tmh.latest_diagnosis = concept_name(t.value_coded,@locale);

-- latest number of seizures (uses the same approach as latest diagnosis above)
drop temporary table if exists temp_obs;
CREATE TEMPORARY TABLE temp_obs
(	temp_id int(11) AUTO_INCREMENT,
	patient_program_id int(11),
	patient_id int(11),
	encounter_id int(11),
	encounter_datetime datetime,
	value_numeric double,
	PRIMARY KEY (temp_id) );

insert into  temp_obs (patient_program_id, patient_id,encounter_id,encounter_datetime,value_numeric)
SELECT 	t.patient_program_id,
		t.patient_id,
		e.encounter_id,
		e.encounter_datetime,
		o.value_numeric
from temp_mentalhealth_program t
inner join encounter e on e.patient_id = t.patient_id and e.encounter_type = @encounter_type and e.voided = 0
	and date(e.encounter_datetime) >= date(t.date_enrolled) and (date(e.encounter_datetime) <= date(t.date_completed) or t.date_completed is null)
inner join obs o on o.encounter_id  = e.encounter_id and o.voided = 0 
	and o.concept_id in (@seizures) 
;

drop temporary table if exists temp_obs_dup;
CREATE TEMPORARY TABLE temp_obs_dup
select * from temp_obs;

create index t_encounter_datetime_index on temp_obs_dup (encounter_datetime);
create index t_obs_id_temp_id on temp_obs_dup (temp_id);

update temp_mentalhealth_program tmh
inner join temp_obs t on t.temp_id =
	(select temp_id from temp_obs_dup t2 
	where t2.patient_program_id = tmh.patient_program_id
  	order by t2.encounter_datetime desc limit 1)
set tmh.latest_seizure_number = t.value_numeric,
	tmh.latest_seizure_date = date(t.encounter_datetime);

-- previous number of seizures and date (uses the same temp table as the latest score)

update temp_mentalhealth_program tmh
inner join temp_obs t on t.temp_id =
	(select temp_id from temp_obs_dup t2 
	where t2.patient_program_id = tmh.patient_program_id
  	order by t2.encounter_datetime desc limit 1,1)
set tmh.previous_seizure_number = t.value_numeric,
	tmh.previous_seizure_date =date(t.encounter_datetime);

-- baseline number of seizures and date (uses the same temp table as the latest score)

update temp_mentalhealth_program tmh
inner join temp_obs t on t.temp_id =
	(select temp_id from temp_obs_dup t2 
	where t2.patient_program_id = tmh.patient_program_id
  	order by t2.encounter_datetime asc limit 1)
set tmh.baseline_seizure_number = t.value_numeric,
	tmh.baseline_seizure_date = date(t.encounter_datetime);

-- last Medication recorded (uses the same approach as latest diagnosis above)

drop temporary table if exists temp_obs;
CREATE TEMPORARY TABLE temp_obs
(	temp_id int(11) AUTO_INCREMENT,
	patient_program_id int(11),
	encounter_id int(11),
	encounter_datetime datetime,
	medications varchar(500),
	PRIMARY KEY (temp_id) );

insert into temp_obs (patient_program_id, encounter_id,encounter_datetime,medications)
SELECT 	t.patient_program_id,
		e.encounter_id,
		e.encounter_datetime,
		group_concat(concept_name(o.value_coded,@locale))
from temp_mentalhealth_program t
inner join encounter e on e.patient_id = t.patient_id and e.encounter_type = @encounter_type and e.voided = 0
	and date(e.encounter_datetime) >= date(t.date_enrolled) and (date(e.encounter_datetime) <= date(t.date_completed) or t.date_completed is null)
inner join obs o on o.encounter_id  = e.encounter_id and o.voided = 0 
	and o.concept_id in (@medication) 
group by patient_program_id, encounter_id ,encounter_datetime 	
;

drop temporary table if exists temp_obs_dup;
CREATE TEMPORARY TABLE temp_obs_dup
select * from temp_obs;

create index t_encounter_datetime_index on temp_obs_dup (encounter_datetime);
create index t_encounter_id_temp_id on temp_obs_dup (temp_id);

update temp_mentalhealth_program tmh
inner join temp_obs t on t.temp_id =
	(select temp_id from temp_obs_dup t2 
	where t2.patient_program_id = tmh.patient_program_id
  	order by t2.encounter_datetime desc limit 1)
set tmh.latest_medication_given = t.medications,
	tmh.latest_medication_date = date(t.encounter_datetime);

-- Last Visit Date  (uses the same temp table as the latest score)
drop temporary table if exists temp_obs;
CREATE TEMPORARY TABLE temp_obs
(	temp_id int(11) AUTO_INCREMENT,
	patient_program_id int(11),
	encounter_id int(11),
	encounter_datetime datetime,
	PRIMARY KEY (temp_id) );

insert into  temp_obs (patient_program_id, encounter_id,encounter_datetime)
SELECT 	t.patient_program_id,
		e.encounter_id,
		e.encounter_datetime
from temp_mentalhealth_program t
inner join encounter e on e.patient_id = t.patient_id and e.encounter_type = @encounter_type and e.voided = 0
	and date(e.encounter_datetime) >= date(t.date_enrolled) and (date(e.encounter_datetime) <= date(t.date_completed) or t.date_completed is null)
group by patient_program_id, encounter_id, encounter_datetime
;

drop temporary table if exists temp_obs_dup;
CREATE TEMPORARY TABLE temp_obs_dup
select * from temp_obs;

create index t_encounter_datetime_index on temp_obs_dup (encounter_datetime);
create index t_obs_id_temp_id on temp_obs_dup (temp_id);

update temp_mentalhealth_program tmh
inner join temp_obs t on t.temp_id =
	(select temp_id from temp_obs_dup t2 
	where t2.patient_program_id = tmh.patient_program_id
  	order by t2.encounter_datetime desc limit 1)
set tmh.last_visit_date = date(t.encounter_datetime);

-- Next Scheduled Visit Date  (uses the same temp table as the latest score)
drop temporary table if exists temp_obs;
CREATE TEMPORARY TABLE temp_obs
(	temp_id int(11) AUTO_INCREMENT,
	patient_program_id int(11),
	patient_id int(11),
	encounter_id int(11),
	encounter_datetime datetime,
	value_datetime double,
	PRIMARY KEY (temp_id) );

insert into  temp_obs (patient_program_id, patient_id,encounter_id,encounter_datetime,value_datetime)
SELECT 	t.patient_program_id,
		t.patient_id,
		e.encounter_id,
		e.encounter_datetime,
		o.value_datetime
from temp_mentalhealth_program t
inner join encounter e on e.patient_id = t.patient_id and e.encounter_type = @encounter_type and e.voided = 0
	and date(e.encounter_datetime) >= date(t.date_enrolled) and (date(e.encounter_datetime) <= date(t.date_completed) or t.date_completed is null)
inner join obs o on o.encounter_id  = e.encounter_id and o.voided = 0 
	and o.concept_id in (@return_visit_date) 
;

drop temporary table if exists temp_obs_dup;
CREATE TEMPORARY TABLE temp_obs_dup
select * from temp_obs;

create index t_encounter_datetime_index on temp_obs_dup (encounter_datetime);
create index t_obs_id_temp_id on temp_obs_dup (temp_id);

update temp_mentalhealth_program tmh
inner join temp_obs t on t.temp_id =
	(select temp_id from temp_obs_dup t2 
	where t2.patient_program_id = tmh.patient_program_id
  	order by t2.encounter_datetime desc limit 1)
set tmh.next_scheduled_visit_date = date(t.value_datetime),
    tmh.patient_came_within_14_days_appt = IF(datediff(now(), tmh.last_visit_date) <= 14, 'Oui', 'No'),
    tmh.three_months_since_latest_return_date = IF(datediff(now(), tmh.last_visit_date) <= 91.2501, 'No', 'Oui'),
	tmh.six_months_since_latest_return_date = IF(datediff(now(), tmh.last_visit_date) <= 182.5, 'No', 'Oui');
        
select
emr_id,
gender,
age,
assigned_chw,
person_address_state_province(patient_id) 'province',
person_address_city_village(patient_id) 'city_village',
person_address_three(patient_id) 'address3',
person_address_one(patient_id) 'address1',
person_address_two(patient_id) 'address2',
location_when_registered_in_program,
date_enrolled,
date_completed,
number_of_days_in_care,
program_status_outcome,
latest_diagnosis,
latest_seizure_number,
latest_seizure_date,
previous_seizure_number,
previous_seizure_date,
baseline_seizure_number,
baseline_seizure_date,
latest_medication_given,
latest_medication_date,
last_visit_date,
next_scheduled_visit_date,
three_months_since_latest_return_date,
six_months_since_latest_return_date
from temp_mentalhealth_program;