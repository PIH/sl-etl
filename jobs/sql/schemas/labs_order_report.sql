CREATE TABLE labs_order_report
(
    patient_id              VARCHAR(100),
    wellbody_emr_id          VARCHAR(255),
    kgh_emr_id          VARCHAR(255),
    loc_registered  VARCHAR(255),
    unknown_patient CHAR(1),
    gender          CHAR(1),
    age_at_enc      INT,
    patient_address VARCHAR(1000),
    order_number    VARCHAR(255),
    accession_number VARCHAR(255),
    orderable       VARCHAR(255),
    status          VARCHAR(255),
    orderer         VARCHAR(255),
    orderer_provider_type VARCHAR(255),
    order_datetime  DATETIME,
    ordering_location VARCHAR(255),
    urgency         VARCHAR(255),
    specimen_collection_datetime DATETIME,
    collection_date_estimated VARCHAR(255),
    test_location  VARCHAR(255),
    result_date     DATETIME
);