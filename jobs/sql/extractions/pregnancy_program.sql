SET sql_safe_updates = 0;
SET SESSION group_concat_max_len = 100000;

drop temporary table if exists temp_pregnancy_program;
create temporary table temp_pregnancy_program
(
    pregnancy_program_id            int,
    patient_id                      int,
    emr_id                          varchar(30),
    location_id                     int,
    reg_location                    varchar(255),
    date_enrolled                   date,
    date_completed                  date,
    outcome_concept_id              int,
    outcome                         varchar(255),
    current_state                   varchar(255),
    pregnancy_status                varchar(255),
    mother_birthdate                date,
    age_at_pregnancy_registration   int,
    danger_signs                    varchar(1000),
    high_risk_factors               varchar(1000),
    last_menstruation_date          datetime,
    estimated_gestational_age       varchar(10),
    estimated_delivery_date         date,
    actual_delivery_date            date,
    delivery_location               varchar(255),
    delivery_outcome                varchar(255),
    number_of_fetuses               int,
    hiv_status                      varchar(255),
    itn_status                      bit,
    trimester_enrolled              varchar(255),
    total_anc_visits                int,
    ferrous_sulfate_folic_acid_ever bit,
    iptp_sp_malaria_ever            bit,
    nutrition_counseling_ever       bit,
    hiv_counsel_and_test_ever       bit,
    insecticide_treated_net_ever    bit,
    index_asc                       int,
    index_desc                      int
);

set @pregnancy_program_id = program('Pregnancy');
set @type_of_tx_workflow_id = (select program_workflow_id from program_workflow where uuid = '9a3f8252-1588-4f7b-b02c-9e99c437d4ef');
set @ancIntake = encounter_type('00e5e810-90ec-11e8-9eb6-529269fb1459');
set @ancFollowup = encounter_type('00e5e946-90ec-11e8-9eb6-529269fb1459');
set @laborDeliverySummary = encounter_type('fec2cc56-e35f-42e1-8ae3-017142c1ca59');
set @newbornAssessment = encounter_type('6444b8d4-407d-444d-aa15-d6dff204ed83');

# Set up one row per patient program

insert into temp_pregnancy_program (pregnancy_program_id, patient_id, location_id, date_enrolled, date_completed, outcome_concept_id)
select pp.patient_program_id, pp.patient_id, pp.location_id, date(pp.date_enrolled), date(pp.date_completed), pp.outcome_concept_id
from patient_program pp
where pp.program_id = @pregnancy_program_id
and pp.voided = 0;

create index temp_pregnancy_program_pp_id_idx on temp_pregnancy_program(pregnancy_program_id);
create index temp_pregnancy_program_patient_id_idx on temp_pregnancy_program(patient_id);

update temp_pregnancy_program set emr_id = patient_identifier(patient_id, metadata_uuid('org.openmrs.module.emrapi', 'emr.primaryIdentifierType'));
update temp_pregnancy_program set reg_location = location_name(location_id);
update temp_pregnancy_program set outcome = concept_name(outcome_concept_id, 'en');
update temp_pregnancy_program set current_state = currentProgramState(pregnancy_program_id, @type_of_tx_workflow_id, 'en');
update temp_pregnancy_program set mother_birthdate = birthdate(patient_id);
update temp_pregnancy_program set age_at_pregnancy_registration = TIMESTAMPDIFF(YEAR, mother_birthdate, date_enrolled);

# Set up encounter table that links pregnancy encounters with pregnancy enrollments based on date

drop temporary table if exists temp_encounter;
create temporary table temp_encounter
(
    pregnancy_program_id int,
    patient_id           int,
    encounter_id         int,
    encounter_type_id    int,
    encounter_datetime   datetime
);
insert into temp_encounter (patient_id, encounter_id, encounter_type_id, encounter_datetime)
select patient_id, encounter_id, encounter_type, encounter_datetime
from encounter
where encounter_type in (@ancIntake, @ancFollowup, @laborDeliverySummary, @newbornAssessment)
and voided = 0;

create index temp_encounter_patient_id_idx on temp_encounter(patient_id);

