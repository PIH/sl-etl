DROP TABLE IF EXISTS ncd_penplus_disease_condition_staging;
CREATE TABLE ncd_penplus_disease_condition_staging
(
    disease_condition_index   INT               IDENTITY(1,1) PRIMARY KEY,
    ncd_program_id            VARCHAR(50),
    patient_id                VARCHAR(50),
    emr_id                    VARCHAR(50),
    dead                      BIT,
    death_date                DATE,
    age_at_diagnosis          FLOAT,
    gender                    VARCHAR(50),
    birthdate                 DATE,
    disease_condition         TEXT,
    disease_category          TEXT,
    first_instance            DATETIME,
    latest_instance           DATETIME,
    outcome                   VARCHAR(255),
    site                      VARCHAR(100),
    index_asc                 INT,
    index_desc                INT,
    index_program_asc         INT,
    index_program_desc        INT
);

-- Diabetes: Type 1
INSERT INTO ncd_penplus_disease_condition_staging 
    (ncd_program_id, patient_id, emr_id, site, first_instance, latest_instance, disease_category, disease_condition)
SELECT ncd_program_id, patient_id, emr_id, site, MIN(encounter_datetime), MAX(encounter_datetime), 'Diabetes', 'Type 1 Diabetes'
FROM ncd_encounter
WHERE diabetes_type = 'Type 1 diabetes'
GROUP BY ncd_program_id, patient_id, emr_id, site;

-- Diabetes: Type 2
INSERT INTO ncd_penplus_disease_condition_staging 
    (ncd_program_id, patient_id, emr_id, site, first_instance, latest_instance, disease_category, disease_condition)
SELECT ncd_program_id, patient_id, emr_id, site, MIN(encounter_datetime), MAX(encounter_datetime), 'Diabetes', 'Type 2 Diabetes'
FROM ncd_encounter
WHERE diabetes_type = 'Type 2 diabetes'
GROUP BY ncd_program_id, patient_id, emr_id, site;

-- Diabetes: Unspecified/Gestational
INSERT INTO ncd_penplus_disease_condition_staging 
    (ncd_program_id, patient_id, emr_id, site, first_instance, latest_instance, disease_category, disease_condition)
SELECT ncd_program_id, patient_id, emr_id, site, MIN(encounter_datetime), MAX(encounter_datetime), 'Diabetes', 'Unspecified/Gestational Diabetes'
FROM ncd_encounter
WHERE diabetes_type NOT IN ('Type 1 diabetes', 'Type 2 diabetes')
  AND diabetes_section_populated = 1
GROUP BY ncd_program_id, patient_id, emr_id, site;

-- Cardiac: Rheumatic heart disease
INSERT INTO ncd_penplus_disease_condition_staging 
    (ncd_program_id, patient_id, emr_id, site, first_instance, latest_instance, disease_category, disease_condition)
SELECT ncd_program_id, patient_id, emr_id, site, MIN(encounter_datetime), MAX(encounter_datetime), 'Cardiac', 'Rheumatic heart disease'
FROM ncd_diagnoses
WHERE diagnosis_entered = 'Rheumatic heart disease'
GROUP BY ncd_program_id, patient_id, emr_id, site;

-- Cardiac: Congenital heart disease
INSERT INTO ncd_penplus_disease_condition_staging 
    (ncd_program_id, patient_id, emr_id, site, first_instance, latest_instance, disease_category, disease_condition)
SELECT ncd_program_id, patient_id, emr_id, site, MIN(encounter_datetime), MAX(encounter_datetime), 'Cardiac', 'Congenital heart disease'
FROM ncd_diagnoses
WHERE diagnosis_entered = 'Congenital heart disease'
GROUP BY ncd_program_id, patient_id, emr_id, site;

-- Cardiac: Heart Failure
INSERT INTO ncd_penplus_disease_condition_staging 
    (ncd_program_id, patient_id, emr_id, site, first_instance, latest_instance, disease_category, disease_condition)
SELECT ncd_program_id, patient_id, emr_id, site, MIN(encounter_datetime), MAX(encounter_datetime), 'Cardiac', 'Heart Failure'
FROM ncd_diagnoses
WHERE diagnosis_entered IN (
    'Cardiomyopathy',
    'Degenerative heart disease',
    'Right heart failure',
    'Pericardial disease',
    'Other heart valve disease or congenital heart disease',
    'Unknown heart failure without echocardiogram'
)
GROUP BY ncd_program_id, patient_id, emr_id, site;

