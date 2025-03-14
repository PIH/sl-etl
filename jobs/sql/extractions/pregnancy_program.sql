SET sql_safe_updates = 0;
SET SESSION group_concat_max_len = 100000;
set @partition = '${partitionNum}';

select program_workflow_state_id into @postpartum_state from program_workflow_state where uuid = 'a735b5f6-0b63-4d9a-ae2e-70d08c947aed';
select program_workflow_state_id into @anc_state from program_workflow_state where uuid = 'a83896bf-9094-4a3c-b843-e75509a52b32';
set @weightConceptId = concept_from_mapping('PIH','5089');
set @art_set = concept_from_mapping('PIH','1085');
set @antimalarial_set = concept_from_mapping('PIH','20673');
set @ferrous_sulfate_folic_acid = concept_from_mapping('PIH','773');
set @ferrous_sulfate = concept_from_mapping('PIH','256');


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
    latest_labor_delivery_summary_datetime     datetime,
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
    anc_count_end_datetime                     datetime,
    total_anc_initial                          int,
    total_anc_followup                         int,
    total_anc_visits                           int,
    post_partum_state_date                     date,
    anc_state_date                             date,
    iptp_sp_malaria_ever                       boolean,
    nutrition_counseling_ever                  boolean,
    hiv_counsel_and_test_ever                  boolean,
    insecticide_treated_net_ever               boolean,
    iron_ifa_ever                              boolean,
    syphilis_test_ever                         boolean,  
    arv_for_pmtct                              boolean,
    latest_anc_intake_encounter_id             int(11),
    anc_intake_visit_id                        int(11),
    muac_measured                              boolean, 
    anc_visit1_weight_recorded                 boolean,
    malaria_treatment_during_antenatal         boolean, 
    index_asc                                  int,
    index_desc                                 int
);

set @now = now();
set @pregnancy_program_id = program('Pregnancy');
set @type_of_tx_workflow_id = (select program_workflow_id from program_workflow where uuid = '9a3f8252-1588-4f7b-b02c-9e99c437d4ef');
set @ancIntake = encounter_type('00e5e810-90ec-11e8-9eb6-529269fb1459');
set @ancFollowup = encounter_type('00e5e946-90ec-11e8-9eb6-529269fb1459');
set @laborDeliverySummary = encounter_type('fec2cc56-e35f-42e1-8ae3-017142c1ca59');
set @vitals = encounter_type('4fb47712-34a6-40d2-8ed3-e153abbd25b7');
set @labResults = encounter_type('4d77916a-0620-11e5-a6c0-1697f925ec7b');
set @specimenCollection= encounter_type('39C09928-0CAB-4DBA-8E48-39C631FA4286');

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
update temp_pregnancy_program set latest_gest_age_date = temp_program_obs_latest_obs_datetime(patient_program_id, 'CIEL', '1438', null, null);
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

update temp_pregnancy_program t
inner join encounter e on e.encounter_id  = latest_labor_delivery_summary_encounter_id
set  latest_labor_delivery_summary_datetime  = e.encounter_datetime;

update temp_pregnancy_program set num_previous_anc_visits = temp_program_obs_latest_value_numeric(patient_program_id, 'CIEL', '1590');
update temp_pregnancy_program set num_previous_anc_visits = 0 where num_previous_anc_visits is null;
update temp_pregnancy_program set num_previous_anc_visits = (num_previous_anc_visits - 1) where num_previous_anc_visits > 0;

update temp_pregnancy_program set post_partum_state_date = temp_program_earliest_patient_state_date(patient_program_id, @postpartum_state);
update temp_pregnancy_program set anc_count_end_datetime = LEAST(post_partum_state_date, latest_labor_delivery_summary_datetime);

update temp_pregnancy_program set total_anc_initial = temp_program_encounter_count(patient_program_id, @ancIntake, anc_count_end_datetime);
update temp_pregnancy_program set total_anc_followup = temp_program_encounter_count(patient_program_id, @ancFollowup, anc_count_end_datetime);
update temp_pregnancy_program set total_anc_visits = num_previous_anc_visits + total_anc_initial + total_anc_followup;

