create table all_programs
(
  patient_id            varchar(100),
  wellbody_emr_id       varchar(50),
  kgh_emr_id            varchar(50),
  emr_id                varchar(50),
  program_name          varchar(50),
  date_enrolled         date,
  date_completed        date,
  final_program_status  varchar(100),
  user_entered          varchar(50)
  index_asc             int,
  index_desc            int  
);
