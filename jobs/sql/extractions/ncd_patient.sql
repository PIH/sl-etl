SELECT encounter_type_id  INTO @ncd_init FROM encounter_type et WHERE uuid='ae06d311-1866-455b-8a64-126a9bd74171';
SELECT encounter_type_id  INTO @ncd_followup FROM encounter_type et WHERE uuid='5cbfd6a2-92d9-4ad0-b526-9d29bfe1d10c';
SELECT encounter_type_id INTO @NCDFollowupPart1 FROM encounter_type where uuid = 'e02a8c32-4f14-4ff7-a4e9-2f087d9a1cf7'; 
SELECT encounter_type_id INTO @NCDFollowupPart2 FROM encounter_type where uuid = '6a3afa6f-8f78-44a9-80c9-3f4f3b6ad8f2'; 
SELECT encounter_type_id INTO @NCDInitialPart1 FROM encounter_type where uuid = '48c413c4-e7f6-491a-8431-900451fe8a32'; 
SELECT encounter_type_id INTO @NCDInitialPart2 FROM encounter_type where uuid = '43423212-6f70-4df8-a9f7-2aef88df1ee2'; 

SELECT program_id  INTO @ncd_program FROM program p WHERE uuid='515796ec-bf3a-11e7-abc4-cec278b6b50a';
SELECT encounter_type_id INTO @labResultEnc FROM encounter_type WHERE uuid= '4d77916a-0620-11e5-a6c0-1697f925ec7b';
SELECT concept_id INTO @order_number FROM concept WHERE UUID = '393dec41-2fb5-428f-acfa-36ea85da6666'; 
SELECT concept_id INTO @result_date FROM concept WHERE UUID = '68d6bd27-37ff-4d7a-87a0-f5e0f9c8dcc0'; 
SELECT concept_id INTO @test_location FROM concept WHERE UUID = GLOBAL_PROPERTY_VALUE('labworkflowowa.locationOfLaboratory', 'Unknown Location'); -- test location may differ by implementation
SELECT concept_id INTO @test_status FROM concept WHERE UUID = '7e0cf626-dbe8-42aa-9b25-483b51350bf8'; 
SELECT concept_id INTO @collection_date_estimated FROM concept WHERE UUID = '87f506e3-4433-40ec-b16c-b3c65e402989'; 

SET @partition = '${partitionNum}';

DROP TEMPORARY TABLE IF EXISTS ncd_patient;
CREATE TEMPORARY TABLE ncd_patient (
patient_id                      int,           
emr_id                          varchar(50),  
hiv                             varchar(255), 
education_level                 varchar(255), 
read_and_write                  bit,          
referred_from                   text,         
sickle_cell_confirmatory_test   varchar(255), 
comorbidities                   varchar(255), 
diabetes                        boolean,      
hypertension                    boolean,      
heart_failure                   boolean,      
chronic_lung_disease            boolean,      
chronic_kidney_disease          boolean,      
liver_cirrhosis_hepb            boolean,      
palliative_care                 boolean,      
sickle_cell                     boolean,      
other_ncd                       boolean,      
diabetes_type                   varchar(100), 
hypertension_type               varchar(255),  
rheumatic_heart_disease         boolean,       
congenital_heart_disease        boolean,      
nyha_classification             varchar(255), 
lung_disease_type               varchar(255),  
ckd_stage                       varchar(255), 
sickle_cell_type                varchar(100), 
recent_program_id               int,          
next_appointment_date           date,         
dead                            boolean,       
date_of_death                   date,         
birthdate                       date,         
birthdate_estimated             boolean,      
current_age                     int,           
gender                          varchar(10),  
other_ncd_type                  text,         
most_recent_visit_date          date,         
first_ncd_visit_date            date,         
disposition                     varchar(255), 
ever_missed_school              boolean,      
cardiomyopathy                  boolean,      
most_recent_hba1c_value         int,          
most_recent_hba1c_date          date,         
most_recent_echocardiogram_date date,
date_enrolled                   date,
outcome_date                    date,
outcome                         varchar(255),
calculated_reporting_outcome    varchar(255)
);


DROP TEMPORARY TABLE IF EXISTS temp_encounter;
CREATE TEMPORARY TABLE temp_encounter (
patient_id int,
encounter_id int, 
encounter_type varchar(100) ,
encounter_datetime datetime, 
date_created date,
echocardiogram_obs_group_id int, 
echocardiogram_date	date
);