update temp_pregnancy_program set iptp_sp_malaria_ever = if(temp_program_obs_num_with_value_coded(patient_program_id, null, 'CIEL', '1591', 'CIEL', '1065') = 0, null, 1);
update temp_pregnancy_program t set iptp_sp_malaria_ever = 0 where total_anc_visits >= 1 and iptp_sp_malaria_ever is null;

update temp_pregnancy_program set nutrition_counseling_ever = if(temp_program_obs_num_with_value_coded(patient_program_id, null, 'CIEL', '1380', 'CIEL', '1065')= 0, null,1);
update temp_pregnancy_program t set nutrition_counseling_ever = 0 where total_anc_visits >= 1 and nutrition_counseling_ever is null;

update temp_pregnancy_program set hiv_counsel_and_test_ever = if(temp_program_obs_num_with_value_coded(patient_program_id, null, 'CIEL', '164401', 'CIEL', '1065') = 0, null, 1);
update temp_pregnancy_program t set hiv_counsel_and_test_ever = 0 where total_anc_visits >= 1 and hiv_counsel_and_test_ever is null;

update temp_pregnancy_program set insecticide_treated_net_ever = if(temp_program_obs_num_with_value_coded(patient_program_id, null, 'CIEL', '159855', 'CIEL', '1065') = 0, null, 1);
update temp_pregnancy_program t set insecticide_treated_net_ever = 0 where total_anc_visits >= 1 and insecticide_treated_net_ever is null;

update temp_pregnancy_program set anc_state_date = temp_program_earliest_patient_state_date(patient_program_id, @anc_state);

update temp_pregnancy_program set latest_gest_age_date = temp_program_obs_latest_obs_datetime(patient_program_id, 'CIEL', '1438', null, null);

update temp_pregnancy_program set latest_anc_intake_encounter_id = temp_program_encounter_latest_encounter_id(patient_program_id, @ancIntake);

update temp_pregnancy_program t
inner join encounter e on e.encounter_id = latest_anc_intake_encounter_id
set anc_intake_visit_id = e.visit_id;

update temp_pregnancy_program set pregnancy_status = 'Antenatal' where actual_delivery_date is null and estimated_gestational_age <= 45 and outcome_concept_id is null and current_state_concept_id != concept_from_mapping('CIEL', '1180');
update temp_pregnancy_program set pregnancy_status = 'Postpartum, delivered' where delivery_outcome in ('Alive', 'Stillbirth', 'Multiple outcome');
update temp_pregnancy_program set pregnancy_status = 'Postpartum, miscarriage' where outcome_concept_id = concept_from_mapping('PIH', '1852');
update temp_pregnancy_program set pregnancy_status = 'Presumed postpartum' where pregnancy_status is null and estimated_gestational_age > 45;

update temp_pregnancy_program set delivery_location = 'outborn' where delivery_location is null and pregnancy_status != 'Prenatal';
update temp_pregnancy_program set delivery_location = 'miscarried' where outcome = 'Miscarried';

-- columns dependent on dispensing events
drop temporary table if exists temp_med_orders;
create temporary table temp_med_orders
(patient_program_id int(11),
patient_id int(11),
medication_dispense_id int(11),
concept_id int(11),
category text);

insert into temp_med_orders(patient_program_id, patient_id, medication_dispense_id, concept_id, category)
select patient_program_id, t.patient_id,medication_dispense_id, concept, 'Iron'
from medication_dispense d 
inner join temp_pregnancy_program t 
	on t.patient_id = d.patient_id
where (d.date_handed_over >= t.anc_state_date
and (d.date_handed_over <= t.post_partum_state_date or t.post_partum_state_date is null)
and (d.date_handed_over <= t.date_completed or t.date_completed is null))
and d.concept in (@ferrous_sulfate_folic_acid, @ferrous_sulfate);;

insert into temp_med_orders(patient_program_id, patient_id, medication_dispense_id, concept_id, category)
select patient_program_id, t.patient_id,medication_dispense_id, concept, 'Antimalarial'
from medication_dispense d 
inner join temp_pregnancy_program t 
	on t.patient_id = d.patient_id
where (d.date_handed_over >= t.anc_state_date
and (d.date_handed_over <= t.post_partum_state_date or t.post_partum_state_date is null)
and (d.date_handed_over <= t.date_completed or t.date_completed is null))
and concept_in_set(d.concept, @antimalarial_set)  
;

