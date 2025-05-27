-- Set partition parameter
-- set @startDate = '2021-01-01';
-- set @endDate = '2021-01-31';
SET @partition = '${partitionNum}';

-- Create temporary table for all diagnoses
DROP TEMPORARY TABLE IF EXISTS all_diagnosis;
CREATE TEMPORARY TABLE all_diagnosis (
    patient_id           INT,
    patient_primary_id   VARCHAR(50),
    loc_registered       VARCHAR(255),
    unknown_patient      boolean,
    gender               VARCHAR(50),
    age_at_encounter     INT,
    district             VARCHAR(255),
    chiefdom             VARCHAR(255),
    encounter_id         INT,
    encounter_location   VARCHAR(255),
    obs_id               INT,
    obs_group_id         INT,
    value_text           TEXT, 
    obs_datetime         DATETIME,
    entered_by           VARCHAR(255),
    provider             VARCHAR(255),
    diagnosis_entered    TEXT,
    dx_order             VARCHAR(255),
    certainty            VARCHAR(255),
    coded                VARCHAR(255),
    diagnosis_concept    INT,
    diagnosis_coded_en   VARCHAR(255),
    icd10_code           VARCHAR(255),
    notifiable           INT,
    urgent               INT,
    womens_health        INT,
    psychological        INT,
    pediatric            INT,
    outpatient           INT,
    ncd                  INT,
    non_diagnosis        INT,
    ed                   INT,
    age_restricted       INT,
    oncology             INT,
    date_created         DATETIME,
    retrospective        INT,
    visit_id             INT,
    birthdate            DATETIME,
    birthdate_estimated  BIT,
    encounter_type       VARCHAR(255),
    index_asc            INT,
    index_desc           INT
);

-- Set concept mappings
SET @coded_dx = concept_from_mapping('PIH', '3064');
SET @non_coded_dx = concept_from_mapping('PIH', '7416');

-- Insert into all_diagnosis
INSERT INTO all_diagnosis (
    patient_id,
    encounter_id,
    obs_id,
    diagnosis_concept,
    obs_group_id,
    obs_datetime,
    date_created,
    value_text
)
SELECT
    o.person_id,
    o.encounter_id,
    o.obs_id,
    o.value_coded,
    o.obs_group_id,
    o.obs_datetime,
    o.date_created,
    o.value_text
FROM obs o
WHERE concept_id IN (@coded_dx, @non_coded_dx)
  AND o.voided = 0;

-- Indexes
CREATE INDEX all_diagnosis_e ON all_diagnosis(encounter_id);
CREATE INDEX all_diagnosis_p ON all_diagnosis(patient_id);
CREATE INDEX all_diagnosis_dc ON all_diagnosis(diagnosis_concept);

-- Patient-level information
DROP TEMPORARY TABLE IF EXISTS temp_dx_patient;
CREATE TEMPORARY TABLE temp_dx_patient (
    patient_id           INT(11),
    patient_primary_id   VARCHAR(50),
    loc_registered       VARCHAR(255),
    unknown_patient      boolean,
    gender               VARCHAR(50),
    district             VARCHAR(255),
    chiefdom             VARCHAR(255),
    birthdate            DATETIME,
    birthdate_estimated  BIT
);

INSERT INTO temp_dx_patient(patient_id)
SELECT DISTINCT patient_id FROM all_diagnosis;

CREATE INDEX temp_dx_patient_pi ON temp_dx_patient(patient_id);

-- Populate patient info
set @primary_emr_id = metadata_uuid('org.openmrs.module.emrapi', 'emr.primaryIdentifierType');
UPDATE temp_dx_patient
SET patient_primary_id = patient_identifier(patient_id,@primary_emr_id),
    loc_registered = loc_registered(patient_id),
    unknown_patient = if(unknown_patient(patient_id) is null, null, 1),
    gender = gender(patient_id);

UPDATE temp_dx_patient t
JOIN person p ON p.person_id = t.patient_id
SET t.birthdate = p.birthdate,
    t.birthdate_estimated = p.birthdate_estimated;

UPDATE temp_dx_patient
SET district = person_address_county_district(patient_id),
    chiefdom = person_address_state_province(patient_id);