-- Cardiac: Other/Unspecified Cardiac Condition
INSERT INTO ncd_penplus_disease_condition_staging 
    (ncd_program_id, patient_id, emr_id, site, first_instance, latest_instance, disease_category, disease_condition)
SELECT ncd_program_id, patient_id, emr_id, site, MIN(encounter_datetime), MAX(encounter_datetime), 'Cardiac', 'Other/Unspecified Cardiac Condition'
FROM ncd_encounter e
WHERE heart_failure_section_populated = 1
  AND NOT EXISTS (
    SELECT 1 FROM ncd_diagnoses d WHERE d.diagnosis_entered IN (
        'Cardiomyopathy',
        'Hypertensive cardiomyopathy',
        'Rheumatic heart disease',
        'Degenerative heart disease',
        'Right heart failure',
        'Pericardial disease',
        'Congenital heart disease',
        'Other heart valve disease or congenital heart disease',
        'Unknown heart failure without echocardiogram'
    )
    AND d.encounter_id = e.encounter_id
)
GROUP BY ncd_program_id, patient_id, emr_id, site;

-- Cardiac: Hypertension
INSERT INTO ncd_penplus_disease_condition_staging 
    (ncd_program_id, patient_id, emr_id, site, first_instance, latest_instance, disease_category, disease_condition)
SELECT ncd_program_id, patient_id, emr_id, site, MIN(encounter_datetime), MAX(encounter_datetime), 'Cardiac', 'Hypertension'
FROM ncd_encounter
WHERE hypertension_section_populated = 1
GROUP BY ncd_program_id, patient_id, emr_id, site;

-- Sickle Cell
INSERT INTO ncd_penplus_disease_condition_staging 
    (ncd_program_id, patient_id, emr_id, site, first_instance, latest_instance, disease_category, disease_condition)
SELECT ncd_program_id, patient_id, emr_id, site, MIN(encounter_datetime), MAX(encounter_datetime), 'Sickle Cell', 'Sickle Cell'
FROM ncd_diagnoses
WHERE diagnosis_entered IN (
    'Sickle cell beta thalassemia',
    'Sickle cell disease',
    'Sickle-cell trait',
    'HbSC (Disease)'
)
GROUP BY ncd_program_id, patient_id, emr_id, site;

-- Thalassemia
INSERT INTO ncd_penplus_disease_condition_staging 
    (ncd_program_id, patient_id, emr_id, site, first_instance, latest_instance, disease_category, disease_condition)
SELECT ncd_program_id, patient_id, emr_id, site, MIN(encounter_datetime), MAX(encounter_datetime), 'Sickle Cell', 'Thalessemia'
FROM ncd_diagnoses
WHERE diagnosis_entered = 'Sickle cell beta thalassemia'
GROUP BY ncd_program_id, patient_id, emr_id, site;

-- Respiratory: Chronic Respiratory Disease
INSERT INTO ncd_penplus_disease_condition_staging 
    (ncd_program_id, patient_id, emr_id, site, first_instance, latest_instance, disease_category, disease_condition)
SELECT ncd_program_id, patient_id, emr_id, site, MIN(encounter_datetime), MAX(encounter_datetime), 'Respiratory', 'Chronic Respiratory Disease'
FROM ncd_encounter
WHERE lung_section_populated = 1
GROUP BY ncd_program_id, patient_id, emr_id, site;

-- Kidney: Chronic Kidney Disease
INSERT INTO ncd_penplus_disease_condition_staging 
    (ncd_program_id, patient_id, emr_id, site, first_instance, latest_instance, disease_category, disease_condition)
SELECT ncd_program_id, patient_id, emr_id, site, MIN(encounter_datetime), MAX(encounter_datetime), 'Kidney', 'Chronic Kidney Disease'
FROM ncd_encounter
WHERE kidney_section_populated = 1
GROUP BY ncd_program_id, patient_id, emr_id, site;

-- Liver: Chronic Liver Disease
INSERT INTO ncd_penplus_disease_condition_staging 
    (ncd_program_id, patient_id, emr_id, site, first_instance, latest_instance, disease_category, disease_condition)
