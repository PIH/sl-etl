create table all_programs
(
  patient_program_id    varchar(50),
  patient_id            varchar(50),
  wellbody_emr_id       varchar(50),
  kgh_emr_id            varchar(50),
  emr_id                varchar(50),
  program_name          varchar(50),
  date_enrolled         date,
  date_completed        date,
  program_outcome       varchar(255),
  user_entered          varchar(50),
  index_asc             int,
  index_desc            int  
);
