SET sql_safe_updates = 0;
SET SESSION group_concat_max_len = 100000;
set @partition = '${partitionNum}';

drop temporary table if exists temp_pregnancy_program;
create temporary table temp_pregnancy_program
(
    patient_program_id                         int,
    patient_id                                 int,
    emr_id                                     varchar(30),
    location_id                                int,
    reg_location                               varchar(255),
    date_enrolled                              date,
    date_completed                             date,
    outcome_concept_id                         int,
    outcome                                    varchar(255),
    current_state_concept_id                   int,
    current_state                              varchar(255),
    pregnancy_status                           varchar(255),
    mother_birthdate                           date,
    age_at_pregnancy_registration              int,
    danger_signs                               varchar(1000),
    high_risk_factors                          varchar(1000),
    latest_lmp                                 date,
    estimated_lmp_from_gest_age                datetime,
    latest_gest_age                            double,
    latest_gest_age_date                       datetime,
    latest_edd                                 date,
    estimated_gestational_age_calculation_date date,
    estimated_gestational_age                  double,
    estimated_delivery_date                    date,
    latest_labor_delivery_summary_encounter_id int,
    actual_delivery_date                       date,
    delivery_location                          varchar(255),
    delivery_num_live_birth                    int,
    delivery_num_fsb                           int,
    delivery_num_msb                           int,
    delivery_outcome                           varchar(255),
    number_of_fetuses                          int,
    hiv_status                                 varchar(255),
    trimester_enrolled                         varchar(255),
    num_previous_anc_visits                    int,
    total_anc_initial                          int,
    total_anc_followup                         int,
    total_anc_visits                           int,
    ferrous_sulfate_folic_acid_ever            boolean,
    iptp_sp_malaria_ever                       boolean,
    nutrition_counseling_ever                  boolean,
    hiv_counsel_and_test_ever                  boolean,
    insecticide_treated_net_ever               boolean,
    index_asc                                  int,
    index_desc                                 int
);

set @now = now();
set @pregnancy_program_id = program('Pregnancy');
set @type_of_tx_workflow_id = (select program_workflow_id from program_workflow where uuid = '9a3f8252-1588-4f7b-b02c-9e99c437d4ef');
set @ancIntake = encounter_type('00e5e810-90ec-11e8-9eb6-529269fb1459');
set @ancFollowup = encounter_type('00e5e946-90ec-11e8-9eb6-529269fb1459');
set @laborDeliverySummary = encounter_type('fec2cc56-e35f-42e1-8ae3-017142c1ca59');

# Set up one row per patient program
call temp_program_patient_create();
call temp_program_patient_populate(@pregnancy_program_id);
call temp_program_patient_create_indexes();

# Link in the pregnancy encounters to pregnancy enrollments based on date
call temp_program_encounter_create();
call temp_program_encounter_populate(@ancIntake);
call temp_program_encounter_populate(@ancFollowup);
call temp_program_encounter_populate(@laborDeliverySummary);
call temp_program_encounter_create_indexes();

# Link in the observations from the pregnancy encounters
call temp_program_obs_create();
call temp_program_obs_populate('en');

# Populate the table with data
insert into temp_pregnancy_program (patient_program_id, patient_id, location_id, date_enrolled, date_completed, outcome_concept_id)
select patient_program_id, patient_id, location_id, date_enrolled, date_completed, outcome_concept_id from temp_program_patient;

update temp_pregnancy_program set emr_id = patient_identifier(patient_id, metadata_uuid('org.openmrs.module.emrapi', 'emr.primaryIdentifierType'));
update temp_pregnancy_program set reg_location = location_name(location_id);
update temp_pregnancy_program set outcome = concept_name(outcome_concept_id, 'en');

update temp_pregnancy_program p set p.current_state_concept_id = (
    select pws.concept_id
    from patient_state ps inner join program_workflow_state pws on ps.state = pws.program_workflow_state_id and pws.program_workflow_id = @type_of_tx_workflow_id
    where ps.patient_program_id = p.patient_program_id
    and ps.voided = 0
    and (ps.end_date is null or ps.end_date = p.date_completed)
    order by ps.start_date desc
    limit 1
);

update temp_pregnancy_program set current_state = concept_name(current_state_concept_id, 'en');
update temp_pregnancy_program set mother_birthdate = birthdate(patient_id);
update temp_pregnancy_program set age_at_pregnancy_registration = TIMESTAMPDIFF(YEAR, mother_birthdate, date_enrolled);

