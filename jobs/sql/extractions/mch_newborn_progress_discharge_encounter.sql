set @partition = '${partitionNum}';

SELECT encounter_type_id INTO @newborn_progress_enc FROM encounter_type et WHERE uuid = '7e42e652-89e7-4559-80fd-41f42826c98c';
SELECT encounter_type_id INTO @newborn_discharge_enc FROM encounter_type et WHERE uuid = '153d3182-c76f-4047-b7f2-d83cf967b206';

drop temporary table if exists temp_enc;
create temporary table temp_enc
(
    encounter_id                  int,
    visit_id                      int,
    patient_id                    int,
    emr_id                        varchar(255),
    encounter_datetime            datetime,
    encounter_location            varchar(255),
    datetime_entered              datetime,
    user_entered                  varchar(255),
    provider                      varchar(255),
    visit_type                    varchar(255),
    bp_systolic                   int,
    bp_diastolic                  int,
    respiratory_rate              int,
    o2_saturation                 int,
    glucose                       double,
    doctor_contacted              bit,
    length_cm                     double,
    head_circumference_cm         double,
    muac_cm                       double,
    rbg                           double,
    umbilical_cord                varchar(255),
    eyes                          varchar(255),
    umbilical_eye_comments        text,
    skin_color                    varchar(255),
    skin_comments                 text,
    urination                     varchar(255),
    urination_comments            text,
    stool                         varchar(255),
    stool_comments                text,
    neuro_exam                    varchar(255),
    seizures                      bit,
    neuro_comments                text,
    cardiac_exam                  varchar(255),
    cardiac_comments              text,
    downes_score                  int,
    silverman_andersen_score      int,
    thompson_hie_score            int,
    feeding_method                varchar(255),
    feeding_route                 varchar(255),
    iv_access                     bit,
    iv_placement_date             datetime,
    iv_site                       varchar(255),
    days_with_iv                  int,
    ivf_type                      varchar(1000),
    ivf_volume                    double,
    air_supply                    varchar(255),
    o2_flow_rate                  double,
    cpap_pressure                 double,
    fio2                          double,
    apnea                         bit,
    apnea_duration                double,
    neonatal_resuscitation        bit,
    resus_supplemental_oxygen     bit,
    resus_ventilation_bag         bit,
    resus_intubation              bit,
    resus_heart_massage           bit,
    days_with_respiratory_support int,
    adrenaline_administered       bit,
    adrenaline_dosing             text,
    transfusion_given             bit,
    transfusion_type              varchar(255),
    whole_blood_transfusion       bit,
    whole_blood_volume            double,
    prbc_transfusion              bit,
    prbc_volume                   double,
    plasma_transfusion            bit,
    plasma_volume                 double,
    platelet_transfusion          bit,
    platelet_volume               double,
    transfusion_reaction          bit,
    urine_output                  double,
    estimated_blood_loss          double,
    surgery_recommended           bit,
    weight                        double,
    temperature                   double,
    heart_rate                    int,
    eye_drops                     bit,
    umbilical_cord_care           bit,
    vitamin_k                     bit,
    vitamin_d                     bit,
    treatment_plan                text,
    overall_condition             varchar(255),
    summary_notes                 text,
    remarks                       text,
    disposition                   varchar(255),
    transfer_in_location_newborn  varchar(255),
    transfer_in_location          varchar(255),
    transfer_out_location_newborn varchar(255),
    transfer_out_location         varchar(255),
    transfer_location             varchar(255),
    death_date                    datetime,
    index_asc                     INT,
    index_desc                    INT
);

insert into temp_enc (patient_id, encounter_id, visit_id, encounter_datetime, datetime_entered, user_entered, visit_type)
select patient_id, encounter_id, visit_id, encounter_datetime, date_created, creator, if(encounter_type = @newborn_progress_enc, 'Daily assessment', 'Discharge')
from encounter e
where e.voided = 0
AND encounter_type IN (@newborn_progress_enc, @newborn_discharge_enc)
ORDER BY encounter_datetime desc;

create index temp_enc_ei on temp_enc (encounter_id);

