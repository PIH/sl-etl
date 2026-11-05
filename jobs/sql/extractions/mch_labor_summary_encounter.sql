set @partition = '${partitionNum}';

SELECT encounter_type_id  INTO @labor_enc
FROM encounter_type et WHERE uuid='fec2cc56-e35f-42e1-8ae3-017142c1ca59';
set @pregnancyProgramId = program('Pregnancy');

drop temporary table if exists temp_labor_encs;
create temporary table temp_labor_encs
(
    patient_id                              int,
    emr_id                                  varchar(255),
    encounter_id                            int,
    visit_id                                int,
    pregnancy_program_id                    int,
    encounter_datetime                      datetime,
    encounter_location                      varchar(255),
    datetime_entered                        datetime,
    user_entered                            varchar(255),
    provider                                varchar(255),
    age_at_encounter                        int,
    labor_start                             datetime,
    induced_labor                           boolean,
    induction_time                          datetime,
    method_of_induction                     varchar(255),
    companion_present                       boolean,
    t_first_hour                            decimal(8, 3),
    t_first_minute                          decimal(8, 3),
    duration_first_stage                    decimal(8, 3),
    second_stage_start                      varchar(255),
    t_second_hour                           decimal(8, 3),
    t_second_minute                         decimal(8, 3),
    duration_second_stage                   decimal(8, 3),
    multiple_birth                          boolean,
    amtsl                                   boolean,
    visual_inspection_placenta_completeness varchar(255),
    birth_attendant                         varchar(255),
    breastfeeding_initiation_datetime       datetime,
    perineal_tear                           varchar(255),
    perineal_tear_procedure                 varchar(255),
    t_third_hour                            decimal(8, 3),
    t_third_minute                          decimal(8, 3),
    duration_third_stage                    decimal(8, 3),
    t_total_hour                            decimal(8, 3),
    t_total_minute                          decimal(8, 3),
    total_duration_labor                    decimal(8, 3),
    partogram_uploaded                      bit,
    uterotonic_after_birth                  bit,
    uterotonic_datetime                     datetime,
    blood_loss_before_delivery_ml           decimal(8, 2),
    blood_loss_after_delivery_ml            decimal(8, 2),
    placenta_weight_g                       decimal(8, 2),
    placenta_abnormality                    boolean,
    placenta_abnormality_specify            text,
    cord_length_cm                          decimal(8, 2),
    cord_abnormality                        text,
    breastfeeding_initiated                 boolean,
    skin_to_skin_initiated                  boolean,
    birth_attendant_other                   varchar(255),
    number_of_sutures                       int,
    sutured_by                              varchar(255),
    perineum_comments                       text,
    hiv_rapid_test_obs_id                   int,
    hiv_rapid_test_obs_group_id             int,
    hiv_rapid_test_result                   varchar(255),
    hiv_rapid_test_reason_not_performed     varchar(255),
    syphilis_rapid_test_obs_id              int,
    syphilis_rapid_test_obs_group_id        int,
    syphilis_rapid_test_result              varchar(255),
    syphilis_rapid_test_reason_not_performed varchar(255),
    hep_b_test_result                       varchar(255),
    phq2_score                              int,
    index_asc                               INT,
    index_desc                              INT
);

insert into temp_labor_encs(patient_id, encounter_id, visit_id, encounter_datetime, datetime_entered, user_entered)
select patient_id, encounter_id, visit_id, encounter_datetime, date_created, creator
from encounter e
where e.voided = 0
AND encounter_type IN (@labor_enc)
ORDER BY encounter_datetime desc;

create index temp_labor_encs_ei on temp_labor_encs (encounter_id);

UPDATE temp_labor_encs set user_entered = person_name_of_user(user_entered);
UPDATE temp_labor_encs SET provider = provider(encounter_id);
UPDATE temp_labor_encs t SET emr_id = patient_identifier(patient_id, 'c09a1d24-7162-11eb-8aa6-0242ac110002');
UPDATE temp_labor_encs SET encounter_location=encounter_location_name(encounter_id);

