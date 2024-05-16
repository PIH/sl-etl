create table maternal_discharge_encounter
(
emr_id              varchar(255),
encounter_id        int,
visit_id            int,
encounter_datetime datetime,
datetime_created datetime,
user_entered     varchar(255),
provider             varchar(255),
next_appointment_date  date,
disposition          varchar(255),
transfer_location    varchar(255),
followup_clinic      varchar(255),
index_asc int,
index_desc  int
);