SELECT ncd_program_id, patient_id, emr_id, site, MIN(encounter_datetime), MAX(encounter_datetime), 'Liver', 'Chronic Liver Disease'
FROM ncd_encounter
WHERE liver_section_populated = 1
GROUP BY ncd_program_id, patient_id, emr_id, site;

-- Other NCD condition (palliative care or Hemoglobinopathy)
INSERT INTO ncd_penplus_disease_condition_staging 
    (ncd_program_id, patient_id, emr_id, site, first_instance, latest_instance, disease_category, disease_condition)
SELECT ncd_program_id, patient_id, emr_id, site, MIN(encounter_datetime), MAX(encounter_datetime), 'other NCD', 'Other NCD condition'
FROM ncd_encounter n
WHERE palliative_care_section_populated = 1
   OR EXISTS (
        SELECT 1 FROM ncd_diagnoses d
        WHERE d.encounter_id = n.encounter_id
          AND diagnosis_entered = 'Hemoglobinopathy'
      )
GROUP BY ncd_program_id, patient_id, emr_id, site;

-- Other NCD condition (not already captured)
INSERT INTO ncd_penplus_disease_condition_staging 
    (ncd_program_id, patient_id, emr_id, site, first_instance, latest_instance, disease_category, disease_condition)
SELECT ncd_program_id, patient_id, emr_id, site, MIN(encounter_datetime), MAX(encounter_datetime), 'other NCD', 'Other NCD condition'
FROM ncd_encounter n
WHERE NOT EXISTS (
    SELECT 1 FROM ncd_penplus_disease_condition_staging d
    WHERE isnull(d.ncd_program_id,0) = isnull(n.ncd_program_id,0)
--      AND n.encounter_datetime >= d.first_instance
--      AND n.encounter_datetime <= d.latest_instance
)
GROUP BY ncd_program_id, patient_id, emr_id, site;

-- Update demographic and death info
UPDATE n
SET n.dead        = p.dead,
    n.death_date  = p.death_date,
    n.gender      = p.gender,
    n.birthdate   = p.birthdate
FROM ncd_penplus_disease_condition_staging n
INNER JOIN all_patients p ON p.patient_id = n.patient_id;

-- Calculate age at diagnosis
UPDATE n
SET n.age_at_diagnosis = DATEDIFF(YEAR, birthdate, first_instance)
FROM ncd_penplus_disease_condition_staging n;

-- Indexing (asc, desc)
DROP TABLE IF EXISTS #derived_indexes;
SELECT  disease_condition_index,
        ROW_NUMBER() OVER (PARTITION BY patient_id ORDER BY first_instance, disease_condition_index) AS index_asc,
        ROW_NUMBER() OVER (PARTITION BY patient_id ORDER BY first_instance DESC, disease_condition_index DESC) AS index_desc
INTO    #derived_indexes
FROM    ncd_penplus_disease_condition_staging;

UPDATE t
SET t.index_asc  = i.index_asc,
    t.index_desc = i.index_desc
FROM ncd_penplus_disease_condition_staging t
INNER JOIN #derived_indexes i ON i.disease_condition_index = t.disease_condition_index;

-- Indexing by program (asc, desc)
DROP TABLE IF EXISTS #derived_indexes;
SELECT  disease_condition_index,
        ROW_NUMBER() OVER (PARTITION BY ncd_program_id, patient_id ORDER BY first_instance, disease_condition_index) AS index_program_asc,
        ROW_NUMBER() OVER (PARTITION BY ncd_program_id, patient_id ORDER BY first_instance DESC, disease_condition_index DESC) AS index_program_desc
INTO    #derived_indexes
FROM    ncd_penplus_disease_condition_staging;

UPDATE t
SET t.index_program_asc  = i.index_program_asc,
    t.index_program_desc = i.index_program_desc
FROM ncd_penplus_disease_condition_staging t
INNER JOIN #derived_indexes i ON i.disease_condition_index = t.disease_condition_index;

-- Finalize
DROP TABLE IF EXISTS ncd_penplus_disease_condition;
EXEC sp_rename 'ncd_penplus_disease_condition_staging', 'ncd_penplus_disease_condition';
