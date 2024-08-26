SET sql_safe_updates = 0;
SET SESSION group_concat_max_len = 100000;
set @partition = '${partitionNum}';

drop temporary table if exists temp_pregnancy_program;
create temporary table temp_pregnancy_program
(
    patient_program_id              int,
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
    latest_lmp                      date,
    latest_lmp_date                 datetime,
    latest_gest_age                 double,
    latest_gest_age_date            datetime,
    latest_edd                      date,
    latest_edd_date                 datetime,
    last_menstruation_date          date,
    estimated_gestational_age_date  date,
    estimated_gestational_age       double,
    estimated_delivery_date         date,
    actual_delivery_date            date,
    delivery_location               varchar(255),
    delivery_num_live_birth         int,
    delivery_num_fsb                int,
    delivery_num_msb                int,
    delivery_outcome                varchar(255),
    number_of_fetuses               int,
    hiv_status                      varchar(255),
    itn_status                      boolean,
    trimester_enrolled              varchar(255),
    total_anc_initial               int,
    total_anc_followup              int,
    total_anc_visits                int,
    ferrous_sulfate_folic_acid_ever boolean,
    iptp_sp_malaria_ever            boolean,
    nutrition_counseling_ever       boolean,
    hiv_counsel_and_test_ever       boolean,
    insecticide_treated_net_ever    boolean,
    index_asc                       int,
    index_desc                      int
);

set @now = now();
set @pregnancy_program_id = program('Pregnancy');
set @type_of_tx_workflow_id = (select program_workflow_id from program_workflow where uuid = '9a3f8252-1588-4f7b-b02c-9e99c437d4ef');
set @ancIntake = encounter_type('00e5e810-90ec-11e8-9eb6-529269fb1459');
set @ancFollowup = encounter_type('00e5e946-90ec-11e8-9eb6-529269fb1459');
set @laborDeliverySummary = encounter_type('fec2cc56-e35f-42e1-8ae3-017142c1ca59');

# Set up one row per patient program
call create_temp_patient_program();
call populate_temp_patient_program(@pregnancy_program_id);
call create_temp_patient_program_indexes();

# Link in the pregnancy encounters to pregnancy enrollments based on date
call create_temp_encounter();
call populate_temp_encounter(@ancIntake);
call populate_temp_encounter(@ancFollowup);
call populate_temp_encounter(@laborDeliverySummary);
call create_temp_encounter_indexes();
call link_temp_encounter_to_temp_patient_program();

# Link in the observations from the pregnancy encounters
call create_temp_obs();
call populate_temp_obs('en');

# Populate the table with data
insert into temp_pregnancy_program (patient_program_id, patient_id, location_id, date_enrolled, date_completed, outcome_concept_id)
select patient_program_id, patient_id, location_id, date_enrolled, date_completed, outcome_concept_id from temp_patient_program;

update temp_pregnancy_program set emr_id = patient_identifier(patient_id, metadata_uuid('org.openmrs.module.emrapi', 'emr.primaryIdentifierType'));
update temp_pregnancy_program set reg_location = location_name(location_id);
update temp_pregnancy_program set outcome = concept_name(outcome_concept_id, 'en');
update temp_pregnancy_program set current_state = currentProgramState(patient_program_id, @type_of_tx_workflow_id, 'en');
update temp_pregnancy_program set mother_birthdate = birthdate(patient_id);
update temp_pregnancy_program set age_at_pregnancy_registration = TIMESTAMPDIFF(YEAR, mother_birthdate, date_enrolled);

-- We appear to be storing danger signs as the diagnoses that are netered on the anc followup form.  TODO: Check on this
set @dangerSignsConcept = concept_from_mapping('PIH', 'DIAGNOSIS');
update temp_pregnancy_program p set p.danger_signs = (
    select  group_concat(o.value_coded_name separator ' | ')
    from    temp_obs o
    where   o.patient_program_id = p.patient_program_id
    and     o.concept_id = @dangerSignsConcept and o.encounter_type_id = @ancFollowup
);

