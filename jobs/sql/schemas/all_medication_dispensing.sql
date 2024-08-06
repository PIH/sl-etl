CREATE TABLE all_medication_dispensing
(
    encounter_id       varchar(100),
    visit_id           varchar(100),
    patient_id         varchar(100),
    emr_id              varchar(50),
    form                varchar(10),
    encounter_datetime  datetime,
    encounter_location  varchar(100),
    creator             varchar(30),
    encounter_provider  varchar(30),
    drug_name           varchar(500),
    drug_openboxes_code int,
    duration            int,
    duration_unit       varchar(20),
    quantity_per_dose   float,
    dose_unit           varchar(50),
    frequency           varchar(50),
    quantity_dispensed  int,
    quantity_unit       varchar(30),
    order_id            int,
    dispensing_status   varchar(50),
    status_reason       varchar(50),
    instructions        text
)
;