INSERT INTO temp_encounter
SELECT patient_id,encounter_id, encounter_type ,encounter_datetime, date_created, NULL AS echocardiogram_obs_group_id,
NULL AS echocardiogram_date
FROM encounter e 
WHERE e.encounter_type IN (@ncd_init, @ncd_followup,@NCDInitialPart1, @NCDInitialPart2, @NCDFollowupPart1, @NCDFollowupPart2)
AND e.voided = 0;


DROP TEMPORARY TABLE IF EXISTS recent_encounter;
CREATE TEMPORARY TABLE recent_encounter
SELECT max(encounter_datetime) encounter_datetime, patient_id
FROM temp_encounter
GROUP BY patient_id;

DROP TEMPORARY TABLE IF EXISTS first_encounter;
CREATE TEMPORARY TABLE first_encounter
SELECT min(encounter_datetime) encounter_datetime, patient_id
FROM temp_encounter
GROUP BY patient_id;

create index temp_encounter_ci1 on temp_encounter(encounter_id);
create index temp_encounter_eoi on temp_encounter(echocardiogram_obs_group_id);

DROP TEMPORARY TABLE if exists temp_obs;
CREATE TEMPORARY TABLE temp_obs
select o.obs_id, o.voided, o.obs_group_id, o.encounter_id, o.person_id, o.concept_id, o.value_coded, o.value_numeric, o.value_text, o.value_datetime, o.value_drug, o.comments, o.date_created, o.obs_datetime
,CASE WHEN concept_id=concept_from_mapping('PIH','5629') THEN TRUE ELSE NULL END AS ever_missed_school,
CASE WHEN concept_id=concept_from_mapping('PIH','3064') AND value_coded=concept_from_mapping('PIH','5016') THEN TRUE ELSE NULL END AS cardiomyopathy
from obs o inner join temp_encounter t on o.encounter_id = t.encounter_id
where o.voided = 0;

create index temp_obs_ei on temp_obs(encounter_id);
create index temp_obs_c1 on temp_obs(obs_group_id, concept_id);
create index temp_obs_c2 on temp_obs(encounter_id, concept_id);
create index temp_obs_c3 on temp_obs(person_id, concept_id);
create index temp_obs_c4 on temp_obs(person_id, concept_id, value_coded);

UPDATE temp_encounter t
set echocardiogram_obs_group_id = obs_group_id_of_value_coded_from_temp(encounter_id,'PIH','8614','PIH','3763');

UPDATE temp_encounter t
SET echocardiogram_date= obs_from_group_id_value_datetime_from_temp(t.echocardiogram_obs_group_id,'PIH','12847');

DROP TEMPORARY TABLE IF EXISTS last_echocardiogram;
CREATE TEMPORARY TABLE last_echocardiogram
SELECT patient_id, max(echocardiogram_date) AS echocardiogram_date
FROM temp_encounter te
GROUP BY patient_id;

DROP TEMPORARY TABLE if exists temp_mschool_card;
CREATE TEMPORARY TABLE temp_mschool_card
SELECT person_id, max(ever_missed_school) AS ever_missed_school, max(cardiomyopathy) AS cardiomyopathy
FROM temp_obs
GROUP BY person_id;

INSERT INTO ncd_patient(patient_id, emr_id, 
current_age, gender, dead, date_of_death, birthdate)
SELECT DISTINCT patient_id,
patient_identifier(patient_id, metadata_uuid('org.openmrs.module.emrapi', 'emr.primaryIdentifierType')) AS emr_id,
current_age_in_years(patient_id),
gender(patient_id), 
dead(patient_id),
death_date(patient_id),
birthdate(patient_id)
FROM temp_encounter;

create index ncd_patient_i1 on ncd_patient(patient_id); 

-- Patient details columns
UPDATE ncd_patient
SET education_level = last_value_coded_list_from_temp(patient_id, 'PIH', '1688','en');

UPDATE ncd_patient
SET read_and_write = value_coded_as_boolean(latest_obs_from_temp(patient_id, 'PIH','13736'));

UPDATE ncd_patient
SET referred_from = last_value_coded_list_from_temp(patient_id, 'PIH', '7454','en');

-- update referred from to match form
UPDATE ncd_patient
set referred_from = replace(referred_from,'Hospitalized','Inpatient Ward');
UPDATE ncd_patient
set referred_from =  replace(referred_from,'Primary care clinic','OPD');

