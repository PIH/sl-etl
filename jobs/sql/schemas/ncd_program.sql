CREATE TABLE ncd_program
(
    patient_id           varchar(50),
    emr_id               varchar(30),
    program_name         varchar(50),
    date_enrolled        date,
    date_completed       date,
    final_program_status varchar(100),
    clinical_status      varchar(50),
    created_by           varchar(50)
);
