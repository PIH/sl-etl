create table delivery_summary_encounter
(
mother_emr_id              varchar(255),
encounter_id        int,
visit_id            int,
encounter_datetime datetime,
encounter_location varchar(255),
datetime_created datetime,
user_entered     varchar(255),
provider             varchar(255),
birthdate        datetime,
outcome          varchar(255),
sex              varchar(10),
birth_weight     decimal(3,2),
birth_length     int,
birth_head_circumference  int,
apgar_1_min       int,
apgar_5_min       int,
apgar_10_min      int,
fetal_presentation   varchar(255),
delivery_method varchar(255),
index_asc int,
index_desc int
);