UPDATE ncd_patient
SET sickle_cell_confirmatory_test = last_value_coded_list_from_temp(patient_id, 'PIH', '15143','en');

UPDATE ncd_patient tgt 
INNER JOIN last_echocardiogram lc ON tgt.patient_id = lc.patient_id
SET tgt.most_recent_echocardiogram_date= lc.echocardiogram_date;

UPDATE ncd_patient tgt 
INNER JOIN person p ON tgt.patient_id = p.person_id
AND p.voided=0
SET tgt.birthdate_estimated= p.birthdate_estimated;

UPDATE ncd_patient
SET diabetes = answerEverExists_from_temp(patient_id, 'PIH', '10529','PIH', '3720', NULL);

UPDATE ncd_patient
SET hypertension = answerEverExists_from_temp(patient_id, 'PIH', '10529','PIH', '903', NULL);

UPDATE ncd_patient
SET heart_failure = answerEverExists_from_temp(patient_id, 'PIH', '10529','PIH', '3468', NULL);

UPDATE ncd_patient
SET chronic_lung_disease = answerEverExists_from_temp(patient_id, 'PIH', '10529','PIH', '6768', NULL);

UPDATE ncd_patient
SET chronic_kidney_disease = answerEverExists_from_temp(patient_id, 'PIH', '10529','PIH', '3699', NULL);

UPDATE ncd_patient
SET liver_cirrhosis_hepb = answerEverExists_from_temp(patient_id, 'PIH', '10529','PIH', '3714', NULL);

UPDATE ncd_patient
SET palliative_care = answerEverExists_from_temp(patient_id, 'PIH', '10529','PIH', '10359', NULL);

UPDATE ncd_patient
SET sickle_cell = answerEverExists_from_temp(patient_id, 'PIH', '10529','PIH', '7908', NULL);

UPDATE ncd_patient
SET other_ncd = answerEverExists_from_temp(patient_id, 'PIH', '10529','PIH', '5622', NULL);

UPDATE ncd_patient
SET hypertension_type = last_value_coded_list_from_temp(patient_id, 'PIH', '11940','en');

UPDATE ncd_patient
SET diabetes_type = CASE WHEN answerEverExists_from_temp(patient_id,'PIH','3064', 'PIH', '6692', null) THEN 'Type 2 DM'
WHEN answerEverExists_from_temp(patient_id,'PIH','3064', 'PIH', '6691', null) THEN 'Type 1 DM'
WHEN answerEverExists_from_temp(patient_id,'PIH','3064', 'PIH', '6693', null) THEN 'Gestational DM'
WHEN answerEverExists_from_temp(patient_id,'PIH','3064', 'PIH', '3720', null) THEN 'DM not yet specified' 
ELSE NULL
END;

UPDATE ncd_patient
SET rheumatic_heart_disease = answerEverExists_from_temp(patient_id, 'PIH', '3064','PIH', '221', NULL);

UPDATE ncd_patient
SET congenital_heart_disease = answerEverExists_from_temp(patient_id, 'PIH', '3064','PIH', '3131', NULL );

UPDATE ncd_patient
SET nyha_classification = last_value_coded_list_from_temp(patient_id, 'PIH', '3139','en');

UPDATE ncd_patient
SET lung_disease_type = last_value_coded_list_from_temp(patient_id, 'PIH', '14599','en');

UPDATE ncd_patient
SET ckd_stage = last_value_coded_list_from_temp(patient_id, 'PIH', '12501','en');

UPDATE ncd_patient
SET sickle_cell_type = 
CASE WHEN answerEverExists_from_temp(patient_id,'PIH','3064', 'PIH', '7908', null) THEN 'Sickle-cell anemia (SS)'
     WHEN answerEverExists_from_temp(patient_id,'PIH','3064', 'PIH', '7915', null) THEN 'Sickle-cell trait (AS)'
     WHEN answerEverExists_from_temp(patient_id,'PIH','3064', 'PIH', '14923', null) THEN 'Sickle-cell beta thalassemia (SB)' 
     WHEN answerEverExists_from_temp(patient_id,'PIH','3064', 'PIH', '12715', null) THEN 'Sickle-cell hemoglobin C disease (SC)' 
     WHEN answerEverExists_from_temp(patient_id,'PIH','3064', 'PIH', '10134', null) THEN 'Other hemoglobinopathy' 
     ELSE NULL
     END;

