create table all_appointments
(
    appointment_id       varchar(25),
    patient_id           varchar(25),
    emr_id               varchar(50),
    date_issued          date,
    location             varchar(255),
    service              varchar(50),
    type                 varchar(45),
    recurring            bit,
    appointment_datetime datetime,
    duration             int,
    provider             varchar(255),
    status               varchar(45),
    note                 varchar(255),
    datetime_entered     datetime,
    user_entered         varchar(255),
    index_asc            int,
    index_desc           int
);
