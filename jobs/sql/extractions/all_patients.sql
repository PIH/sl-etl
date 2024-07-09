-- --------------- Variables ----------------------------
set @partition = '${partitionNum}';
SELECT patient_identifier_type_id INTO @identifier_type FROM patient_identifier_type pit WHERE uuid ='1a2acce0-7426-11e5-a837-0800200c9a66';
SELECT patient_identifier_type_id INTO @kgh_identifier_type 
FROM patient_identifier_type pit WHERE uuid ='c09a1d24-7162-11eb-8aa6-0242ac110002';
select encounter_type_id  into @reg_type_id 
from encounter_type et where uuid='873f968a-73a8-4f9c-ac78-9f4778b751b6';

-- ------------------------- Get Fresh Data ---------------------------------------

DROP TABLE IF EXISTS all_patients;
CREATE TEMPORARY TABLE  all_patients
(
wellbody_emr_id varchar(50),
kgh_emr_id varchar(50),
patient_id int, 
reg_location varchar(50),
reg_date date,
user_entered varchar(50),
fist_encounter_date date,
last_encounter_date date, 
name varchar(50),
family_name varchar(50),
dob date,
dob_estimated bit,
gender varchar(2),
dead bit,
death_date date,
cause_of_death varchar(100)
);

-- ---------- Temp tables ----------------
drop table if exists tbl_first_enc;
create temporary table tbl_first_enc
SELECT
    e.patient_id AS patient_id,
    min(e.encounter_datetime) AS encounter_datetime
FROM
    encounter e
GROUP BY
    e.patient_id;
 
drop table if exists tbl_first_enc_details;
create temporary table tbl_first_enc_details
SELECT
    DISTINCT e.patient_id AS patient_id,
    e.encounter_datetime AS encounter_datetime,
    e.encounter_id AS encounter_id,
    e.encounter_type AS encounter_type,
    u.username,
    l.name AS name
FROM
    ((encounter e
JOIN tbl_first_enc X ON
    (((X.patient_id = e.patient_id)
        AND (X.encounter_datetime = e.encounter_datetime))))
JOIN location l ON
    ((l.location_id = e.location_id)))
LEFT OUTER JOIN users u ON e.creator =u.user_id ;

   
-- --------- Identifications --------------------------------------------------------

INSERT INTO all_patients (patient_id) 
SELECT DISTINCT  p.patient_id
FROM patient p
where p.voided=0
GROUP BY p.patient_id ;

UPDATE all_patients dp 
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


UPDATE all_patients dp 
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


-- --------- Registeration --------------------------------------------------------

UPDATE all_patients dp
SET dp.reg_location=loc_registered(patient_id),
dp.reg_date=CAST(registration_date(patient_id) AS date);

drop table if exists tmp_first_enc_date;
create temporary table tmp_first_enc_date as
select min(cast(encounter_datetime as date)) as encounter_date, patient_id
from encounter e 
where encounter_type <>  @reg_type_id
group by patient_id;

drop table if exists tmp_last_enc_date;
create temporary table tmp_last_enc_date as
select max(cast(encounter_datetime as date)) as encounter_date, patient_id
from encounter e 
group by patient_id;

UPDATE all_patients dp
inner join
 (
	select patient_id,encounter_date
	from tmp_first_enc_date
) x
on dp.patient_id= x.patient_id
set fist_encounter_date =x.encounter_date;


UPDATE all_patients dp
inner join 
 (
	select patient_id,encounter_date
	from tmp_last_enc_date
) x 
on dp.patient_id= x.patient_id
set dp.last_encounter_date=x.encounter_date;

update all_patients dp 
inner join
(
	select patient_id, name 
	from tbl_first_enc_details 
) x 
on dp.patient_id= x.patient_id
set dp.reg_location = x.name
where dp.reg_location is null;

update all_patients dp 
inner join (
	select patient_id,cast(encounter_datetime as date) encdate
	from tbl_first_enc_details 
) x 
on dp.patient_id= x.patient_id
set dp.reg_date = x.encdate
where dp.reg_date is null;


update all_patients dp 
inner join (
	select patient_id,username
	from tbl_first_enc_details 
) x 
on dp.patient_id= x.patient_id
set dp.user_entered = x.username;

-- --------- Demographical ---------------------------------------------------------

UPDATE all_patients de 
INNER JOIN (
SELECT person_id,given_name,family_name FROM person_name 
WHERE voided=0 
) pn ON de.patient_id =pn.person_id 
SET de.name=pn.given_name, 
	de.family_name=pn.family_name;

-- -------------------- Bio Information -----------------------

UPDATE all_patients tt
SET tt.dob= birthdate(tt.patient_id),
tt.gender=gender(tt.patient_id);

UPDATE all_patients tt INNER JOIN (
SELECT person_id, dead , death_date, cause_of_death, birthdate_estimated 
FROM person p WHERE voided=0
) st 
on  st.person_id =tt.patient_id 
SET tt.dead = st.dead,
	tt.death_date = CAST(st.death_date AS date),
tt.cause_of_death=st.cause_of_death,
tt.dob_estimated=st.birthdate_estimated;


SELECT 
wellbody_emr_id,
kgh_emr_id,
COALESCE(wellbody_emr_id, kgh_emr_id)  emr_id,
concat(@partition,"-",patient_id)  patient_id,
reg_location,
reg_date as date_registration_entered,
user_entered,
fist_encounter_date,
last_encounter_date,
name,
family_name,
dob,
dob_estimated,
gender,
dead,
death_date,
cause_of_death
FROM all_patients dp;