update temp_encounter e
inner join temp_pregnancy_program p on e.patient_id = p.patient_id
set e.pregnancy_program_id = p.pregnancy_program_id
where e.encounter_datetime >= p.date_enrolled
and (p.date_completed is null or date(e.encounter_datetime) <= p.date_completed);

create index temp_encounter_pp_id_idx on temp_encounter(pregnancy_program_id);

# Set up obs table that links pregnancy obs with pregnancy enrollments based on date

drop temporary table if exists temp_obs;
create temporary table temp_obs
(
    pregnancy_program_id int,
    patient_id           int,
    encounter_id         int,
    encounter_datetime   datetime,
    encounter_type_id    int,
    concept_id           int,
    value_coded          varchar(255)
);

insert into temp_obs (pregnancy_program_id, patient_id, encounter_id, encounter_datetime, encounter_type_id, concept_id, value_coded)
SELECT e.pregnancy_program_id,
       e.patient_id,
       e.encounter_id,
       e.encounter_datetime,
       e.encounter_type_id,
       o.concept_id,
       concept_name(o.value_coded, 'en')
from temp_encounter e
inner join obs o on o.encounter_id = e.encounter_id
where o.voided = 0;

create index temp_obs_pp_id_idx on temp_obs(pregnancy_program_id);

update temp_pregnancy_program p set p.danger_signs = (
    select group_concat(distinct(o.value_coded) separator ' | ') from temp_obs o where o.pregnancy_program_id = p.pregnancy_program_id
    and o.concept_id = concept_from_mapping('PIH', 'DIAGNOSIS') and o.encounter_type_id = @ancFollowup
);

update temp_pregnancy_program p set p.high_risk_factors = (
    select group_concat(distinct(o.value_coded) separator ' | ') from temp_obs o where o.pregnancy_program_id = p.pregnancy_program_id
    and o.concept_id = concept_from_mapping('CIEL', '160079')
);

-- TODO:  For high_risk_factors... If "other" is selected, this should appear as "Other: XXXXX" where XXXXX is any value entered in the open text box

/*
    last_menstruation_date          datetime,
    estimated_gestational_age       varchar(10),
    estimated_delivery_date         date,
    actual_delivery_date            date,
    delivery_location               varchar(255),
    delivery_outcome                varchar(255),
    number_of_fetuses               int,
    hiv_status                      varchar(255),
    itn_status                      bit,
    trimester_enrolled              varchar(255),
    total_anc_visits                int,
    ferrous_sulfate_folic_acid_ever bit,
    iptp_sp_malaria_ever            bit,
    nutrition_counseling_ever       bit,
    hiv_counsel_and_test_ever       bit,
    insecticide_treated_net_ever    bit,
    index_asc                       int,
    index_desc                      int


 update temp_pregnancy_program set pregnancy_status = ;
 Options include:
- Prenatal (patient is currently pregnant, and due date has not passed, and there is no other outcome recorded for pregnancy program enrollment, and the gestational age is <45 weeks)
- Postnatal, delivered (there is a record of the patient giving birth, regardless of birth outcome)
- Postnatal, miscarriage (the patient had a miscarriage - can come from the pregnancy program outcome field)
- Presumed postnatal (gestational age is >=45 weeks or there is no record of the outcome - basically, this is lost-to-follow-up)
 */



select concat(@partition,'-',pregnancy_program_id) as pregnancy_program_id,
       concat(@partition,'-',patient_id) as patient_id,
       emr_id,
       reg_location,
       date_enrolled,
       date_completed,
       outcome,
       current_state,
       pregnancy_status,
       age_at_pregnancy_registration,
       danger_signs,
       high_risk_factors,
       last_menstruation_date,
       estimated_gestational_age,
       estimated_delivery_date,
       actual_delivery_date,
       delivery_location,
       delivery_outcome,
       number_of_fetuses,
       hiv_status,
       itn_status,
       trimester_enrolled,
       total_anc_visits,
       ferrous_sulfate_folic_acid_ever,
       iptp_sp_malaria_ever,
       nutrition_counseling_ever,
       hiv_counsel_and_test_ever,
       insecticide_treated_net_ever,
       index_asc,
       index_desc
from temp_pregnancy_program;