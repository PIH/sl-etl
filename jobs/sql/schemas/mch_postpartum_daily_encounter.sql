create table mch_postpartum_daily_encounter
(
    encounter_id                  varchar(100),
    visit_id                      varchar(100),
    patient_id                    varchar(100),
    emr_id                        varchar(255),
    encounter_datetime            datetime,
    encounter_location            varchar(255),
    datetime_entered              datetime,
    user_entered                  varchar(255),
    provider                      varchar(255),
    temperature                   decimal(8, 3),
    heart_rate                    int,
    bp_systolic                   int,
    bp_diastolic                  int,
    respiratory_rate              int,
    o2_saturation                 int,
    days_since_delivery           int,
    lochia_color                  varchar(255),
    lochia_odor                   varchar(255),
    lochia_quantity               varchar(255),
    postpartum_hemorrhage         bit,
    number_pads_used              int,
    pads_used_unit                varchar(255),
    involution_of_uterus          varchar(255),
    palpation_of_uterus           varchar(255),
    cesarean_wound                varchar(255),
    intact_perineum               varchar(255),
    perineum_wound_infection      varchar(255),
    breast_observations           varchar(255),
    mood                          varchar(255),
    bowels                        varchar(255),
    urination                     varchar(255),
    leg_pain                      varchar(255),
    pain_level                    int,
    family_planning_counselling   varchar(255),
    family_planning_accepted      varchar(255),
    family_planning_method        varchar(255),
    placement_date                datetime,
    disposition                   varchar(255),
    index_asc                     INT,
    index_desc                    INT
);
