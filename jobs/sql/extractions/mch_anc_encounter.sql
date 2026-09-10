set @partition = '${partitionNum}';

SELECT encounter_type_id  INTO @anc_init
FROM encounter_type et WHERE uuid='00e5e810-90ec-11e8-9eb6-529269fb1459';

SELECT encounter_type_id  INTO @anc_followup
FROM encounter_type et WHERE uuid='00e5e946-90ec-11e8-9eb6-529269fb1459';

set @pregnancyProgramId = program('Pregnancy');

drop temporary table if exists temp_anc_encs;
create temporary table temp_anc_encs
(
    patient_id                               int,
    emr_id                                   varchar(255),
    encounter_id                             int,
    visit_id                                 int,
    pregnancy_program_id                     int,
    encounter_datetime                       datetime,
    encounter_location                       varchar(255),
    datetime_entered                         datetime,
    user_entered                             varchar(255),
    provider                                 varchar(255),
    visit_type                               varchar(255),
    age_at_encounter                         int,
    trimester_enrolled                       varchar(255),
    number_anc_visit                         int,
    birth_weight_other_babies                varchar(255),
    danger_signs                             text,
    high_risk_factors                        text,
    other_risk_factors                       text,
    prior_neonatal_deaths                    int,
    prior_stillbirths                        int,
    gravida                                  int,
    parity                                   int,
    abortus                                  int,
    living                                   int,
    last_menstruation_date                   date,
    estimated_delivery_date                  date,
    estimated_gestational_age                int,
    return_visit_date                        date,
    height                                   decimal(8, 2),
    weight                                   decimal(8, 2),
    bp_systolic                              int,
    bp_diastolic                             int,
    fundal_height                            numeric(8, 2),
    fetal_heart_rate                         int,
    blood_type                               varchar(255),
    urine_glucose                            varchar(255),
    urine_protein                            varchar(255),
    ferrous_sulfate_folic_acid               boolean,
    hiv_rapid_test_obs_id                    int,
    hiv_rapid_test_obs_group_id              int,
    hiv_rapid_test_result                    varchar(255),
    hiv_rapid_test_reason_not_performed      varchar(255),
    syphilis_rapid_test_obs_id               int,
    syphilis_rapid_test_obs_group_id         int,
    syphilis_rapid_test_result               varchar(255),
    syphilis_rapid_test_reason_not_performed varchar(255),
    hep_b_test_result                        varchar(255),
    iptp_sp_malaria                          boolean,
    nutrition_counseling                     boolean,
    hiv_counsel_and_test                     boolean,
    smokes_tobacco                           varchar(255),
    drinks_alcohol                           varchar(255),
    drinks_per_day                           int,
    uses_drugs                               varchar(255),
    drug_name                                varchar(255),
    albendazole                              boolean,
    malaria_rdt                              varchar(255),
    counseled_danger_signs                   boolean,
    llin                                     boolean,
    maternal_waiting_home                    varchar(255),
    latest_entered_number_anc_visit          INT,
    actual_visit_number                      INT,
    index_asc                                INT,
    index_desc                               INT,
    index_asc_patient_program                INT,
    index_desc_patient_program               INT
);

insert into temp_anc_encs(patient_id, encounter_id, visit_id, encounter_datetime,
datetime_entered, user_entered, visit_type)
select patient_id, encounter_id, visit_id, encounter_datetime, date_created, creator, encounter_type_name_from_id(encounter_type)
from encounter e
where e.voided = 0
AND encounter_type IN (@anc_followup, @anc_init)
ORDER BY encounter_datetime desc;

create index temp_labor_encs_ei on temp_anc_encs(encounter_id);
create index temp_anc_encs_c1 on temp_anc_encs(patient_id, pregnancy_program_id,encounter_datetime);

UPDATE temp_anc_encs
set user_entered = person_name_of_user(user_entered);

UPDATE temp_anc_encs
SET provider = provider(encounter_id);

UPDATE temp_anc_encs t
SET emr_id = patient_identifier(patient_id, metadata_uuid('org.openmrs.module.emrapi', 'emr.primaryIdentifierType'));

UPDATE temp_anc_encs
SET encounter_location=encounter_location_name(encounter_id);

update temp_anc_encs
set pregnancy_program_id = patient_program_id_from_encounter(patient_id, @pregnancyProgramId ,encounter_id);

update temp_anc_encs 
set age_at_encounter = age_at_enc(patient_id, encounter_id);

