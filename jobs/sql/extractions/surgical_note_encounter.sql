set @partition = '${partitionNum}';

SELECT encounter_type_id INTO @surgical_note_enc_type
FROM encounter_type WHERE uuid = 'c4941dee-7a9b-4c1c-aa6f-8193e9e5e4e5';
set @pregnancyProgramId = program('Pregnancy');

select encounter_role_id into @attendingSurgeon from encounter_role where uuid = '9b135b19-7ebe-4a51-aea2-69a53f9383af';
select encounter_role_id into @assistingSurgeon from encounter_role where uuid = '6e630e03-5182-4cb3-9a82-a5b1a85c09a7';
select encounter_role_id into @nurse from encounter_role where uuid = '98bf2792-3f0a-4388-81bb-c78b29c0df92';
select encounter_role_id into @anesthesiologist from encounter_role where uuid = 'de11b25c-a641-4630-9524-5b85ece9a4f8';

drop temporary table if exists temp_surgical_note;
create temporary table temp_surgical_note
(
    patient_id                          int,
    emr_id                              varchar(255),
    encounter_id                        int,
    visit_id                            int,
    pregnancy_program_id                int,
    encounter_datetime                  datetime,
    encounter_location                  varchar(255),
    datetime_entered                    datetime,
    user_entered                        varchar(255),
    attending_surgeon                   text,
    assisting_surgeon_1                 text,
    assisting_surgeon_2                 text,  
    nurse_1                             text,
    nurse_2                             text,
    anesthesiologist_1                  text,
    anesthesiologist_2                  text,    
    age_at_encounter                    int,
    -- Service / Team
    surgical_service                    varchar(255),
    assistant_surgeon_other             varchar(255),
    -- Description
    admission_status                    varchar(255),
    emergency                           varchar(255),
    scheduled_surgery                   varchar(255),
    planned_return_to_or                varchar(255),
    pre_op_diagnoses                    text,
    post_op_diagnoses                   text,
    procedures_performed                text,
    anesthesia_type                     varchar(255),
    anesthesia_complications            varchar(255),
    wound_classification                varchar(255),
    -- Ins / Outs: IVF
    ivf_type                            varchar(255),
    -- Ins / Outs: Transfusion
    transfusion_given                   varchar(255),
    whole_blood_transfusion             boolean,
    prbc_transfusion                    boolean,
    plasma_transfusion                  boolean,
    platelet_transfusion                boolean,
    -- Antibiotics / VTE
    pre_op_antibiotic_given             varchar(255),
    antibiotics_given                   text,
    vte_prophylaxis                     varchar(255),
    -- Plan / Findings
    findings_comments                   text,
    instructions                        text,
    baby_observations                   text,
    drainage_removal_date               date,
    stitches_removal_date               date,
    -- indices
    index_asc                           int,
    index_desc                          int
);

insert into temp_surgical_note(patient_id, encounter_id, visit_id, encounter_datetime,
    datetime_entered, user_entered)
select patient_id, encounter_id, visit_id, encounter_datetime, date_created, creator
from encounter e
where e.voided = 0
  AND encounter_type = @surgical_note_enc_type
ORDER BY encounter_datetime desc;

create index temp_surgical_note_ei on temp_surgical_note(encounter_id);
create index temp_surgical_note_pi on temp_surgical_note(patient_id);

update temp_surgical_note
set pregnancy_program_id = patient_program_id_from_encounter(patient_id, @pregnancyProgramId ,encounter_id);

UPDATE temp_surgical_note
set user_entered = person_name_of_user(user_entered);

UPDATE temp_surgical_note SET attending_surgeon = provider_name_of_type(encounter_id, @attendingSurgeon, 0);
UPDATE temp_surgical_note SET assisting_surgeon_1 = provider_name_of_type(encounter_id, @assistingSurgeon, 0);
UPDATE temp_surgical_note SET assisting_surgeon_2 = provider_name_of_type(encounter_id, @assistingSurgeon, 1);
UPDATE temp_surgical_note SET nurse_1 = provider_name_of_type(encounter_id, @nurse, 0);
UPDATE temp_surgical_note SET nurse_2 = provider_name_of_type(encounter_id, @nurse, 1);
UPDATE temp_surgical_note SET anesthesiologist_1  = provider_name_of_type(encounter_id, @anesthesiologist, 0);
UPDATE temp_surgical_note SET anesthesiologist_2  = provider_name_of_type(encounter_id, @anesthesiologist, 1);


UPDATE temp_surgical_note t
SET emr_id = patient_identifier(patient_id, metadata_uuid('org.openmrs.module.emrapi', 'emr.primaryIdentifierType'));

UPDATE temp_surgical_note
SET encounter_location = encounter_location_name(encounter_id);