set @highRiskFactorsConcept = concept_from_mapping('CIEL', '160079');
set @otherConcept = concept_from_mapping('PIH', 'OTHER');
update temp_pregnancy_program p set p.high_risk_factors = (
    select group_concat(distinct(if(o.value_coded = @otherConcept, concat('Other: ', o.comments), o.value_coded_name)) separator ' | ')
    from temp_obs o
    where o.patient_program_id = p.patient_program_id
      and o.concept_id = @highRiskFactorsConcept
);

update temp_pregnancy_program set latest_lmp = date(latest_program_obs_value_datetime(patient_program_id, 'CIEL', '1427'));
update temp_pregnancy_program set latest_lmp = latest_program_obs_datetime(patient_program_id, 'CIEL', '1427');
update temp_pregnancy_program set latest_gest_age = date(latest_program_obs_value_datetime(patient_program_id, 'CIEL', '1438'));
update temp_pregnancy_program set latest_gest_age_date = latest_program_obs_datetime(patient_program_id, 'CIEL', '1438');
update temp_pregnancy_program set latest_edd = date(latest_program_obs_value_datetime(patient_program_id, 'CIEL', '5596'));
update temp_pregnancy_program set latest_edd_date = latest_program_obs_datetime(patient_program_id, 'CIEL', '5596');

update temp_pregnancy_program set estimated_delivery_date = latest_edd_date;
update temp_pregnancy_program set estimated_delivery_date = latest_gest_age + (datediff(@now, latest_gest_age_date)/7) where estimated_delivery_date is null and latest_gest_age is not null;
update temp_pregnancy_program set estimated_delivery_date = date_add(latest_lmp, INTERVAL 40 WEEK) where estimated_delivery_date is null and latest_lmp is not null;

update temp_pregnancy_program set last_menstruation_date = date_sub(estimated_delivery_date, INTERVAL 40 WEEK) where estimated_delivery_date is not null;

-- TODO: Should this instead be this obs from the labor delivery summary form? <obs id="labourStartDateTime" conceptId="CIEL:163444" showTime="true" allowFutureTimes="true"/> ?
update temp_pregnancy_program set actual_delivery_date = latest_program_encounter_datetime(patient_program_id, @laborDeliverySummary);
update temp_pregnancy_program set estimated_gestational_age_date = actual_delivery_date;
-- TODO: Need to update estimated_gestational_age_date with other possible outcomes, gave birth, miscarriage, abortion, or patient died
update temp_pregnancy_program set estimated_gestational_age_date = @now where estimated_gestational_age_date is null;
update temp_pregnancy_program set estimated_gestational_age = datediff(estimated_gestational_age_date, estimated_delivery_date)/7;

update temp_pregnancy_program set delivery_location = location_name(latest_program_encounter_location(patient_program_id, @laborDeliverySummary));
-- TODO: If patient did not deliver at the facility but a Newborn Admission form was completed with a value in the "delivery location" field, use that value. Otherwise if delivery was recorded not no specific location recorded, mark as "outborn"

update temp_pregnancy_program set delivery_num_live_birth = num_program_obs_with_value_coded(patient_program_id, @laborDeliverySummary, 'CIEL', '159917', 'CIEL', '151849');
update temp_pregnancy_program set delivery_num_fsb = num_program_obs_with_value_coded(patient_program_id, @laborDeliverySummary, 'CIEL', '159917', 'CIEL', '159916');
update temp_pregnancy_program set delivery_num_msb = num_program_obs_with_value_coded(patient_program_id, @laborDeliverySummary, 'CIEL', '159917', 'CIEL', '135436');
update temp_pregnancy_program set delivery_outcome = 'Alive' where delivery_num_live_birth > 0 and ifnull(delivery_num_fsb, 0) = 0 and ifnull(delivery_num_msb, 0) = 0;
update temp_pregnancy_program set delivery_outcome = 'Stillbirth' where ifnull(delivery_num_live_birth, 0) = 0 and (ifnull(delivery_num_fsb, 0) > 0 or ifnull(delivery_num_msb, 0) > 0);
update temp_pregnancy_program set delivery_outcome = 'Multiple outcome' where ifnull(delivery_num_live_birth, 0) > 0 and (ifnull(delivery_num_fsb, 0) > 0 or ifnull(delivery_num_msb, 0) > 0);