DROP TEMPORARY TABLE IF EXISTS temp_obs;
create temporary table temp_obs
select o.obs_id, o.voided ,o.obs_group_id , o.encounter_id, o.person_id, o.concept_id, o.value_coded, o.value_numeric,
o.value_text,o.value_datetime, o.comments, o.date_created, o.obs_datetime
from obs o
inner join temp_anc_encs t on t.encounter_id = o.encounter_id
where o.voided = 0;

create index temp_obs_encs_ei on temp_obs(encounter_id);
create index temp_obs_encs_eobs on temp_obs(encounter_id, obs_group_id);

SET @abortus = concept_from_mapping('PIH','7012');
SET @albendazole = concept_from_mapping('PIH','10570');
SET @birth_weight_other_babies = concept_from_mapping('PIH','20072');
SET @blood_type = concept_from_mapping('PIH','300');
SET @bp_diastolic = concept_from_mapping('PIH','5086');
SET @bp_systolic = concept_from_mapping('PIH','5085');
SET @counseled_danger_signs = concept_from_mapping('PIH','12750');
SET @danger_signs = concept_from_mapping('PIH','3064');
SET @drinks_alcohol = concept_from_mapping('PIH','1552');
SET @drinks_per_day = concept_from_mapping('PIH','2246');
SET @drug_name = concept_from_mapping('PIH','6489');
SET @estimated_delivery_date = concept_from_mapping('PIH','5596');
SET @estimated_gestational_age = concept_from_mapping('PIH','1279');
SET @ferrous_sulfate_folic_acid = concept_from_mapping('PIH','20073');
SET @fetal_heart_rate = concept_from_mapping('PIH','13199');
SET @fundal_height = concept_from_mapping('PIH','13028');
SET @gravida = concept_from_mapping('PIH','5624');
SET @height = concept_from_mapping('PIH','5090');
SET @high_risk_factors = concept_from_mapping('PIH','11673');
SET @hiv_counsel_and_test = concept_from_mapping('PIH','11381');
SET @hiv_rapid_test_result = concept_from_mapping('CIEL','163722');
SET @hiv_rapid_test_reason_not_performed = concept_from_mapping('CIEL','165182');
SET @syphilis_rapid_test_result = concept_from_mapping('CIEL','165303');
SET @syphilis_rapid_test_reason_not_performed = concept_from_mapping('CIEL','165182');
SET @hep_b_test_result = concept_from_mapping('CIEL','159430');
SET @iptp_sp_malaria = concept_from_mapping('PIH','20074');
SET @last_menstruation_date = concept_from_mapping('PIH','968');
SET @living = concept_from_mapping('PIH','11117');
SET @llin = concept_from_mapping('PIH','13053');
SET @malaria_rdt = concept_from_mapping('PIH','11464');
SET @number_anc_visit = concept_from_mapping('PIH','13321');
SET @nutrition_counseling = concept_from_mapping('PIH','12878');
SET @parity = concept_from_mapping('PIH','1053');
SET @prior_neonatal_deaths = concept_from_mapping('PIH','13241');
SET @prior_stillbirths = concept_from_mapping('PIH','13240');
SET @return_visit_date = concept_from_mapping('PIH','5096');
SET @smokes_tobacco = concept_from_mapping('PIH','2545');
SET @trimester_enrolled = concept_from_mapping('PIH','11661');
SET @urine_glucose = concept_from_mapping('PIH','12292');
SET @urine_protein = concept_from_mapping('PIH','12272');
SET @uses_drugs = concept_from_mapping('PIH','2546');
SET @weight = concept_from_mapping('PIH','5089');
SET @mwh = concept_from_mapping('PIH','20930');
SET @yes = concept_from_mapping('PIH', '1065');
SET @no  = concept_from_mapping('PIH', '1066');