UPDATE temp_surgical_note
SET age_at_encounter = age_at_enc(patient_id, encounter_id);

DROP TEMPORARY TABLE IF EXISTS temp_obs;
create temporary table temp_obs
select o.obs_id, o.voided, o.obs_group_id, o.encounter_id, o.person_id, o.concept_id,
       o.value_coded, o.value_numeric, o.value_text, o.value_datetime, o.comments,
       o.date_created, o.obs_datetime
from obs o
inner join temp_surgical_note t on t.encounter_id = o.encounter_id
where o.voided = 0;

create index temp_obs_surgical_ei   on temp_obs(encounter_id);
create index temp_obs_surgical_eobs on temp_obs(encounter_id, obs_group_id);

-- concept mappings
SET @surgical_service            = concept_from_mapping('PIH', 'Surgical service');
SET @assistant_surgeon_other     = concept_from_mapping('PIH', 'Name of assistant surgeon');
SET @admission_status            = concept_from_mapping('PIH', 'TYPE OF PATIENT');
SET @emergency                   = concept_from_mapping('PIH', 'Emergency');
SET @planned_return_to_or        = concept_from_mapping('PIH', 'Planned return to operating room');
SET @scheduled_surgery           = concept_from_mapping('PIH', 'Scheduled surgery');
SET @pre_op_diagnosis            = concept_from_mapping('PIH', 'Pre-surgery diagnosis');
SET @post_op_diagnosis           = concept_from_mapping('PIH', 'Post-surgery diagnosis');
SET @surgical_procedure          = concept_from_mapping('PIH', 'Surgical procedure');
SET @anesthesia_type             = concept_from_mapping('PIH', 'Type of anesthesia');
SET @anesthesia_complications    = concept_from_mapping('PIH', '21118');
SET @wound_classification        = concept_from_mapping('PIH', 'Classifications of surgical wounds');
SET @ivf_administered            = concept_from_mapping('PIH', 'IVF administered');
SET @transfusion_status          = concept_from_mapping('PIH', 'Transfusion status');
SET @transfusion_of_fluid        = concept_from_mapping('PIH', 'Transfusion of fluid');
SET @whole_blood                 = concept_from_mapping('PIH', 'Whole blood');
SET @prbc                        = concept_from_mapping('PIH', 'Packed red blood cells');
SET @plasma                      = concept_from_mapping('PIH', 'Plasma');
SET @platelets                   = concept_from_mapping('PIH', 'Platelets');
SET @pre_op_antibiotic           = concept_from_mapping('PIH', 'Pre-operative antibiotic administered');
SET @surgery_antibiotics         = concept_from_mapping('PIH', 'Surgery antibiotics');
SET @vte_prophylaxis             = concept_from_mapping('PIH', 'Venous thromboembolism prophylaxis');
SET @findings_comments           = concept_from_mapping('PIH', 'Additional Surgery Comments');
SET @instructions                = concept_from_mapping('CIEL', '163106');
SET @baby_observations           = concept_from_mapping('PIH', '21120');
SET @drainage_removal_date       = concept_from_mapping('PIH', '20926');
SET @stitches_removal_date       = concept_from_mapping('PIH', '20927');

-- Service / Team
UPDATE temp_surgical_note t SET surgical_service        = obs_value_coded_list_from_temp_using_concept_id(encounter_id, @surgical_service, 'en');
UPDATE temp_surgical_note t SET assistant_surgeon_other = obs_value_text_from_temp_using_concept_id(encounter_id, @assistant_surgeon_other);

-- Description
UPDATE temp_surgical_note t SET admission_status        = obs_value_coded_list_from_temp_using_concept_id(encounter_id, @admission_status, 'en');
UPDATE temp_surgical_note t SET emergency               = obs_value_coded_list_from_temp_using_concept_id(encounter_id, @emergency, 'en');
UPDATE temp_surgical_note t SET scheduled_surgery       = obs_value_coded_list_from_temp_using_concept_id(encounter_id, @scheduled_surgery, 'en');
UPDATE temp_surgical_note t SET planned_return_to_or    = obs_value_coded_list_from_temp_using_concept_id(encounter_id, @planned_return_to_or, 'en');
UPDATE temp_surgical_note t SET pre_op_diagnoses        = obs_value_coded_list_from_temp_using_concept_id(encounter_id, @pre_op_diagnosis, 'en');
UPDATE temp_surgical_note t SET post_op_diagnoses       = obs_value_coded_list_from_temp_using_concept_id(encounter_id, @post_op_diagnosis, 'en');
UPDATE temp_surgical_note t SET procedures_performed    = obs_value_coded_list_from_temp_using_concept_id(encounter_id, @surgical_procedure, 'en');
UPDATE temp_surgical_note t SET anesthesia_type         = obs_value_coded_list_from_temp_using_concept_id(encounter_id, @anesthesia_type, 'en');
UPDATE temp_surgical_note t SET anesthesia_complications = obs_value_text_from_temp_using_concept_id(encounter_id, @anesthesia_complications);
UPDATE temp_surgical_note t SET wound_classification    = obs_value_coded_list_from_temp_using_concept_id(encounter_id, @wound_classification, 'en');