-- Danger signs appear to just be a subset of Diagnoses entered on an ANC followup form.
-- NOTE: It would be better to define these as members of a set in the dictionary.  We will need to review these regularly to ensure this is up-to-date.
set @dangerSignsConcept = concept_from_mapping('PIH', 'DIAGNOSIS');
update temp_pregnancy_program p set p.danger_signs = (
    select  group_concat(o.value_coded_name separator ' | ')
    from    temp_program_obs o
    where   o.patient_program_id = p.patient_program_id
      and     o.concept_id = @dangerSignsConcept
      and     o.value_coded in (
          concept_from_mapping('CIEL', '165193'),
          concept_from_mapping('PIH', '136'),
          concept_from_mapping('CIEL', '150802'),
          concept_from_mapping('CIEL', '140238'),
          concept_from_mapping('CIEL', '139081'),
          concept_from_mapping('CIEL', '113054'),
          concept_from_mapping('CIEL', '118938'),
          concept_from_mapping('CIEL', '122983'),
          concept_from_mapping('CIEL', '142412'),
          concept_from_mapping('CIEL', '118771'),
          concept_from_mapping('CIEL', '122496'),
          concept_from_mapping('CIEL', '151')             ,
          concept_from_mapping('CIEL', '153316'),
          concept_from_mapping('CIEL', '148968'),
          concept_from_mapping('CIEL', '113377')
      )
);

set @highRiskFactorsConcept = concept_from_mapping('CIEL', '160079');
set @otherConcept = concept_from_mapping('PIH', 'OTHER');
update temp_pregnancy_program p set p.high_risk_factors = (
    select group_concat(distinct(if(o.value_coded = @otherConcept, concat('Other: ', o.comments), o.value_coded_name)) separator ' | ')
    from temp_program_obs o
    where o.patient_program_id = p.patient_program_id
      and o.concept_id = @highRiskFactorsConcept
);

update temp_pregnancy_program set latest_lmp = date(temp_program_obs_latest_value_datetime(patient_program_id, 'CIEL', '1427'));
update temp_pregnancy_program set latest_gest_age = temp_program_obs_latest_value_numeric(patient_program_id, 'CIEL', '1438');
update temp_pregnancy_program set latest_gest_age_date = temp_program_obs_latest_obs_datetime(patient_program_id, 'CIEL', '1438');
update temp_pregnancy_program set latest_edd = date(temp_program_obs_latest_value_datetime(patient_program_id, 'CIEL', '5596'));

update temp_pregnancy_program set estimated_delivery_date = latest_edd;
update temp_pregnancy_program set estimated_delivery_date = date_add(latest_gest_age_date, INTERVAL (40 - latest_gest_age) WEEK) where estimated_delivery_date is null and latest_gest_age is not null;
update temp_pregnancy_program set estimated_delivery_date = date_add(latest_lmp, INTERVAL 40 WEEK) where estimated_delivery_date is null and latest_lmp is not null;

update temp_pregnancy_program set latest_labor_delivery_summary_encounter_id = temp_program_encounter_latest_encounter_id(patient_program_id, @laborDeliverySummary);

-- Actual delivery date is the earliest birthdate recorded on the labor and delivery form
update temp_pregnancy_program set actual_delivery_date = (select min(o.value_datetime) from temp_program_obs o where o.encounter_id = latest_labor_delivery_summary_encounter_id and o.concept_id = concept_from_mapping('PIH', '15080'));

update temp_pregnancy_program set estimated_gestational_age_calculation_date = actual_delivery_date;
update temp_pregnancy_program set estimated_gestational_age_calculation_date = date_completed where estimated_gestational_age_calculation_date is null;
update temp_pregnancy_program set estimated_gestational_age_calculation_date = @now where estimated_gestational_age_calculation_date is null;
update temp_pregnancy_program set estimated_gestational_age = (40 - round(datediff(estimated_delivery_date, estimated_gestational_age_calculation_date)/7, 1));

-- Delivery location should be the visit location associated with the labor and delivery summary, otherwise set as 'outborn'
update temp_pregnancy_program p inner join temp_program_encounter e on p.latest_labor_delivery_summary_encounter_id = e.encounter_id set p.delivery_location = location_name(e.visit_location_id);

update temp_pregnancy_program set delivery_num_live_birth = (
    select count(*) from temp_program_obs o where o.encounter_id = latest_labor_delivery_summary_encounter_id
    and o.concept_id = concept_from_mapping('CIEL', '159917') and o.value_coded = concept_from_mapping('CIEL', '151849')
);

update temp_pregnancy_program set delivery_num_fsb = (
    select count(*) from temp_program_obs o where o.encounter_id = latest_labor_delivery_summary_encounter_id
    and o.concept_id = concept_from_mapping('CIEL', '159917') and o.value_coded = concept_from_mapping('CIEL', '159916')
);

update temp_pregnancy_program set delivery_num_msb = (
    select count(*) from temp_program_obs o where o.encounter_id = latest_labor_delivery_summary_encounter_id
    and o.concept_id = concept_from_mapping('CIEL', '159917') and o.value_coded = concept_from_mapping('CIEL', '135436')
);