DROP TEMPORARY TABLE IF EXISTS temp_obs_pivoted;
CREATE TEMPORARY TABLE temp_obs_pivoted
SELECT
    encounter_id,
    max(case when concept_id = @abortus then value_numeric end) "abortus",
    max(case when concept_id = @albendazole then if(value_coded = @yes, 1, if(value_coded = @no, 0, null)) end) "albendazole",
    group_concat(distinct case when concept_id = @birth_weight_other_babies then concept_name(value_coded, @locale) end separator '| ') "birth_weight_other_babies",
    group_concat(distinct case when concept_id = @blood_type then concept_name(value_coded, @locale) end separator '| ') "blood_type",
    max(case when concept_id = @bp_diastolic then value_numeric end) "bp_diastolic",
    max(case when concept_id = @bp_systolic then value_numeric end) "bp_systolic",
    max(case when concept_id = @counseled_danger_signs then if(value_coded = @yes, 1, if(value_coded = @no, 0, null)) end) "counseled_danger_signs",
    group_concat(distinct case when concept_id = @danger_signs then concept_name(value_coded, @locale) end separator '| ') "danger_signs",
    group_concat(distinct case when concept_id = @drinks_alcohol then concept_name(value_coded, @locale) end separator '| ') "drinks_alcohol",
    max(case when concept_id = @drinks_per_day then value_numeric end) "drinks_per_day",
    max(case when concept_id = @drug_name then value_text end) "drug_name",
    max(case when concept_id = @estimated_delivery_date then value_datetime end) "estimated_delivery_date",
    max(case when concept_id = @estimated_gestational_age then value_numeric end) "estimated_gestational_age",
    max(case when concept_id = @ferrous_sulfate_folic_acid then if(value_coded = @yes, 1, if(value_coded = @no, 0, null)) end) "ferrous_sulfate_folic_acid",
    max(case when concept_id = @fetal_heart_rate then value_numeric end) "fetal_heart_rate",
    max(case when concept_id = @fundal_height then value_numeric end) "fundal_height",
    max(case when concept_id = @gravida then value_numeric end) "gravida",
    max(case when concept_id = @height then value_numeric end) "height",
    group_concat(distinct case when concept_id = @high_risk_factors then concept_name(value_coded, @locale) end separator '| ') "high_risk_factors",
    max(case when concept_id = @hiv_counsel_and_test then if(value_coded = @yes, 1, if(value_coded = @no, 0, null)) end) "hiv_counsel_and_test",
    -- HIV rapid test obs_id/group_id kept as post-pivot UPDATEs below
    max(case when concept_id = @hiv_rapid_test_result then obs_id end) "hiv_rapid_test_obs_id",
    max(case when concept_id = @hiv_rapid_test_result then concept_name(value_coded, @locale) end) "hiv_rapid_test_result",
    -- Syphilis rapid test obs_id/group_id kept as post-pivot UPDATEs below
    max(case when concept_id = @syphilis_rapid_test_result then obs_id end) "syphilis_rapid_test_obs_id",
    max(case when concept_id = @syphilis_rapid_test_result then concept_name(value_coded, @locale) end) "syphilis_rapid_test_result",
    group_concat(distinct case when concept_id = @hep_b_test_result then concept_name(value_coded, @locale) end separator '| ') "hep_b_test_result",
    max(case when concept_id = @iptp_sp_malaria then if(value_coded = @yes, 1, if(value_coded = @no, 0, null)) end) "iptp_sp_malaria",
    max(case when concept_id = @last_menstruation_date then value_datetime end) "last_menstruation_date",
    max(case when concept_id = @living then value_numeric end) "living",
    max(case when concept_id = @llin then if(value_coded = @yes, 1, if(value_coded = @no, 0, null)) end) "llin",
    group_concat(distinct case when concept_id = @malaria_rdt then concept_name(value_coded, @locale) end separator '| ') "malaria_rdt",
    max(case when concept_id = @number_anc_visit then value_numeric end) "number_anc_visit",
    max(case when concept_id = @nutrition_counseling then if(value_coded = @yes, 1, if(value_coded = @no, 0, null)) end) "nutrition_counseling",
    max(case when concept_id = @parity then value_numeric end) "parity",
    max(case when concept_id = @prior_neonatal_deaths then value_numeric end) "prior_neonatal_deaths",
    max(case when concept_id = @prior_stillbirths then value_numeric end) "prior_stillbirths",
    max(case when concept_id = @return_visit_date then value_datetime end) "return_visit_date",
    group_concat(distinct case when concept_id = @smokes_tobacco then concept_name(value_coded, @locale) end separator '| ') "smokes_tobacco",
    group_concat(distinct case when concept_id = @trimester_enrolled then concept_name(value_coded, @locale) end separator '| ') "trimester_enrolled",
    group_concat(distinct case when concept_id = @urine_glucose then concept_name(value_coded, @locale) end separator '| ') "urine_glucose",
    group_concat(distinct case when concept_id = @urine_protein then concept_name(value_coded, @locale) end separator '| ') "urine_protein",
    group_concat(distinct case when concept_id = @uses_drugs then concept_name(value_coded, @locale) end separator '| ') "uses_drugs",
    max(case when concept_id = @weight then value_numeric end) "weight",
    group_concat(distinct case when concept_id = @mwh then concept_name(value_coded, @locale) end separator '| ') "maternal_waiting_home"