UPDATE temp_enc set user_entered = person_name_of_user(user_entered);
UPDATE temp_enc SET provider = provider(encounter_id);
UPDATE temp_enc t SET emr_id = patient_identifier(patient_id, 'c09a1d24-7162-11eb-8aa6-0242ac110002');
UPDATE temp_enc SET encounter_location=encounter_location_name(encounter_id);

DROP TEMPORARY TABLE IF EXISTS temp_obs;
create temporary table temp_obs
select o.obs_id, o.voided, o.obs_group_id, o.encounter_id, o.person_id, o.concept_id, o.value_coded, o.value_numeric,
       o.value_text,o.value_datetime, o.comments, o.date_created, o.obs_datetime
from obs o
inner join temp_enc t on t.encounter_id = o.encounter_id
where o.voided = 0;

create index temp_obs_encs_ei on temp_obs(encounter_id);
create index temp_obs_encs_eobs on temp_obs(encounter_id, obs_group_id);

-- vitals / measurements
UPDATE temp_enc t SET bp_systolic = obs_value_numeric_from_temp(encounter_id, 'CIEL','5085');
UPDATE temp_enc t SET bp_diastolic = obs_value_numeric_from_temp(encounter_id, 'CIEL','5086');
UPDATE temp_enc t SET respiratory_rate = obs_value_numeric_from_temp(encounter_id, 'CIEL','5242');
UPDATE temp_enc t SET o2_saturation = obs_value_numeric_from_temp(encounter_id, 'CIEL','5092');
UPDATE temp_enc t SET glucose = obs_value_numeric_from_temp(encounter_id, 'CIEL','1458');
UPDATE temp_enc t SET doctor_contacted = answer_exists_in_encounter_temp(encounter_id, 'PIH','20925','CIEL','1065');
UPDATE temp_enc t SET length_cm = obs_value_numeric_from_temp(encounter_id, 'CIEL','5090');
UPDATE temp_enc t SET head_circumference_cm = obs_value_numeric_from_temp(encounter_id, 'CIEL','5314');
UPDATE temp_enc t SET muac_cm = obs_value_numeric_from_temp(encounter_id, 'CIEL','1343');
UPDATE temp_enc t SET rbg = obs_value_numeric_from_temp(encounter_id, 'CIEL','887');
UPDATE temp_enc t SET umbilical_cord = obs_value_coded_list_from_temp(encounter_id, 'CIEL','162121','en');
UPDATE temp_enc t SET eyes = obs_value_coded_list_from_temp(encounter_id, 'CIEL','163309','en');
-- umbilical cord and eye comments share CIEL:168722 on the form (see SL-1486), so both are concatenated here
set @exam_comment = concept_from_mapping('CIEL','168722');
UPDATE temp_enc t SET umbilical_eye_comments =
    (select group_concat(o.value_text order by o.obs_id separator ' | ') from temp_obs o
     where o.encounter_id = t.encounter_id and o.concept_id = @exam_comment);
UPDATE temp_enc t SET skin_color = obs_value_coded_list_from_temp(encounter_id, 'CIEL','1120','en');
UPDATE temp_enc t SET skin_comments = obs_value_text_from_temp(encounter_id, 'CIEL','160981');
UPDATE temp_enc t SET urination = obs_value_coded_list_from_temp(encounter_id, 'CIEL','166358','en');
UPDATE temp_enc t SET urination_comments = obs_value_text_from_temp(encounter_id, 'CIEL','166363');
UPDATE temp_enc t SET stool = obs_value_coded_list_from_temp(encounter_id, 'CIEL','163640','en');
UPDATE temp_enc t SET stool_comments = obs_value_text_from_temp(encounter_id, 'CIEL','160965');
UPDATE temp_enc t SET neuro_exam = obs_value_coded_list_from_temp(encounter_id, 'CIEL','1129','en');
UPDATE temp_enc t SET seizures = obs_value_coded_as_boolean_from_temp(encounter_id, 'PIH','206');
UPDATE temp_enc t SET neuro_comments = obs_value_text_from_temp(encounter_id, 'PIH','11570');
UPDATE temp_enc t SET cardiac_exam = obs_value_coded_list_from_temp(encounter_id, 'CIEL','1124','en');
UPDATE temp_enc t SET cardiac_comments = obs_value_text_from_temp(encounter_id, 'CIEL','163046');

