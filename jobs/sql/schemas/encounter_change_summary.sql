create table encounter_change_summary
(
change_date            date,
encounter_type         varchar(255),
provider_type          varchar(255),
change_lag_group       varchar(30),
change_lag_group_order int,
encounter_location     varchar(255),
mcoe_location          int,
patient_died           int,
encounters_changed     int,
encounters_deleted     int,
answers_changed        int,
answers_removed        int,
answers_added_later    int,
diagnoses_changed      int,
details_changed        int,
total_changes          int,
distinct_users         int
);