FROM temp_obs
GROUP BY encounter_id;
ALTER TABLE temp_obs_pivoted
    ADD COLUMN hiv_rapid_test_obs_group_id int,
    ADD COLUMN hiv_rapid_test_reason_not_performed varchar(255),
    ADD COLUMN syphilis_rapid_test_obs_group_id int,
    ADD COLUMN syphilis_rapid_test_reason_not_performed varchar(255),
    ADD COLUMN other_risk_factors varchar(255);

-- obs_group lookups can't be pivoted; kept as UPDATEs
UPDATE temp_obs_pivoted SET hiv_rapid_test_obs_group_id = obs_group_id_from_obs(hiv_rapid_test_obs_id);
UPDATE temp_obs_pivoted SET hiv_rapid_test_reason_not_performed = obs_from_group_id_value_coded_list_using_concept_id(hiv_rapid_test_obs_group_id, @hiv_rapid_test_reason_not_performed, 'en');
UPDATE temp_obs_pivoted SET syphilis_rapid_test_obs_group_id = obs_group_id_from_obs(syphilis_rapid_test_obs_id);
UPDATE temp_obs_pivoted SET syphilis_rapid_test_reason_not_performed = obs_from_group_id_value_coded_list_using_concept_id(syphilis_rapid_test_obs_group_id, @syphilis_rapid_test_reason_not_performed, 'en');
UPDATE temp_obs_pivoted SET other_risk_factors = obs_comments_from_temp(encounter_id, 'PIH','11673','PIH','5622');

ALTER TABLE temp_obs_pivoted ADD INDEX (encounter_id);

UPDATE temp_anc_encs t
INNER JOIN temp_obs_pivoted c ON c.encounter_id = t.encounter_id
SET
    t.abortus = c.abortus,
    t.albendazole = c.albendazole,
    t.birth_weight_other_babies = c.birth_weight_other_babies,
    t.blood_type = c.blood_type,
    t.bp_diastolic = c.bp_diastolic,
    t.bp_systolic = c.bp_systolic,
    t.counseled_danger_signs = c.counseled_danger_signs,
    t.danger_signs = c.danger_signs,
    t.drinks_alcohol = c.drinks_alcohol,
    t.drinks_per_day = c.drinks_per_day,
    t.drug_name = c.drug_name,
    t.estimated_delivery_date = c.estimated_delivery_date,
    t.estimated_gestational_age = c.estimated_gestational_age,
    t.ferrous_sulfate_folic_acid = c.ferrous_sulfate_folic_acid,
    t.fetal_heart_rate = c.fetal_heart_rate,
    t.fundal_height = c.fundal_height,
    t.gravida = c.gravida,
    t.height = c.height,
    t.high_risk_factors = c.high_risk_factors,
    t.hiv_counsel_and_test = c.hiv_counsel_and_test,
    t.hiv_rapid_test_obs_id = c.hiv_rapid_test_obs_id,
    t.hiv_rapid_test_obs_group_id = c.hiv_rapid_test_obs_group_id,
    t.hiv_rapid_test_result = c.hiv_rapid_test_result,
    t.hiv_rapid_test_reason_not_performed = c.hiv_rapid_test_reason_not_performed,
    t.syphilis_rapid_test_obs_id = c.syphilis_rapid_test_obs_id,
    t.syphilis_rapid_test_obs_group_id = c.syphilis_rapid_test_obs_group_id,
    t.syphilis_rapid_test_result = c.syphilis_rapid_test_result,
    t.syphilis_rapid_test_reason_not_performed = c.syphilis_rapid_test_reason_not_performed,
    t.hep_b_test_result = c.hep_b_test_result,
    t.iptp_sp_malaria = c.iptp_sp_malaria,
    t.last_menstruation_date = c.last_menstruation_date,
    t.living = c.living,
    t.llin = c.llin,
    t.malaria_rdt = c.malaria_rdt,
    t.number_anc_visit = c.number_anc_visit,
    t.nutrition_counseling = c.nutrition_counseling,
    t.parity = c.parity,
    t.prior_neonatal_deaths = c.prior_neonatal_deaths,
    t.prior_stillbirths = c.prior_stillbirths,
    t.return_visit_date = c.return_visit_date,
    t.smokes_tobacco = c.smokes_tobacco,
    t.trimester_enrolled = c.trimester_enrolled,
    t.urine_glucose = c.urine_glucose,
    t.urine_protein = c.urine_protein,
    t.uses_drugs = c.uses_drugs,
    t.weight = c.weight,
    t.other_risk_factors = c.other_risk_factors,
    t.maternal_waiting_home = c.maternal_waiting_home;