-- scores
UPDATE temp_enc t SET downes_score = obs_value_numeric_from_temp(encounter_id, 'PIH','21776');
UPDATE temp_enc t SET silverman_andersen_score = obs_value_numeric_from_temp(encounter_id, 'PIH','21777');
UPDATE temp_enc t SET thompson_hie_score = obs_value_numeric_from_temp(encounter_id, 'PIH','21779');

-- feeding / IV
UPDATE temp_enc t SET feeding_method = obs_value_coded_list_from_temp(encounter_id, 'CIEL','1151','en');
UPDATE temp_enc t SET feeding_route = obs_value_coded_list_from_temp(encounter_id, 'CIEL','168734','en');
UPDATE temp_enc t SET iv_access = answer_exists_in_encounter_temp(encounter_id, 'CIEL','165995','CIEL','1765');
UPDATE temp_enc t SET iv_placement_date = obs_value_datetime_from_temp(encounter_id, 'PIH','20289');
UPDATE temp_enc t SET iv_site = obs_value_coded_list_from_temp(encounter_id, 'CIEL','166006','en');
UPDATE temp_enc t SET days_with_iv = obs_value_numeric_from_temp(encounter_id, 'PIH','20290');
UPDATE temp_enc t SET ivf_type = obs_value_coded_list_from_temp(encounter_id, 'PIH','IVF administered','en');
UPDATE temp_enc t SET ivf_volume = obs_value_numeric_from_temp(encounter_id, 'CIEL','170482');

-- respiration
UPDATE temp_enc t SET air_supply = obs_value_coded_list_from_temp(encounter_id, 'CIEL','162739','en');
UPDATE temp_enc t SET o2_flow_rate = obs_value_numeric_from_temp(encounter_id, 'CIEL','165986');
UPDATE temp_enc t SET cpap_pressure = obs_value_numeric_from_temp(encounter_id, 'PIH','20357');
UPDATE temp_enc t SET fio2 = obs_value_numeric_from_temp(encounter_id, 'CIEL','165927');
UPDATE temp_enc t SET apnea = answer_exists_in_encounter_temp(encounter_id, 'PIH','DIAGNOSIS','CIEL','121519');
UPDATE temp_enc t SET apnea_duration = obs_value_numeric_from_temp(encounter_id, 'PIH','20460');
UPDATE temp_enc t SET neonatal_resuscitation = obs_value_coded_as_boolean_from_temp(encounter_id, 'CIEL','162131');
UPDATE temp_enc t SET resus_supplemental_oxygen = answer_exists_in_encounter_temp(encounter_id, 'CIEL','165995','CIEL','162738');
UPDATE temp_enc t SET resus_ventilation_bag = answer_exists_in_encounter_temp(encounter_id, 'CIEL','165995','CIEL','167383');
UPDATE temp_enc t SET resus_intubation = answer_exists_in_encounter_temp(encounter_id, 'CIEL','165995','CIEL','165935');
UPDATE temp_enc t SET resus_heart_massage = answer_exists_in_encounter_temp(encounter_id, 'CIEL','165995','CIEL','167415');
UPDATE temp_enc t SET days_with_respiratory_support = obs_value_numeric_from_temp(encounter_id, 'PIH','20291');
-- adrenaline (Newborn Daily Progress v1.0 only)
UPDATE temp_enc t SET adrenaline_administered = answer_exists_in_encounter_temp(encounter_id, 'PIH','12603','CIEL','154365');
UPDATE temp_enc t SET adrenaline_dosing = obs_comments_from_temp(encounter_id, 'PIH','12603','CIEL','154365');

-- blood / transfusion
UPDATE temp_enc t SET transfusion_given = obs_value_coded_as_boolean_from_temp(encounter_id, 'PIH','Transfusion status');
UPDATE temp_enc t SET transfusion_type = obs_value_coded_list_from_temp(encounter_id, 'PIH','20464','en');
UPDATE temp_enc t SET transfusion_reaction = answer_exists_in_encounter_temp(encounter_id, 'PIH','DIAGNOSIS','CIEL','147119');

