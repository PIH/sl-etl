CREATE TABLE ncd_program
(
    ncd_program_id       varchar(50),
    patient_id           varchar(50),
    emr_id               varchar(30),
    program_name         varchar(50),
    date_enrolled        date,
    date_completed       date,
    final_program_status varchar(100),
    clinical_status      varchar(50),
    user_entered         varchar(50),
    index_asc            int,
    index_desc           int
);
