CREATE TABLE ncd_diagnoses
(
    obs_id                 VARCHAR(50),
    patient_id             VARCHAR(50),
    emr_id                 VARCHAR(50),
    ncd_program_id         VARCHAR(50),
    encounter_id           VARCHAR(50),
    encounter_datetime     DATETIME,
    encounter_location     VARCHAR(255),
    datetime_entered       DATETIME,
    user_entered           VARCHAR(255),
    provider               VARCHAR(255),
    encounter_type         VARCHAR(255),
    diagnosis_entered      VARCHAR(255),
    dx_order               VARCHAR(255),
    certainty              VARCHAR(255),
    coded                  BIT,
    index_asc              INT,
    index_desc             INT
);