UPDATE ncd_patient
SET next_appointment_date = CAST(last_value_datetime_from_temp(patient_id, 'PIH','5096') AS date); 

UPDATE ncd_patient
SET recent_program_id = mostRecentPatientProgramId(patient_id, @ncd_program);

UPDATE ncd_patient tgt 
SET disposition= last_value_coded_list_from_temp(patient_id, 'PIH', '8620',@locale);

UPDATE ncd_patient
SET hiv = last_value_coded_list_from_temp(patient_id, 'PIH', '1169','en');

UPDATE ncd_patient
SET comorbidities = last_value_coded_list_from_temp(patient_id, 'PIH', '12976','en');

UPDATE ncd_patient
SET other_ncd_type = last_value_text_from_temp(patient_id, 'PIH', '7416');

UPDATE ncd_patient tgt 
INNER JOIN recent_encounter re ON tgt.patient_id = re.patient_id 
SET most_recent_visit_date = re.encounter_datetime ;

UPDATE ncd_patient tgt 
INNER JOIN first_encounter re ON tgt.patient_id = re.patient_id 
SET first_ncd_visit_date = re.encounter_datetime ;

UPDATE ncd_patient tgt 
INNER JOIN temp_mschool_card tm ON tgt.patient_id =tm.person_id 
SET tgt.ever_missed_school=tm.ever_missed_school, tgt.cardiomyopathy=tm.cardiomyopathy;

DROP TABLE IF EXISTS hb1ac_results;
CREATE TABLE hb1ac_results AS
SELECT e.encounter_id, cast(e.encounter_datetime AS date) AS encounter_date, CAST(o.obs_datetime AS date) AS obs_date,
o.person_id, o.value_numeric 
FROM encounter e 
INNER JOIN obs o ON e.encounter_id = o.encounter_id 
WHERE e.encounter_type =@labResultEnc
AND o.concept_id NOT IN (@order_number,@result_date,@test_location,@test_status,@collection_date_estimated)
AND o.concept_id = concept_from_mapping('PIH','7460');


UPDATE ncd_patient t
INNER JOIN hb1ac_results o ON t.patient_id=o.person_id
SET t.most_recent_hba1c_value= o.value_numeric;

UPDATE ncd_patient t
INNER JOIN (SELECT max(encounter_date) AS encounter_date, person_id 
FROM hb1ac_results
GROUP BY person_id
) o
ON t.patient_id=o.person_id
SET t.most_recent_hba1c_date= o.encounter_date;

UPDATE ncd_patient n
inner join patient_program pp on pp.patient_program_id = recent_program_id
set n.date_enrolled = pp.date_enrolled,
    n.outcome_date = date_completed,
	n.outcome = concept_name(outcome_concept_id, @locale);

UPDATE ncd_patient n 
set calculated_reporting_outcome = outcome;

UPDATE ncd_patient n 
set calculated_reporting_outcome = 'Lost to followup'  
where (DATEDIFF(now(), COALESCE(most_recent_visit_date, date_enrolled)) > 90
	and DATEDIFF(now(),next_appointment_date) > 180)
and outcome_date is null;

SELECT
if(@partition REGEXP '^[0-9]+$' = 1,concat(@partition,'-',patient_id),patient_id) "patient_id",
emr_id,
hiv,
education_level,
read_and_write,
referred_from,
comorbidities,
diabetes,
hypertension,
heart_failure,
chronic_lung_disease,
chronic_kidney_disease,
liver_cirrhosis_hepb,
palliative_care,
sickle_cell,
other_ncd,
diabetes_type,
hypertension_type,
rheumatic_heart_disease,
congenital_heart_disease,
nyha_classification,
lung_disease_type,
ckd_stage,
sickle_cell_type,
sickle_cell_confirmatory_test,
cast(next_appointment_date as date) as next_appointment_date,
dead,
cast(date_of_death as date) as date_of_death,
cast(birthdate as date) as birthdate,
birthdate_estimated,
current_age,
gender,
other_ncd_type,
cast(most_recent_visit_date as date) as most_recent_visit_date,
cast(first_ncd_visit_date as date) as first_ncd_visit_date,
disposition,
ever_missed_school,
cardiomyopathy,
most_recent_hba1c_value,
most_recent_hba1c_date,
most_recent_echocardiogram_date,
date_enrolled,
outcome_date,
outcome,
calculated_reporting_outcome 
FROM ncd_patient;
