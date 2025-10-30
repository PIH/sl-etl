-- Set up locale and encounter type variables
SET @locale = GLOBAL_PROPERTY_VALUE('default_locale', 'en');

SELECT encounter_type_id INTO @ncd_intake FROM encounter_type et WHERE uuid = 'ae06d311-1866-455b-8a64-126a9bd74171';
SELECT encounter_type_id INTO @ncd_followup FROM encounter_type et WHERE uuid = '5cbfd6a2-92d9-4ad0-b526-9d29bfe1d10c';
SELECT encounter_type_id INTO @NCDFollowupPart1 FROM encounter_type where uuid = 'e02a8c32-4f14-4ff7-a4e9-2f087d9a1cf7'; 
SELECT encounter_type_id INTO @NCDFollowupPart2 FROM encounter_type where uuid = '6a3afa6f-8f78-44a9-80c9-3f4f3b6ad8f2'; 
SELECT encounter_type_id INTO @NCDInitialPart1 FROM encounter_type where uuid = '48c413c4-e7f6-491a-8431-900451fe8a32'; 
SELECT encounter_type_id INTO @NCDInitialPart2 FROM encounter_type where uuid = '43423212-6f70-4df8-a9f7-2aef88df1ee2'; 


SET @partition = '${partitionNum}';

-- Diagnoses table
DROP TEMPORARY TABLE IF EXISTS temp_ncd_diagnoses;
CREATE TEMPORARY TABLE temp_ncd_diagnoses (
    obs_id                  INT(11),
    obs_group_id            INT(11),
    patient_id              INT(11),
    emr_id                  VARCHAR(50),
    ncd_program_id          INT(11),
    encounter_id            INT(11),
    encounter_datetime      DATETIME,
    encounter_location_id   INT(11),
    encounter_location      VARCHAR(255),
    datetime_entered        DATE,
    creator                 INT(11),
    user_entered            VARCHAR(255),
    provider                VARCHAR(255),
    encounter_type_id       INT(11),
    encounter_type          VARCHAR(255),
    dx_order                VARCHAR(255),
    certainty               VARCHAR(255),
    coded                   BIT,
    diagnosis_concept_id    INT(11),
    coded_diagnosis         VARCHAR(255),
    non_coded_diagnosis     VARCHAR(255),
    diagnosis_entered       VARCHAR(255),
    icd10_code              varchar(255),
    index_asc               INT,
    index_desc              INT
);

SET @dx_coded_concept_id    = concept_from_mapping('PIH','3064');
SET @dx_non_coded_concept_id= concept_from_mapping('PIH','7416');

-- Insert coded diagnoses
INSERT INTO temp_ncd_diagnoses (
	obs_id,
	obs_group_id,
    patient_id,
    encounter_id,
    encounter_type_id,
    encounter_datetime,
    encounter_location_id,
    datetime_entered,
    creator,
    diagnosis_concept_id,
    coded
)
SELECT
    obs_id,
    obs_group_id,
    patient_id,
    o.encounter_id,
    e.encounter_type,
    encounter_datetime,
    e.location_id,
    o.date_created,
    o.creator,
    o.value_coded,
    1
FROM obs o
INNER JOIN encounter e
    ON o.encounter_id = e.encounter_id
    AND e.encounter_type IN (@ncd_intake, @ncd_followup, @NCDInitialPart1, @NCDInitialPart2, @NCDFollowupPart1, @NCDFollowupPart2)
WHERE o.concept_id = @dx_coded_concept_id
  AND o.voided = 0
  AND e.voided = 0;

-- Insert non-coded diagnoses
INSERT INTO temp_ncd_diagnoses (
    obs_id,
    obs_group_id,
    patient_id,
    encounter_id,
    encounter_type_id,
    encounter_datetime,
    encounter_location_id,
    datetime_entered,
    creator,
    non_coded_diagnosis,
    coded
)
SELECT
    obs_id,
    obs_group_id,
    patient_id,
    o.encounter_id,
    e.encounter_type,
    encounter_datetime,
    e.location_id,
    o.date_created,
    o.creator,
    o.value_text,
    0
FROM obs o
INNER JOIN encounter e
    ON o.encounter_id = e.encounter_id
    AND e.encounter_type IN (@ncd_intake, @ncd_followup)
WHERE o.concept_id = @dx_non_coded_concept_id
  AND o.voided = 0
  AND e.voided = 0;

CREATE INDEX temp_ncd_diagnoses_ei ON temp_ncd_diagnoses(encounter_id);