alter table temp_pregnancy_program add index temp_pregnancy_program_delivery_outcome_idx(delivery_outcome);

-- TODO: Requirements indicate this should come from ANC forms, but I do not see it there.
update temp_pregnancy_program set number_of_fetuses = ifnull(delivery_num_live_birth, 0) + ifnull(delivery_num_fsb, 0) + ifnull(delivery_num_msb, 0);

-- TODO: HIV is listed under "High risk factors" too.  Should we also use this?  Other places?
-- Also, why do we have multiple HIV Test result concepts, and which are used where?  Do we look at all of them?
update temp_pregnancy_program set hiv_status = 'Unknown';
update temp_pregnancy_program p set p.hiv_status = (
    select distinct o.value_coded from obs o
    where o.person_id = p.patient_id
      and o.voided = 0
      and o.concept_id in (concept_from_mapping('CIEL', '163722'), concept_from_mapping('CIEL', '159427'))
      and o.value_coded = concept_from_mapping('CIEL', '703')
      and (p.date_completed is null or p.date_completed > date(o.obs_datetime))
);

-- TODO: itn_status, I don't see this on the form or I don't know how it differs from the itn question lower down
update temp_pregnancy_program set trimester_enrolled = latest_program_obs_value_coded(patient_program_id, 'PIH', '11661');

update temp_pregnancy_program set total_anc_initial = num_program_encounters(patient_program_id, @ancIntake);
update temp_pregnancy_program set total_anc_followup = num_program_encounters(patient_program_id, @ancFollowup);
update temp_pregnancy_program set total_anc_visits = total_anc_initial + total_anc_followup;

update temp_pregnancy_program set ferrous_sulfate_folic_acid_ever = ifnull(num_program_obs_with_value_coded(patient_program_id, null, 'CIEL', '164166', 'CIEL', '1065'), 0) > 0;
update temp_pregnancy_program set iptp_sp_malaria_ever = ifnull(num_program_obs_with_value_coded(patient_program_id, null, 'CIEL', '1591', 'CIEL', '1065'), 0) > 0;
update temp_pregnancy_program set nutrition_counseling_ever = ifnull(num_program_obs_with_value_coded(patient_program_id, null, 'CIEL', '1380', 'CIEL', '1065'), 0) > 0;
update temp_pregnancy_program set hiv_counsel_and_test_ever = ifnull(num_program_obs_with_value_coded(patient_program_id, null, 'CIEL', '164401', 'CIEL', '1065'), 0) > 0;
update temp_pregnancy_program set insecticide_treated_net_ever = ifnull(num_program_obs_with_value_coded(patient_program_id, null, 'CIEL', '159855', 'CIEL', '1065'), 0) > 0;

-- TODO: These statuses don't totally work for multiple births.
update temp_pregnancy_program set pregnancy_status = 'Prenatal' where actual_delivery_date is null and estimated_gestational_age <= 45;
update temp_pregnancy_program set pregnancy_status = 'Postnatal, delivered' where delivery_outcome = 'Alive';
update temp_pregnancy_program set pregnancy_status = 'Postnatal, miscarriage' where delivery_outcome in ('Stillbirth', 'Multiple outcome');
update temp_pregnancy_program set pregnancy_status = 'Presumed postnatal' where pregnancy_status is null;

select concat(@partition,'-',patient_program_id) as pregnancy_program_id,
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
       if(estimated_gestational_age > 45, '>45', concat('', estimated_gestational_age)),
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