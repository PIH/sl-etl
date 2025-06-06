create table admission_note_encounter
(
    encounter_id             varchar(100),
    visit_id                 varchar(100),
    patient_id               varchar(100),
    emr_id                   varchar(255),
    encounter_datetime       datetime,
    encounter_location       varchar(255),
    datetime_entered         datetime,
    user_entered             varchar(255),
    admitting_clinician      varchar(255),
    admitted_to              varchar(255),
    admission_date           datetime,
    index_asc                INT,
    index_desc               INT
);
