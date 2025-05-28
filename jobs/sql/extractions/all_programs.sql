-- All Programs 
SET @partition = '${partitionNum}';

-- Get patient identifier types
SELECT patient_identifier_type_id INTO @identifier_type FROM patient_identifier_type pit WHERE uuid = '1a2acce0-7426-11e5-a837-0800200c9a66';
SELECT patient_identifier_type_id INTO @kgh_identifier_type FROM patient_identifier_type pit WHERE uuid = 'c09a1d24-7162-11eb-8aa6-0242ac110002';

-- Drop and create temporary table
DROP TEMPORARY TABLE IF EXISTS all_programs;

CREATE TEMPORARY TABLE all_programs (
	patient_program_id    INT,
    patient_id            INT,
    wellbody_emr_id       VARCHAR(50),
    kgh_emr_id            VARCHAR(50),
    program_name          VARCHAR(50),
    date_enrolled         DATE,
    date_completed        DATE,
    final_program_status  VARCHAR(100),
    created_by            VARCHAR(50),
    index_asc             INT,
    index_desc            INT
);

-- Insert program data
INSERT INTO all_programs (
	patient_program_id,
    patient_id,
    program_name,
    date_enrolled,
    date_completed,
    final_program_status,
    created_by
)
SELECT 
    pp.patient_program_id,
	pp.patient_id,
    p.name AS program_name,
    pp.date_enrolled,
    pp.date_completed,
    cn.name AS final_program_status,
    u.username AS created_by
FROM 
    patient_program pp
    LEFT JOIN program p ON pp.program_id = p.program_id
    LEFT JOIN users u ON pp.creator = u.user_id
    LEFT JOIN concept_name cn 
        ON pp.outcome_concept_id = cn.concept_id 
        AND cn.voided = 0 
        AND cn.locale = 'en'
WHERE 
    pp.voided = 0;

-- Update identifiers
UPDATE all_programs ae
SET ae.wellbody_emr_id = patient_identifier(ae.patient_id, '1a2acce0-7426-11e5-a837-0800200c9a66');

UPDATE all_programs ae
SET ae.kgh_emr_id = patient_identifier(ae.patient_id, 'c09a1d24-7162-11eb-8aa6-0242ac110002');

-- Remove rows with no EMR IDs
DELETE FROM all_programs 
WHERE wellbody_emr_id IS NULL 
  AND kgh_emr_id IS NULL;

-- Final output
SELECT 
    CONCAT(@partition, "-", patient_program_id) AS patient_program_id,
    CONCAT(@partition, "-", patient_id) AS patient_id,
    wellbody_emr_id,
    kgh_emr_id,
    COALESCE(wellbody_emr_id, kgh_emr_id) AS emr_id,
    program_name,
    date_enrolled,
    date_completed,
    final_program_status,
    created_by AS user_entered,
    index_asc,
    index_desc
FROM 
    all_programs;