UPDATE all_diagnosis d 
inner join temp_dx_patient t on t.patient_id = d.patient_id
set d.patient_primary_id = t.patient_primary_id,
	d.loc_registered = t.loc_registered,
	d.unknown_patient = t.unknown_patient,
	d.gender = t.gender,
	d.district = t.district,
	d.chiefdom = t.chiefdom,
	d.birthdate = t.birthdate,
	d.birthdate_estimated = t.birthdate_estimated;

-- Encounter-level information
DROP TEMPORARY TABLE IF EXISTS temp_dx_encounter;
CREATE TEMPORARY TABLE temp_dx_encounter (
    patient_id           INT(11),
    encounter_id         INT(11),
    encounter_location   VARCHAR(255),
    age_at_encounter     INT(3),
    entered_by           VARCHAR(255),
    provider             VARCHAR(255),
    date_created         DATETIME,
    retrospective        INT(1),
    visit_id             INT(11),
    encounter_type       VARCHAR(255)
);

INSERT INTO temp_dx_encounter(patient_id, encounter_id)
SELECT DISTINCT patient_id, encounter_id FROM all_diagnosis;

CREATE INDEX temp_dx_encounter_ei ON temp_dx_encounter(encounter_id);

-- Populate encounter info
UPDATE temp_dx_encounter
SET encounter_location = encounter_location_name(encounter_id),
    provider = provider(encounter_id),
    age_at_encounter = age_at_enc(patient_id, encounter_id);

UPDATE temp_dx_encounter t
JOIN encounter e ON e.encounter_id = t.encounter_id
JOIN users u ON u.user_id = e.creator
SET t.entered_by = person_name(u.person_id),
    t.visit_id = e.visit_id,
    t.encounter_type = encounterName(e.encounter_type),
    t.date_created = e.date_created;

UPDATE all_diagnosis d 
inner join temp_dx_encounter t on t.encounter_id = d.encounter_id
set d.encounter_location = t.encounter_location,
	d.age_at_encounter = t.age_at_encounter,
	d.entered_by = t.entered_by,
	d.provider = t.provider,
	d.date_created = t.date_created,
	d.retrospective = t.retrospective,
	d.visit_id = t.visit_id,
	d.encounter_type = t.encounter_type;

-- Diagnosis info
DROP TEMPORARY TABLE IF EXISTS temp_obs;
CREATE TEMPORARY TABLE temp_obs
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
JOIN all_diagnosis t ON t.obs_group_id = o.obs_group_id
WHERE o.voided = 0;

-- Indexes
CREATE INDEX temp_obs_concept_id ON temp_obs(concept_id);
CREATE INDEX temp_obs_ogi ON temp_obs(obs_group_id);
CREATE INDEX temp_obs_ci1 ON temp_obs(obs_group_id, concept_id);

set @dx_order = concept_from_mapping('PIH', '7537');
set @certainty = concept_from_mapping('PIH', '1379');

DROP TABLE IF EXISTS temp_obs_collated;
CREATE TEMPORARY TABLE temp_obs_collated AS
select obs_group_id,
max(case when concept_id = @dx_order then concept_name(value_coded,@locale) end) "dx_order",
max(case when concept_id = @certainty then concept_name(value_coded,@locale) end) "certainty"
from temp_obs o 
group by obs_group_id;

create index temp_obs_collated_ogi on temp_obs_collated(obs_group_id);

update all_diagnosis d
inner join temp_obs_collated t on t.obs_group_id = d.obs_group_id
set d.dx_order = t.dx_order,
	d.certainty = t.certainty;

-- Diagnosis concept-level info
DROP TEMPORARY TABLE IF EXISTS temp_dx_concept;
CREATE TEMPORARY TABLE temp_dx_concept (
    diagnosis_concept   INT(11),
    icd10_code          VARCHAR(255),
    notifiable          INT(1),
    urgent              INT(1),
    womens_health       INT(1),
    psychological       INT(1),
    pediatric           INT(1),
    outpatient          INT(1),
    ncd                 INT(1),
    non_diagnosis       INT(1),
    ed                  INT(1),
    age_restricted      INT(1),
    oncology            INT(1)
);

INSERT INTO temp_dx_concept(diagnosis_concept)
SELECT DISTINCT diagnosis_concept FROM all_diagnosis;

