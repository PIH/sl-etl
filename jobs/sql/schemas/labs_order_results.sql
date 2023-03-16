CREATE TABLE labs_order_results
(
  wellbody_emr_id    VARCHAR(255),
  kgh_emr_id        VARCHAR(255),
  loc_registered VARCHAR(255),
  encounter_location VARCHAR(255),
  unknown_patient VARCHAR(50),
  gender VARCHAR(50),
  age_at_enc INT,
  department VARCHAR(255),
  commune VARCHAR(255),
  section VARCHAR(255),
  locality VARCHAR(255),
  street_landmark VARCHAR(255),
  order_number VARCHAR(50) ,
  orderable VARCHAR(255),
  test VARCHAR(255),
  lab_id VARCHAR(255),	
  LOINC VARCHAR(255),	
  specimen_collection_date DATETIME,
  results_date DATETIME,
  results_entry_date DATETIME,
  result VARCHAR(255),
  units VARCHAR(255),
  reason_not_performed TEXT
);
 