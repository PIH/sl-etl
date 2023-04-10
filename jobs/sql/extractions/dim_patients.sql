-- --------------- Variables ----------------------------
set @partition = '${partitionNum}';

SELECT patient_identifier_type_id INTO @identifier_type FROM patient_identifier_type pit WHERE uuid ='1a2acce0-7426-11e5-a837-0800200c9a66';
SELECT patient_identifier_type_id INTO @kgh_identifier_type FROM patient_identifier_type pit WHERE uuid ='c09a1d24-7162-11eb-8aa6-0242ac110002';

SELECT name  INTO @etype_echo_name FROM encounter_type et WHERE et.uuid ='fdee591e-78ba-11e9-8f9e-2a86e4085a59';
SELECT encounter_type_id  INTO @etype_echo_id FROM encounter_type et WHERE et.uuid ='fdee591e-78ba-11e9-8f9e-2a86e4085a59';

SELECT name  INTO @etype_ncdinit_name FROM encounter_type et WHERE et.uuid ='ae06d311-1866-455b-8a64-126a9bd74171';
SELECT encounter_type_id  INTO @etype_ncdinit_id FROM encounter_type et WHERE et.uuid ='ae06d311-1866-455b-8a64-126a9bd74171';
SELECT name  INTO @etype_ncdf_name FROM encounter_type et WHERE et.uuid ='5cbfd6a2-92d9-4ad0-b526-9d29bfe1d10c';
SELECT encounter_type_id  INTO @etype_ncdf_id FROM encounter_type et WHERE et.uuid ='5cbfd6a2-92d9-4ad0-b526-9d29bfe1d10c';

SELECT name  INTO @etype_hivinit_name FROM encounter_type et WHERE et.uuid ='c31d306a-40c4-11e7-a919-92ebcb67fe33';
SELECT encounter_type_id  INTO @etype_hivinit_id FROM encounter_type et WHERE et.uuid ='c31d306a-40c4-11e7-a919-92ebcb67fe33';
SELECT name  INTO @etype_hivf_name FROM encounter_type et WHERE et.uuid ='c31d3312-40c4-11e7-a919-92ebcb67fe33';
SELECT encounter_type_id  INTO @etype_hivf_id FROM encounter_type et WHERE et.uuid ='c31d3312-40c4-11e7-a919-92ebcb67fe33';


-- ------------------------- Get Fresh Data ---------------------------------------

DROP TABLE IF EXISTS dim_patients;
CREATE TEMPORARY TABLE  dim_patients (
wellbody_emr_id varchar(50),
kgh_emr_id varchar(50),
patient_id int, 

reg_location varchar(50),
reg_date date,

name varchar(50),
family_name varchar(50),
dob date,
dob_estimated bit,
gender varchar(2),
dead bit,
death_date date,
cause_of_death varchar(100),

ncd_enrolled bit,
ncd_last_encounter_date date,
echo_enrolled bit,
echo_last_encounter_date date,
hiv_enrolled bit,
hiv_last_encounter_date date,
valid_from date,
valid_to date,
recent_flag bit
);
 
-- --------- Identifications --------------------------------------------------------

INSERT INTO dim_patients (patient_id) 
SELECT DISTINCT  p.patient_id
FROM patient p
GROUP BY p.patient_id ;

UPDATE dim_patients dp 
SET dp.wellbody_emr_id= (
 SELECT identifier
 FROM patient_identifier 
 WHERE identifier_type =@identifier_type
 AND patient_id=dp.patient_id
 AND voided=0
 ORDER BY preferred desc, date_created desc limit 1
);

UPDATE dim_patients dp 
SET dp.kgh_emr_id= (
 SELECT identifier
 FROM patient_identifier 
 WHERE identifier_type =@kgh_identifier_type
 AND patient_id=dp.patient_id
 AND voided=0
 ORDER BY preferred desc, date_created desc limit 1
);

delete from dim_patients 
where wellbody_emr_id is null and kgh_emr_id is null;

-- --------- Registeration --------------------------------------------------------

UPDATE dim_patients dp
SET -- dp.reg_location=loc_registered(patient_id),
dp.reg_date=CAST(registration_date(patient_id) AS date);

-- --------- Demographical ---------------------------------------------------------

UPDATE dim_patients de 
INNER JOIN (
SELECT person_id,given_name,family_name FROM person_name 
WHERE voided=0 
) pn ON de.patient_id =pn.person_id 
SET de.name=pn.given_name, 
	de.family_name=pn.family_name;

-- -------------------- Bio Information -----------------------

UPDATE dim_patients tt
SET tt.dob= birthdate(tt.patient_id),
tt.gender=gender(tt.patient_id);

UPDATE dim_patients tt INNER JOIN (
SELECT person_id, dead , death_date, cause_of_death, birthdate_estimated 
FROM person p WHERE voided=0
) st 
on  st.person_id =tt.patient_id 
SET tt.dead = st.dead,
	tt.death_date = CAST(st.death_date AS date),
tt.cause_of_death=st.cause_of_death,
tt.dob_estimated=st.birthdate_estimated;


-- --------------------- Patient Status Information --------------------------------------

UPDATE dim_patients de 
INNER JOIN (
	SELECT patient_id, max(encounter_datetime)  encounter_datetime FROM encounter e 
	WHERE encounter_type IN (@etype_ncdinit_id,@etype_ncdf_id)
	-- AND encounter_id > @encounter_last_id
	GROUP BY patient_id
) x
ON de.patient_id =x.patient_id
SET de.ncd_last_encounter_date= cast(x.encounter_datetime AS date);

UPDATE dim_patients de 
INNER JOIN (
	SELECT patient_id, max(encounter_datetime)  encounter_datetime FROM encounter e 
	WHERE encounter_type IN (@etype_echo_id)
	-- AND encounter_id > @encounter_last_id
	GROUP BY patient_id
) x
ON de.patient_id =x.patient_id
SET de.echo_last_encounter_date= cast(x.encounter_datetime AS date);


UPDATE dim_patients de 
INNER JOIN (
	SELECT patient_id, max(encounter_datetime)  encounter_datetime FROM encounter e 
	WHERE encounter_type IN (@etype_hivinit_id,@etype_hivf_id)
	-- AND encounter_id > @encounter_last_id
	GROUP BY patient_id
) x
ON de.patient_id =x.patient_id
SET de.hiv_last_encounter_date= cast(x.encounter_datetime AS date);

UPDATE dim_patients de 
SET de.ncd_enrolled = CASE WHEN de.ncd_last_encounter_date IS NOT NULL THEN TRUE ELSE FALSE END,
de.echo_enrolled = CASE WHEN de.echo_last_encounter_date IS NOT NULL THEN TRUE ELSE FALSE END,
de.hiv_enrolled = CASE WHEN de.hiv_last_encounter_date IS NOT NULL THEN TRUE ELSE FALSE END;

UPDATE dim_patients
SET valid_from=CURRENT_DATE(),
valid_to=NULL, recent_flag=TRUE;


UPDATE dim_patients de 
SET de.reg_location =loc_registered(de.patient_id);


SELECT 
wellbody_emr_id,
kgh_emr_id,
concat(@partition,"-",patient_id)  patient_id,
reg_location,
reg_date,
name,
family_name,
dob,
dob_estimated,
gender,
dead,
death_date,
cause_of_death,
ncd_enrolled,
ncd_last_encounter_date,
echo_enrolled,
echo_last_encounter_date,
hiv_enrolled,
hiv_last_encounter_date,
valid_from,
valid_to,
recent_flag
FROM dim_patients dp;