CREATE INDEX temp_dx_patient_dc ON temp_dx_concept(diagnosis_concept);

UPDATE temp_dx_concept
SET icd10_code = retrieveICD10(diagnosis_concept);

-- Flags
SELECT concept_id INTO @non_diagnoses
FROM concept
WHERE uuid = 'a2d2124b-fc2e-4aa2-ac87-792d4205dd8d';

UPDATE temp_dx_concept SET notifiable = concept_in_set(diagnosis_concept, concept_from_mapping('PIH', '8612'));
UPDATE temp_dx_concept SET womens_health = concept_in_set(diagnosis_concept, concept_from_mapping('PIH', '7957'));
UPDATE temp_dx_concept SET urgent = concept_in_set(diagnosis_concept, concept_from_mapping('PIH', '7679'));
UPDATE temp_dx_concept SET psychological = concept_in_set(diagnosis_concept, concept_from_mapping('PIH', '7942'));
UPDATE temp_dx_concept SET pediatric = concept_in_set(diagnosis_concept, concept_from_mapping('PIH', '7933'));
UPDATE temp_dx_concept SET outpatient = concept_in_set(diagnosis_concept, concept_from_mapping('PIH', '7936'));
UPDATE temp_dx_concept SET ncd = concept_in_set(diagnosis_concept, concept_from_mapping('PIH', '7935'));
UPDATE temp_dx_concept SET non_diagnosis = concept_in_set(diagnosis_concept, @non_diagnoses);
UPDATE temp_dx_concept SET ed = concept_in_set(diagnosis_concept, concept_from_mapping('PIH', '7934'));
UPDATE temp_dx_concept SET age_restricted = concept_in_set(diagnosis_concept, concept_from_mapping('PIH', '7677'));
UPDATE temp_dx_concept SET oncology = concept_in_set(diagnosis_concept, concept_from_mapping('PIH', '8934'));

update all_diagnosis d 
inner join temp_dx_concept t on t.diagnosis_concept = d.diagnosis_concept
set d.icd10_code = t.icd10_code,
d.notifiable = t.notifiable,
d.urgent = t.urgent,
d.womens_health = t.womens_health,
d.psychological = t.psychological,
d.pediatric = t.pediatric,
d.outpatient = t.outpatient,
d.ncd = t.ncd,
d.non_diagnosis = t.non_diagnosis,
d.ed = t.ed,
d.age_restricted = t.age_restricted;

update all_diagnosis d
set diagnosis_entered = concept_name(diagnosis_concept, @locale),
	coded = 1
where d.diagnosis_concept is not null;

update all_diagnosis d
set diagnosis_coded_en = diagnosis_entered
where coded = 1;

update all_diagnosis d
set diagnosis_entered = value_text,
	coded = 0
where d.diagnosis_concept is null;

-- Final output
SELECT
    CONCAT(@partition, "-", d.patient_id) AS patient_id,
    d.patient_primary_id,
    d.loc_registered,
    d.unknown_patient,
    d.gender,
    d.age_at_encounter,
    d.district,
    d.chiefdom,
    CONCAT(@partition, "-", d.encounter_id) AS encounter_id,
    d.encounter_location,
    CONCAT(@partition, "-", d.obs_id) AS obs_id,    
    d.obs_datetime,
    d.entered_by,
    d.provider,
    d.diagnosis_entered,
    d.dx_order,
    d.certainty,
    d.coded,
    d.diagnosis_concept,
    d.diagnosis_coded_en,
    d.icd10_code,
    d.notifiable,
    d.urgent,
    d.womens_health,
    d.psychological,
    d.pediatric,
    d.outpatient,
    d.ncd,
    d.non_diagnosis,
    d.ed,
    d.age_restricted,
    d.oncology,
    d.date_created,
    IF(TIME_TO_SEC(d.date_created) - TIME_TO_SEC(d.obs_datetime) > 1800, 1, 0) AS retrospective,
    CONCAT(@partition, "-", d.visit_id) AS visit_id, 
    d.birthdate,
    d.birthdate_estimated,
    d.encounter_type,
    d.index_asc,
    d.index_desc
FROM all_diagnosis d;