UPDATE temp_labor_encs SET pregnancy_program_id = patient_program_id_from_encounter(patient_id, @pregnancyProgramId ,encounter_id);

DROP TEMPORARY TABLE IF EXISTS temp_obs;
create temporary table temp_obs
select o.obs_id, o.voided ,o.obs_group_id , o.encounter_id, o.person_id, o.concept_id, o.value_coded, o.value_numeric,
o.value_text,o.value_datetime, o.comments, o.date_created, o.obs_datetime
from obs o
inner join temp_labor_encs t on t.encounter_id = o.encounter_id
where o.voided = 0;

create index temp_obs_encs_ei on temp_obs(encounter_id);
create index temp_obs_encs_eobs on temp_obs(encounter_id, obs_group_id);

UPDATE temp_labor_encs t SET labor_start = obs_value_datetime_from_temp(encounter_id, 'PIH','14377');
UPDATE temp_labor_encs t SET induced_labor = obs_value_coded_as_boolean_from_temp(encounter_id, 'PIH','15113');
UPDATE temp_labor_encs t SET induction_time = obs_value_datetime_from_temp(encounter_id, 'PIH','15116');
UPDATE temp_labor_encs t SET method_of_induction = obs_value_coded_list_from_temp(encounter_id, 'PIH','15114','en');
UPDATE temp_labor_encs t SET t_first_hour = obs_value_numeric_from_temp(encounter_id, 'PIH','20114');
UPDATE temp_labor_encs t SET t_first_minute = obs_value_numeric_from_temp(encounter_id, 'PIH','20115');
UPDATE temp_labor_encs t SET duration_first_stage = t_first_hour+(t_first_minute/60);
UPDATE temp_labor_encs t SET second_stage_start = obs_value_datetime_from_temp(encounter_id, 'PIH','20113');
UPDATE temp_labor_encs t SET t_second_hour = obs_value_numeric_from_temp(encounter_id, 'PIH','20116');
UPDATE temp_labor_encs t SET t_second_minute = obs_value_numeric_from_temp(encounter_id, 'PIH','20117');
UPDATE temp_labor_encs t SET duration_second_stage = t_second_hour+(t_second_minute/60);
-- multiple birth is the "twins or triplets" diagnosis checkbox on this encounter, or more than one newborn recorded on it
-- (previously used answerEverExists_from_temp, which flagged any multiple gestation diagnosis in the patient's history)
UPDATE temp_labor_encs t SET multiple_birth = answer_exists_in_encounter_temp(encounter_id, 'PIH','3064','PIH','7225');
set @newborn_details = concept_from_mapping('PIH','13555');
UPDATE temp_labor_encs t SET multiple_birth = 1
where (select count(*) from temp_obs o where o.encounter_id = t.encounter_id and o.concept_id = @newborn_details and o.obs_group_id is null) > 1;
UPDATE temp_labor_encs t SET amtsl = obs_value_coded_as_boolean_from_temp(encounter_id, 'PIH','13533');
UPDATE temp_labor_encs t SET visual_inspection_placenta_completeness = obs_value_coded_list_from_temp(encounter_id, 'PIH','13537','en');
UPDATE temp_labor_encs t SET birth_attendant = obs_value_coded_list_from_temp(encounter_id, 'PIH','20118','en');
UPDATE temp_labor_encs t SET perineal_tear = obs_value_coded_list_from_temp(encounter_id, 'PIH','12369','en');
UPDATE temp_labor_encs t SET t_third_hour = obs_value_numeric_from_temp(encounter_id, 'PIH','20124');
UPDATE temp_labor_encs t SET t_third_minute = obs_value_numeric_from_temp(encounter_id, 'PIH','20125');
UPDATE temp_labor_encs t SET duration_third_stage = t_third_hour+(t_third_minute/60);
UPDATE temp_labor_encs t SET t_total_hour = obs_value_numeric_from_temp(encounter_id, 'PIH','20457');
UPDATE temp_labor_encs t SET t_total_minute = obs_value_numeric_from_temp(encounter_id, 'PIH','20458');
-- the form records total duration as hours + minutes (PIH:20457/20458); CIEL:159616 is the legacy single-value question
UPDATE temp_labor_encs t SET total_duration_labor =
    case when t_total_hour is null and t_total_minute is null
         then obs_value_numeric_from_temp(encounter_id, 'CIEL','159616')
         else ifnull(t_total_hour,0) + (ifnull(t_total_minute,0)/60)
    end;
UPDATE temp_labor_encs t SET breastfeeding_initiation_datetime = obs_value_datetime_from_temp(encounter_id, 'PIH',21116);
UPDATE temp_labor_encs t SET partogram_uploaded = (select count(o.obs_id) > 0 from temp_obs o where o.encounter_id = t.encounter_id and o.concept_id = concept_from_mapping('PIH', '13756'));
UPDATE temp_labor_encs t SET age_at_encounter = AGE_AT_ENC(patient_id, encounter_id);
UPDATE temp_labor_encs t SET uterotonic_after_birth = obs_value_coded_as_boolean_from_temp(encounter_id, 'PIH','14373');
UPDATE temp_labor_encs t SET uterotonic_datetime = obs_value_datetime_from_temp(encounter_id, 'PIH','21403');
-- checkboxes: an unticked box saves no obs, so load NULL rather than 0 (1 = ticked, NULL = not ticked / not recorded)
UPDATE temp_labor_encs t SET companion_present = NULLIF(answer_exists_in_encounter_temp(encounter_id, 'PIH','6547','PIH','14646'), 0);
UPDATE temp_labor_encs t SET blood_loss_before_delivery_ml = obs_value_numeric_from_temp(encounter_id, 'PIH','20130');
UPDATE temp_labor_encs t SET blood_loss_after_delivery_ml = obs_value_numeric_from_temp(encounter_id, 'PIH','20131');
UPDATE temp_labor_encs t SET placenta_weight_g = obs_value_numeric_from_temp(encounter_id, 'PIH','20122');
UPDATE temp_labor_encs t SET placenta_abnormality = obs_value_coded_as_boolean_from_temp(encounter_id, 'CIEL','130109');
UPDATE temp_labor_encs t SET placenta_abnormality_specify = obs_value_text_from_temp(encounter_id, 'PIH','20152');
UPDATE temp_labor_encs t SET cord_length_cm = obs_value_numeric_from_temp(encounter_id, 'PIH','20129');
UPDATE temp_labor_encs t SET cord_abnormality = obs_value_text_from_temp(encounter_id, 'CIEL','168722');
UPDATE temp_labor_encs t SET breastfeeding_initiated = obs_value_coded_as_boolean_from_temp(encounter_id, 'CIEL','161543');
-- skin-to-skin is stored under "Procedure performed" (CIEL:1651), the same question as episiotomy/suture, so filter on the answer
UPDATE temp_labor_encs t SET skin_to_skin_initiated = NULLIF(answer_exists_in_encounter_temp(encounter_id, 'CIEL','1651','CIEL','164173'), 0);
UPDATE temp_labor_encs t SET birth_attendant_other = obs_value_text_from_temp(encounter_id, 'PIH','20119');
UPDATE temp_labor_encs t SET number_of_sutures = obs_value_numeric_from_temp(encounter_id, 'PIH','20121');
UPDATE temp_labor_encs t SET sutured_by = obs_value_text_from_temp(encounter_id, 'PIH','20126');
UPDATE temp_labor_encs t SET perineum_comments = obs_value_text_from_temp(encounter_id, 'PIH','20128');
UPDATE temp_labor_encs t SET phq2_score = obs_value_numeric_from_temp(encounter_id, 'PIH','PHQ-2');

-- rapid tests (lab results section); reason not performed shares a concept across tests, so read it from each test's obs group
set @hiv_rapid_test_result = concept_from_mapping('CIEL','163722');
set @syphilis_rapid_test_result = concept_from_mapping('CIEL','165303');
set @rapid_test_reason_not_performed = concept_from_mapping('CIEL','165182');
UPDATE temp_labor_encs t SET hiv_rapid_test_obs_id = obs_id_from_temp_using_concept_id(encounter_id, @hiv_rapid_test_result, 0);
UPDATE temp_labor_encs t SET hiv_rapid_test_obs_group_id = obs_group_id_from_obs(hiv_rapid_test_obs_id);
UPDATE temp_labor_encs t SET hiv_rapid_test_result = value_coded_name(hiv_rapid_test_obs_id, @locale);
UPDATE temp_labor_encs t SET hiv_rapid_test_reason_not_performed = obs_from_group_id_value_coded_list_using_concept_id(hiv_rapid_test_obs_group_id, @rapid_test_reason_not_performed, @locale);
UPDATE temp_labor_encs t SET syphilis_rapid_test_obs_id = obs_id_from_temp_using_concept_id(encounter_id, @syphilis_rapid_test_result, 0);
UPDATE temp_labor_encs t SET syphilis_rapid_test_obs_group_id = obs_group_id_from_obs(syphilis_rapid_test_obs_id);
UPDATE temp_labor_encs t SET syphilis_rapid_test_result = value_coded_name(syphilis_rapid_test_obs_id, @locale);
UPDATE temp_labor_encs t SET syphilis_rapid_test_reason_not_performed = obs_from_group_id_value_coded_list_using_concept_id(syphilis_rapid_test_obs_group_id, @rapid_test_reason_not_performed, @locale);
UPDATE temp_labor_encs t SET hep_b_test_result = obs_value_coded_list_from_temp(encounter_id, 'CIEL','159430', @locale);



set @perineal_tear_procedure = concept_from_mapping('PIH','10484');
set @episiotomy = concept_from_mapping('CIEL','5577');
set @suture = concept_from_mapping('CIEL','164157');
UPDATE temp_labor_encs t
inner join 
	(select  o.encounter_id, group_concat(distinct concept_name(o.value_coded, @locale) separator ' | ') "perineal_tear_procedure"
	from temp_obs o 
	where o.concept_id = @perineal_tear_procedure 
	and o.value_coded in (@episiotomy, @suture)
	group by o.encounter_id) eo on eo.encounter_id = t.encounter_id
set t.perineal_tear_procedure = eo.perineal_tear_procedure;	

SELECT
    concat(@partition, '-', encounter_id) as encounter_id,
    concat(@partition, '-', visit_id) as visit_id,
    concat(@partition, '-', patient_id) as patient_id,
    emr_id,
    concat(@partition, '-', pregnancy_program_id) as pregnancy_program_id,
    encounter_datetime,
    encounter_location,
    datetime_entered,
    user_entered,
    provider,
    age_at_encounter,
    labor_start,
    induced_labor,
    induction_time,
    method_of_induction,
    companion_present,
    duration_first_stage,
    second_stage_start,
    duration_second_stage,
    case when multiple_birth is null then false else multiple_birth end as multiple_birth,
    amtsl,
    visual_inspection_placenta_completeness,
    birth_attendant,
    breastfeeding_initiation_datetime,
    perineal_tear,
    perineal_tear_procedure,
    duration_third_stage,
    total_duration_labor,
    partogram_uploaded,
    uterotonic_after_birth,
    uterotonic_datetime,
    blood_loss_before_delivery_ml,
    blood_loss_after_delivery_ml,
    placenta_weight_g,
    placenta_abnormality,
    placenta_abnormality_specify,
    cord_length_cm,
    cord_abnormality,
    breastfeeding_initiated,
    skin_to_skin_initiated,
    birth_attendant_other,
    number_of_sutures,
    sutured_by,
    perineum_comments,
    hiv_rapid_test_result,
    hiv_rapid_test_reason_not_performed,
    syphilis_rapid_test_result,
    syphilis_rapid_test_reason_not_performed,
    hep_b_test_result,
    phq2_score,
    index_asc,
    index_desc
FROM temp_labor_encs;