insert into temp_med_orders(patient_program_id, patient_id, medication_dispense_id, concept_id, category)
select patient_program_id, t.patient_id,medication_dispense_id, concept, 'ART'
from medication_dispense d 
inner join temp_pregnancy_program t 
	on t.patient_id = d.patient_id
where (d.date_handed_over >= t.anc_state_date
and (d.date_handed_over <= t.post_partum_state_date or t.post_partum_state_date is null)
and (d.date_handed_over <= t.date_completed or t.date_completed is null))
and concept_in_set(d.concept, @art_set)  
;

create index temp_med_orders_ppi on temp_med_orders(patient_program_id);

update temp_pregnancy_program t
set arv_for_pmtct = 1
where EXISTS 
	(select 1 from temp_med_orders o where o.patient_program_id = t.patient_program_id
	and category = 'ART');
update temp_pregnancy_program t set arv_for_pmtct = 0 where total_anc_visits >= 1 and arv_for_pmtct is null;

update temp_pregnancy_program t
set malaria_treatment_during_antenatal = 1
where EXISTS 
	(select 1 from temp_med_orders o where o.patient_program_id = t.patient_program_id
	and category = 'Antimalarial');
update temp_pregnancy_program t set malaria_treatment_during_antenatal = 0 where total_anc_visits >= 1 and malaria_treatment_during_antenatal is null;

update temp_pregnancy_program t
set iron_ifa_ever = 1
where EXISTS 
	(select 1 from temp_med_orders o where o.patient_program_id = t.patient_program_id
	and category = 'Iron');
update temp_pregnancy_program t set iron_ifa_ever = 0 where total_anc_visits >= 1 and iron_ifa_ever is null;

-- columns using labs
call temp_program_encounter_create();
call temp_program_encounter_populate(@labResults);
call temp_program_encounter_populate(@specimenCollection);
call temp_program_encounter_create_indexes();
call temp_program_obs_create();
call temp_program_obs_populate('en');

select temp_program_obs_latest_obs_datetime(patient_program_id, 'PIH', '12265',null,null), t.* from temp_pregnancy_program t;

update temp_pregnancy_program 
set syphilis_test_ever = 
CASE
	when temp_program_obs_latest_obs_datetime(patient_program_id, 'PIH', '12265',null,null) is not null
		or temp_program_obs_latest_obs_datetime(patient_program_id, 'PIH', '1478',null,null) is not null then 1
	when total_anc_visits >= 1 then 0 
END;

-- columns using Vitals
call temp_program_encounter_create();
call temp_program_encounter_populate(@vitals);
call temp_program_encounter_create_indexes();
call temp_program_obs_create();
call temp_program_obs_populate('en');

update temp_pregnancy_program set muac_measured = 
	if(temp_program_obs_latest_obs_datetime(patient_program_id, 'PIH', '7956', anc_state_date, post_partum_state_date) is null,null,1);
update temp_pregnancy_program t
set muac_measured = 0 where total_anc_visits >= 1 and muac_measured is null;

update temp_pregnancy_program t
set anc_visit1_weight_recorded  = 1
where exists 
	(select 1 from temp_program_encounter e 
	inner join temp_program_obs o on o.encounter_id = e.encounter_id
		and o.concept_id = @weightConceptId
	where e.visit_id = t.anc_intake_visit_id 
	and e.patient_program_id = t.patient_program_id);
update temp_pregnancy_program t
set anc_visit1_weight_recorded = 0 where total_anc_visits >= 1 and anc_visit1_weight_recorded is null;

select concat(@partition,'-',patient_program_id) as pregnancy_program_id,
       concat(@partition,'-',patient_id) as patient_id,
       emr_id,
       reg_location,
       date_enrolled,
       date_completed,
       outcome,
       current_state,
       pregnancy_status,
       mother_birthdate as birthdate,
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
       iptp_sp_malaria_ever,
       nutrition_counseling_ever,
       hiv_counsel_and_test_ever,
       insecticide_treated_net_ever,
       iron_ifa_ever,
       syphilis_test_ever,
       arv_for_pmtct,
       muac_measured,
       anc_visit1_weight_recorded,
       malaria_treatment_during_antenatal,
       index_asc,
       index_desc
from temp_pregnancy_program;