-- Encounter-level columns
DROP TEMPORARY TABLE IF EXISTS  temp_ncd_dx_encounters;
CREATE TEMPORARY TABLE  temp_ncd_dx_encounters (
    patient_id              INT(11),
    encounter_id            INT(11),
    ncd_program_id          INT(11),
    encounter_location_id   INT(11),
    encounter_location      VARCHAR(255),
    creator                 INT(11),
    user_entered            VARCHAR(255),
    provider      VARCHAR(255),
    encounter_type_id       INT(11),
    encounter_type          VARCHAR(255)
);

INSERT INTO  temp_ncd_dx_encounters (
    patient_id,
    encounter_id,
    encounter_location_id,
    creator,
    encounter_type_id
)
SELECT DISTINCT
    patient_id,
    encounter_id,
    encounter_location_id,
    creator,
    encounter_type_id
FROM temp_ncd_diagnoses;

CREATE INDEX  temp_ncd_dx_encounters_ei ON  temp_ncd_dx_encounters(encounter_id);

UPDATE  temp_ncd_dx_encounters
SET encounter_location = location_name(encounter_location_id);

UPDATE  temp_ncd_dx_encounters
SET user_entered = person_name_of_user(creator);

UPDATE  temp_ncd_dx_encounters n
INNER JOIN encounter_type et
    ON et.encounter_type_id = n.encounter_type_id
SET encounter_type = et.name;

UPDATE  temp_ncd_dx_encounters
SET provider = provider(encounter_id);

SET @ncdProgramId = program('NCD');
UPDATE  temp_ncd_dx_encounters
SET ncd_program_id = patient_program_id_from_encounter(patient_id, @ncdProgramId, encounter_id);

UPDATE temp_ncd_diagnoses d
INNER JOIN  temp_ncd_dx_encounters de
    ON de.encounter_id = d.encounter_id
SET d.encounter_location = de.encounter_location,
    d.user_entered = de.user_entered,
    d.encounter_type = de.encounter_type,
    d.provider = de.provider,
    d.ncd_program_id = de.ncd_program_id;

-- Patient-level columns
DROP TEMPORARY TABLE IF EXISTS temp_emrids;
CREATE TEMPORARY TABLE temp_emrids (
    patient_id              INT(11),
    emr_id                  VARCHAR(50)
);

INSERT INTO temp_emrids(patient_id)
SELECT DISTINCT patient_id
FROM temp_ncd_diagnoses;

CREATE INDEX temp_emrids_patient_id ON temp_emrids(patient_id);

SET @primary_emr_id_type = metadata_uuid('org.openmrs.module.emrapi', 'emr.primaryIdentifierType');
UPDATE temp_emrids
SET emr_id = patient_identifier(patient_id, @primary_emr_id_type);

UPDATE temp_ncd_diagnoses n
INNER JOIN temp_emrids e
    ON e.patient_id = n.patient_id
SET n.emr_id = e.emr_id;

-- Diagnosis-level columns
DROP TEMPORARY TABLE IF EXISTS temp_obs;
CREATE TEMPORARY TABLE temp_obs AS
SELECT
    o.obs_id,
    o.voided,
    o.obs_group_id,
    o.encounter_id,
    o.person_id,
    o.concept_id,
    o.value_coded,
    o.value_numeric,
    o.value_text,
    o.value_datetime,
    o.value_coded_name_id,
    o.comments
FROM obs o
INNER JOIN temp_ncd_diagnoses n
    ON n.obs_group_id = o.obs_group_id
WHERE o.voided = 0;

CREATE INDEX temp_obs_ogi ON temp_obs(obs_group_id);

UPDATE temp_ncd_diagnoses
SET coded_diagnosis = concept_name(diagnosis_concept_id, @locale);

UPDATE temp_ncd_diagnoses
SET certainty = obs_from_group_id_value_coded_list_from_temp(obs_group_id, 'PIH','1379', @locale);

UPDATE temp_ncd_diagnoses
SET dx_order= obs_from_group_id_value_coded_list_from_temp(obs_group_id, 'PIH','7537', @locale); 

UPDATE temp_ncd_diagnoses
SET diagnosis_entered =
CASE
	when coded = 1 then coded_diagnosis 
	else non_coded_diagnosis
END;

UPDATE temp_ncd_diagnoses
SET icd10_code = retrieveICD10(diagnosis_concept_id); 

-- Final output
SELECT
    CONCAT(@partition, '-', obs_id)         AS "obs_id",
    CONCAT(@partition, '-', patient_id)        AS "patient_id",
    emr_id,
    CONCAT(@partition, '-', ncd_program_id)    AS "ncd_program_id",
    CONCAT(@partition, '-', encounter_id)      AS "encounter_id",
    encounter_datetime,
    encounter_location,
    datetime_entered,
    user_entered,
    provider,
    encounter_type,
    diagnosis_entered,
    dx_order,
    certainty,
    coded,
    icd10_code,
    index_asc,
    index_desc
FROM temp_ncd_diagnoses;