-- each blood product and its volume sit together in a Transfusion construct obsgroup
set @transfusion_of_fluid = concept_from_mapping('PIH','Transfusion of fluid');
set @transfusion_volume   = concept_from_mapping('CIEL','166650');
set @whole_blood          = concept_from_mapping('PIH','Whole blood');
set @prbc                 = concept_from_mapping('PIH','Packed red blood cells');
set @plasma               = concept_from_mapping('PIH','Plasma');
set @platelets            = concept_from_mapping('PIH','Platelets');

DROP TEMPORARY TABLE IF EXISTS temp_transfusion;
create temporary table temp_transfusion
(
    encounter_id int,
    obs_group_id int,
    product      int,
    volume       double
);
insert into temp_transfusion (encounter_id, obs_group_id, product)
select encounter_id, obs_group_id, value_coded
from temp_obs
where concept_id = @transfusion_of_fluid;

UPDATE temp_transfusion tt SET volume =
    (select o.value_numeric from temp_obs o
     where o.obs_group_id = tt.obs_group_id and o.concept_id = @transfusion_volume
     order by o.obs_id desc limit 1);

UPDATE temp_enc t SET whole_blood_transfusion = IF(EXISTS(select 1 from temp_transfusion tt where tt.encounter_id = t.encounter_id and tt.product = @whole_blood), 1, 0);
UPDATE temp_enc t SET prbc_transfusion        = IF(EXISTS(select 1 from temp_transfusion tt where tt.encounter_id = t.encounter_id and tt.product = @prbc), 1, 0);
UPDATE temp_enc t SET plasma_transfusion      = IF(EXISTS(select 1 from temp_transfusion tt where tt.encounter_id = t.encounter_id and tt.product = @plasma), 1, 0);
UPDATE temp_enc t SET platelet_transfusion    = IF(EXISTS(select 1 from temp_transfusion tt where tt.encounter_id = t.encounter_id and tt.product = @platelets), 1, 0);
UPDATE temp_enc t SET whole_blood_volume = (select sum(tt.volume) from temp_transfusion tt where tt.encounter_id = t.encounter_id and tt.product = @whole_blood);
UPDATE temp_enc t SET prbc_volume        = (select sum(tt.volume) from temp_transfusion tt where tt.encounter_id = t.encounter_id and tt.product = @prbc);
UPDATE temp_enc t SET plasma_volume      = (select sum(tt.volume) from temp_transfusion tt where tt.encounter_id = t.encounter_id and tt.product = @plasma);
UPDATE temp_enc t SET platelet_volume    = (select sum(tt.volume) from temp_transfusion tt where tt.encounter_id = t.encounter_id and tt.product = @platelets);

-- outputs / plan
UPDATE temp_enc t SET urine_output = obs_value_numeric_from_temp(encounter_id, 'PIH','21114');
UPDATE temp_enc t SET estimated_blood_loss = obs_value_numeric_from_temp(encounter_id, 'PIH','12555');
UPDATE temp_enc t SET surgery_recommended = obs_value_coded_as_boolean_from_temp(encounter_id, 'CIEL','164258');
UPDATE temp_enc t SET weight = obs_value_numeric_from_temp(encounter_id, 'CIEL','5089');
UPDATE temp_enc t SET temperature = obs_value_numeric_from_temp(encounter_id, 'CIEL','5088');
UPDATE temp_enc t SET heart_rate = obs_value_numeric_from_temp(encounter_id, 'CIEL','5087');
UPDATE temp_enc t SET eye_drops = answer_exists_in_encounter(encounter_id, 'CIEL','1651','CIEL','168724');
UPDATE temp_enc t SET umbilical_cord_care = answer_exists_in_encounter(encounter_id, 'CIEL','1651','CIEL','168725');
UPDATE temp_enc t SET vitamin_k = answer_exists_in_encounter(encounter_id, 'PIH','SUPPLEMENT RECEIVED','CIEL','86352');
UPDATE temp_enc t SET vitamin_d = answer_exists_in_encounter_temp(encounter_id, 'PIH','SUPPLEMENT RECEIVED','CIEL','105310');
UPDATE temp_enc t SET treatment_plan = obs_value_text_from_temp(encounter_id, 'CIEL','163104');
UPDATE temp_enc t SET overall_condition = obs_value_coded_list_from_temp(encounter_id, 'CIEL','160116','en');
-- the Diagnoses and Summary sections both save to CIEL:161011 (see SL-1487), so both are concatenated here
set @summary_notes = concept_from_mapping('CIEL','161011');
UPDATE temp_enc t SET summary_notes =
    (select group_concat(o.value_text order by o.obs_id separator ' | ') from temp_obs o
     where o.encounter_id = t.encounter_id and o.concept_id = @summary_notes);