-- IVF (obs members live directly inside the IVF obsgroup)
UPDATE temp_surgical_note t SET ivf_type      = obs_value_coded_list_from_temp_using_concept_id(encounter_id, @ivf_administered, 'en');

-- Transfusion header
UPDATE temp_surgical_note t SET transfusion_given = obs_value_coded_list_from_temp_using_concept_id(encounter_id, @transfusion_status, 'en');

-- Transfusion subtypes: boolean presence + volume per product, joining sibling obs via shared obs_group_id
UPDATE temp_surgical_note t
SET whole_blood_transfusion = IF(EXISTS(
    SELECT 1 FROM temp_obs WHERE encounter_id = t.encounter_id
      AND concept_id = @transfusion_of_fluid AND value_coded = @whole_blood), 1, 0);

UPDATE temp_surgical_note t
SET prbc_transfusion = IF(EXISTS(
    SELECT 1 FROM temp_obs WHERE encounter_id = t.encounter_id
      AND concept_id = @transfusion_of_fluid AND value_coded = @prbc), 1, 0);

UPDATE temp_surgical_note t
SET plasma_transfusion = IF(EXISTS(
    SELECT 1 FROM temp_obs WHERE encounter_id = t.encounter_id
      AND concept_id = @transfusion_of_fluid AND value_coded = @plasma), 1, 0);

UPDATE temp_surgical_note t
SET platelet_transfusion = IF(EXISTS(
    SELECT 1 FROM temp_obs WHERE encounter_id = t.encounter_id
      AND concept_id = @transfusion_of_fluid AND value_coded = @platelets), 1, 0);

-- Antibiotics / VTE
UPDATE temp_surgical_note t SET pre_op_antibiotic_given = obs_value_coded_list_from_temp_using_concept_id(encounter_id, @pre_op_antibiotic, 'en');
UPDATE temp_surgical_note t SET antibiotics_given       = obs_value_coded_list_from_temp_using_concept_id(encounter_id, @surgery_antibiotics, 'en');
UPDATE temp_surgical_note t SET vte_prophylaxis         = obs_value_coded_list_from_temp_using_concept_id(encounter_id, @vte_prophylaxis, 'en');

-- Plan / Findings
UPDATE temp_surgical_note t SET findings_comments     = obs_value_text_from_temp_using_concept_id(encounter_id, @findings_comments);
UPDATE temp_surgical_note t SET instructions          = obs_value_text_from_temp_using_concept_id(encounter_id, @instructions);
UPDATE temp_surgical_note t SET baby_observations     = obs_value_text_from_temp_using_concept_id(encounter_id, @baby_observations);
UPDATE temp_surgical_note t SET drainage_removal_date = date(obs_value_datetime_from_temp_using_concept_id(encounter_id, @drainage_removal_date));
UPDATE temp_surgical_note t SET stitches_removal_date = date(obs_value_datetime_from_temp_using_concept_id(encounter_id, @stitches_removal_date));

SELECT
    concat(@partition, '-', patient_id)    AS patient_id,
    emr_id,
    concat(@partition, '-', encounter_id)  AS encounter_id,
    concat(@partition, '-', visit_id)      AS visit_id,
    concat(@partition,"-",pregnancy_program_id)  as pregnancy_program_id,
    encounter_datetime,
    encounter_location,
    datetime_entered,
    user_entered,
    attending_surgeon,
    assisting_surgeon_1,
    assisting_surgeon_2,  
    nurse_1,
    nurse_2,
    anesthesiologist_1,
    anesthesiologist_2, 
    age_at_encounter,
    surgical_service,
    assistant_surgeon_other,
    admission_status,
    emergency,
    scheduled_surgery,
    planned_return_to_or,
    pre_op_diagnoses,
    post_op_diagnoses,
    procedures_performed,
    anesthesia_type,
    anesthesia_complications,
    wound_classification,
    ivf_type,
    transfusion_given,
    whole_blood_transfusion,
    prbc_transfusion,
    plasma_transfusion,
    platelet_transfusion,
    pre_op_antibiotic_given,
    antibiotics_given,
    vte_prophylaxis,
    findings_comments,
    instructions,
    baby_observations,
    drainage_removal_date,
    stitches_removal_date,
    index_asc,
    index_desc
FROM temp_surgical_note;