-- calculate actual visit count
DROP temporary table if exists temp_visit_counts;
CREATE temporary table temp_visit_counts
SELECT encounter_id, patient_id, pregnancy_program_id, number_anc_visit, encounter_datetime, visit_type
from temp_anc_encs t;

create index temp_visit_counts_ei on temp_visit_counts(encounter_id);

DROP temporary table if exists temp_visit_counts_dup;
CREATE temporary table temp_visit_counts_dup
select * from temp_visit_counts
where visit_type = 'ANC Intake';

create index temp_visit_counts_dup_c1 on temp_visit_counts_dup(patient_id, pregnancy_program_id,encounter_datetime);

UPDATE temp_anc_encs t
inner join temp_visit_counts vc on vc.encounter_id =
	(select encounter_id from temp_visit_counts_dup vc2
	where vc2.patient_id = t.patient_id
	and ifnull(vc2.pregnancy_program_id, 9999999) = ifnull(t.pregnancy_program_id, 9999999)
	and (number_anc_visit is not null and number_anc_visit > 0) 
	and vc2.encounter_datetime <= t.encounter_datetime
	order by encounter_datetime desc, encounter_id desc
	limit 1)
SET latest_entered_number_anc_visit = vc.number_anc_visit;	

DROP temporary table if exists temp_actual_visit_count;
CREATE TEMPORARY TABLE temp_actual_visit_count AS
SELECT
    t.encounter_id,
    COUNT(vc.encounter_id) AS visit_count
FROM temp_anc_encs t
INNER JOIN temp_visit_counts vc
    ON vc.patient_id = t.patient_id
    AND (vc.pregnancy_program_id = t.pregnancy_program_id
         OR (vc.pregnancy_program_id IS NULL AND t.pregnancy_program_id IS NULL))
    AND vc.encounter_datetime <= t.encounter_datetime
GROUP BY t.encounter_id;

ALTER TABLE temp_actual_visit_count ADD INDEX (encounter_id);

UPDATE temp_anc_encs t
INNER JOIN temp_actual_visit_count avc ON avc.encounter_id = t.encounter_id
SET t.actual_visit_number = IFNULL(t.latest_entered_number_anc_visit, 1) - 1 + avc.visit_count;

SELECT
concat(@partition,"-",patient_id) as patient_id,
emr_id,
concat(@partition,"-",encounter_id) as encounter_id,
concat(@partition,"-",visit_id)  as visit_id,
concat(@partition,"-",pregnancy_program_id)  as pregnancy_program_id,
encounter_datetime,
encounter_location,
datetime_entered,
user_entered,
provider,
age_at_encounter,
visit_type,
trimester_enrolled,
number_anc_visit,
birth_weight_other_babies,
danger_signs,
high_risk_factors,
other_risk_factors,
prior_neonatal_deaths,
prior_stillbirths,
gravida,
parity,
abortus,
living,
last_menstruation_date,
estimated_delivery_date,
estimated_gestational_age,
return_visit_date,
height,
weight,
bp_systolic,
bp_diastolic,
fundal_height,
fetal_heart_rate,
blood_type,
urine_glucose,
urine_protein,
ferrous_sulfate_folic_acid,
iptp_sp_malaria,
hiv_rapid_test_result,
hiv_rapid_test_reason_not_performed,
syphilis_rapid_test_result,
syphilis_rapid_test_reason_not_performed,
hep_b_test_result,
nutrition_counseling,
hiv_counsel_and_test,
smokes_tobacco,
drinks_alcohol,
drinks_per_day,
uses_drugs,
drug_name,
albendazole,
malaria_rdt,
counseled_danger_signs,
llin,
maternal_waiting_home,
actual_visit_number,
index_asc,
index_desc,
index_asc_patient_program,
index_desc_patient_program
FROM temp_anc_encs;