UPDATE temp_enc t SET remarks = obs_value_text_from_temp(encounter_id, 'PIH','10637');
UPDATE temp_enc t SET disposition = obs_value_coded_list_from_temp(encounter_id, 'PIH','8620','en');
UPDATE temp_enc t SET transfer_in_location_newborn = obs_value_coded_list_from_temp(encounter_id, 'PIH','15175','en'); -- transferWithinHospitalNewborn
UPDATE temp_enc t SET transfer_in_location = obs_value_coded_list_from_temp(encounter_id, 'PIH','14973','en'); -- transferWithinHospital
UPDATE temp_enc t SET transfer_out_location_newborn = obs_value_coded_list_from_temp(encounter_id, 'PIH','15177','en'); -- transferOutOfHospitalNewborn
UPDATE temp_enc t SET transfer_out_location = obs_value_coded_list_from_temp(encounter_id, 'PIH','14424','en'); -- transferOutOfHospital
UPDATE temp_enc t SET transfer_location = COALESCE(transfer_in_location_newborn, transfer_out_location_newborn, transfer_in_location, transfer_out_location);
UPDATE temp_enc t SET death_date = obs_value_datetime_from_temp(encounter_id, 'PIH','14399');

SELECT
    concat(@partition, '-', encounter_id) as encounter_id,
    concat(@partition, '-', visit_id) as visit_id,
    concat(@partition, '-', patient_id) as patient_id,
    emr_id,
    encounter_datetime,
    encounter_location,
    datetime_entered,
    user_entered,
    provider,
    visit_type,
    bp_systolic,
    bp_diastolic,
    respiratory_rate,
    o2_saturation,
    glucose,
    doctor_contacted,
    length_cm,
    head_circumference_cm,
    muac_cm,
    rbg,
    umbilical_cord,
    eyes,
    umbilical_eye_comments,
    skin_color,
    skin_comments,
    urination,
    urination_comments,
    stool,
    stool_comments,
    neuro_exam,
    seizures,
    neuro_comments,
    cardiac_exam,
    cardiac_comments,
    downes_score,
    silverman_andersen_score,
    thompson_hie_score,
    feeding_method,
    feeding_route,
    iv_access,
    iv_placement_date,
    iv_site,
    days_with_iv,
    ivf_type,
    ivf_volume,
    air_supply,
    o2_flow_rate,
    cpap_pressure,
    fio2,
    apnea,
    apnea_duration,
    neonatal_resuscitation,
    resus_supplemental_oxygen,
    resus_ventilation_bag,
    resus_intubation,
    resus_heart_massage,
    days_with_respiratory_support,
    adrenaline_administered,
    adrenaline_dosing,
    transfusion_given,
    transfusion_type,
    whole_blood_transfusion,
    whole_blood_volume,
    prbc_transfusion,
    prbc_volume,
    plasma_transfusion,
    plasma_volume,
    platelet_transfusion,
    platelet_volume,
    transfusion_reaction,
    urine_output,
    estimated_blood_loss,
    surgery_recommended,
    weight,
    temperature,
    heart_rate,
    eye_drops,
    umbilical_cord_care,
    vitamin_k,
    vitamin_d,
    treatment_plan,
    overall_condition,
    summary_notes,
    remarks,
    disposition,
    transfer_location,
    death_date,
    index_asc,
    index_desc
FROM temp_enc;