update temp_pregnancy_program set delivery_outcome = 'Alive' where delivery_num_live_birth > 0 and ifnull(delivery_num_fsb, 0) = 0 and ifnull(delivery_num_msb, 0) = 0;
update temp_pregnancy_program set delivery_outcome = 'Stillbirth' where ifnull(delivery_num_live_birth, 0) = 0 and (ifnull(delivery_num_fsb, 0) > 0 or ifnull(delivery_num_msb, 0) > 0);
update temp_pregnancy_program set delivery_outcome = 'Multiple outcome' where ifnull(delivery_num_live_birth, 0) > 0 and (ifnull(delivery_num_fsb, 0) > 0 or ifnull(delivery_num_msb, 0) > 0);

alter table temp_pregnancy_program add index temp_pregnancy_program_delivery_outcome_idx(delivery_outcome);

-- This is the count of birthdate/time observations
update temp_pregnancy_program set number_of_fetuses = (
    select count(*) from temp_program_obs o where o.encounter_id = latest_labor_delivery_summary_encounter_id
    and o.concept_id = concept_from_mapping('PIH', '15080') and o.value_datetime is not null
);
update temp_pregnancy_program set number_of_fetuses = 1 where number_of_fetuses = 0;

update temp_pregnancy_program p set p.hiv_status = (
    select distinct concept_name(o.value_coded, 'en')
    from obs o
    where o.person_id = p.patient_id
      and o.voided = 0
      and o.concept_id in (concept_from_mapping('CIEL', '163722'), concept_from_mapping('CIEL', '159427'))
      and (p.date_completed is null or p.date_completed > date(o.obs_datetime))
      order by o.obs_datetime desc, o.obs_id desc limit 1
);
update temp_pregnancy_program set hiv_status = 'Unknown' where hiv_status is null;

update temp_pregnancy_program set trimester_enrolled = temp_program_obs_latest_value_coded_name(patient_program_id, 'PIH', '11661');

update temp_pregnancy_program set num_previous_anc_visits = temp_program_obs_latest_value_numeric(patient_program_id, 'CIEL', '1590');
update temp_pregnancy_program set num_previous_anc_visits = 0 where num_previous_anc_visits is null;
update temp_pregnancy_program set num_previous_anc_visits = (num_previous_anc_visits - 1) where num_previous_anc_visits > 0;

update temp_pregnancy_program set total_anc_initial = temp_program_encounter_count(patient_program_id, @ancIntake);
update temp_pregnancy_program set total_anc_followup = temp_program_encounter_count(patient_program_id, @ancFollowup);
update temp_pregnancy_program set total_anc_visits = num_previous_anc_visits + total_anc_initial + total_anc_followup;

update temp_pregnancy_program set ferrous_sulfate_folic_acid_ever = ifnull(temp_program_obs_num_with_value_coded(patient_program_id, null, 'CIEL', '164166', 'CIEL', '1065'), 0) > 0;
update temp_pregnancy_program set iptp_sp_malaria_ever = ifnull(temp_program_obs_num_with_value_coded(patient_program_id, null, 'CIEL', '1591', 'CIEL', '1065'), 0) > 0;
update temp_pregnancy_program set nutrition_counseling_ever = ifnull(temp_program_obs_num_with_value_coded(patient_program_id, null, 'CIEL', '1380', 'CIEL', '1065'), 0) > 0;
update temp_pregnancy_program set hiv_counsel_and_test_ever = ifnull(temp_program_obs_num_with_value_coded(patient_program_id, null, 'CIEL', '164401', 'CIEL', '1065'), 0) > 0;
update temp_pregnancy_program set insecticide_treated_net_ever = ifnull(temp_program_obs_num_with_value_coded(patient_program_id, null, 'CIEL', '159855', 'CIEL', '1065'), 0) > 0;

update temp_pregnancy_program set pregnancy_status = 'Prenatal' where actual_delivery_date is null and estimated_gestational_age <= 45 and outcome_concept_id is null and current_state_concept_id != concept_from_mapping('CIEL', '1180');
update temp_pregnancy_program set pregnancy_status = 'Postnatal, delivered' where delivery_outcome in ('Alive', 'Stillbirth', 'Multiple outcome');
update temp_pregnancy_program set pregnancy_status = 'Postnatal, miscarriage' where outcome_concept_id = concept_from_mapping('PIH', '1852');
update temp_pregnancy_program set pregnancy_status = 'Presumed postnatal' where pregnancy_status is null;

update temp_pregnancy_program set delivery_location = 'outborn' where delivery_location is null and pregnancy_status != 'Prenatal';

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
       if(estimated_gestational_age > 45, '>45', concat('', estimated_gestational_age)),
       estimated_delivery_date,
       actual_delivery_date,
       delivery_location,
       delivery_outcome,
       number_of_fetuses,
       hiv_status,
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