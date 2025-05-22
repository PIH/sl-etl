set @partition = '${partitionNum}';
select encounter_type_id  into @labor_enc
from encounter_type et where uuid='ac5ec970-31b7-4659-9141-284bfbc13c69';
set @pregnancyProgramId = program('Pregnancy');

drop temporary table if exists temp_labor_encs;
create temporary table temp_labor_encs
(
patient_id 			int,
emr_id				varchar(255),
encounter_id        int,
visit_id            int,
encounter_datetime datetime,
encounter_location varchar(255),
datetime_entered datetime,
user_entered     varchar(255),
provider             varchar(255),
pregnancy_program_id varchar(50),
admission_date datetime,
gravida INT,
partiy INT,
gestational_age decimal(5,2),
gestational_age_source varchar(255),
temperature decimal,
heart_rate INT,
bp_systolic INT,
bp_diastolic INT,
respiratory_rate INT,
o2_saturation INT,
pregnancy_complications text,
labor_start datetime,
membranes_status varchar(255),
membrane_rupture_date datetime,
membrane_color varchar(255),
meconium_classification varchar(255),
fundal_height decimal,
uc_status varchar(255),
fetal_heart_rate_method varchar(255),
fhr1 INT,
fhr2 INT,
fhr3 INT,
fhr4 INT,
fhr5 INT,
induced_labor varchar(5),
induction_time datetime,
method_of_induction varchar(255),
palpation_of_abdomen varchar(255),
previous_abdominal_scar varchar(5),
number_previous_csections INT,
overall_condition varchar(255),
disposition varchar(255),
transfer_in varchar(255),
transfer_out varchar(255),
transfer_location varchar(255),
death_date datetime,
partogram_uploaded varchar(255),
index_asc INT,
index_desc INT
);

insert into temp_labor_encs(patient_id, encounter_id, visit_id, encounter_datetime, 
datetime_entered, user_entered)
select patient_id, encounter_id, visit_id, encounter_datetime, date_created, creator
from encounter e
where e.voided = 0
AND encounter_type IN (@labor_enc)
ORDER BY encounter_datetime desc;

create index temp_labor_encs_ei on temp_labor_encs(encounter_id);


UPDATE temp_labor_encs
set user_entered = person_name_of_user(user_entered);

UPDATE temp_labor_encs
SET provider = provider(encounter_id);

UPDATE temp_labor_encs t
SET emr_id = patient_identifier(patient_id, 'c09a1d24-7162-11eb-8aa6-0242ac110002');

UPDATE temp_labor_encs
SET encounter_location=encounter_location_name(encounter_id);

update temp_labor_encs
set pregnancy_program_id = patient_program_id_from_encounter(patient_id, @pregnancyProgramId ,encounter_id);


DROP TEMPORARY TABLE IF EXISTS temp_obs;
create temporary table temp_obs 
select o.obs_id, o.voided ,o.obs_group_id , o.encounter_id, o.person_id, o.concept_id, o.value_coded, o.value_numeric, 
o.value_text,o.value_datetime, o.comments, o.date_created, o.obs_datetime
from obs o
inner join temp_labor_encs t on t.encounter_id = o.encounter_id
where o.voided = 0;


UPDATE temp_labor_encs
SET admission_date=obs_value_datetime_from_temp(encounter_id, 'PIH','12240');
UPDATE temp_labor_encs
SET gravida=obs_value_numeric_from_temp(encounter_id, 'PIH','5624');
UPDATE temp_labor_encs
SET partiy=obs_value_numeric_from_temp(encounter_id, 'PIH','1053');
UPDATE temp_labor_encs
SET gestational_age=obs_value_numeric_from_temp(encounter_id, 'PIH','14390');
UPDATE temp_labor_encs
SET gestational_age_source=obs_value_coded_list_from_temp(encounter_id, 'PIH','15090','en');
UPDATE temp_labor_encs
SET temperature=obs_value_numeric_from_temp(encounter_id, 'PIH','5088');
UPDATE temp_labor_encs
SET heart_rate=obs_value_numeric_from_temp(encounter_id, 'PIH','5087');
UPDATE temp_labor_encs
SET bp_systolic=obs_value_numeric_from_temp(encounter_id, 'PIH','5085');
UPDATE temp_labor_encs
SET bp_diastolic=obs_value_numeric_from_temp(encounter_id, 'PIH','5086');
UPDATE temp_labor_encs
SET respiratory_rate=obs_value_numeric_from_temp(encounter_id, 'PIH','5242');
UPDATE temp_labor_encs
SET o2_saturation=obs_value_numeric_from_temp(encounter_id, 'PIH','5092');


UPDATE temp_labor_encs
SET pregnancy_complications=obs_value_coded_list_from_temp(encounter_id, 'PIH','6644','en');
UPDATE temp_labor_encs
SET labor_start=obs_value_datetime_from_temp(encounter_id, 'PIH','14377');
UPDATE temp_labor_encs
SET membranes_status=obs_value_coded_list_from_temp(encounter_id, 'PIH','13549','en');
UPDATE temp_labor_encs
SET membrane_rupture_date=obs_value_datetime_from_temp(encounter_id, 'PIH','15092');
UPDATE temp_labor_encs
SET membrane_color=obs_value_coded_list_from_temp(encounter_id, 'PIH','15111','en');
UPDATE temp_labor_encs
SET meconium_classification=obs_value_coded_list_from_temp(encounter_id, 'PIH','15110','en');

UPDATE temp_labor_encs
SET fundal_height=obs_value_numeric_from_temp(encounter_id, 'PIH','13028');
UPDATE temp_labor_encs
SET uc_status=obs_value_coded_list_from_temp(encounter_id, 'PIH','13215','en');
UPDATE temp_labor_encs
SET fetal_heart_rate_method=obs_value_coded_list_from_temp(encounter_id, 'PIH','15095','en');

DROP TEMPORARY TABLE IF EXISTS temp_fhr_index_asc;
CREATE TEMPORARY TABLE temp_fhr_index_asc
(
    SELECT
            encounter_id,
            obs_group_id,
            value_numeric,
            index_asc
FROM (SELECT
            @r:= IF(@u = encounter_id, @r + 1,1) index_asc,
            encounter_id,
            obs_group_id,
            value_numeric,
            @u:= encounter_id
      FROM temp_obs AS t,
                    (SELECT @r:= 1) AS r,
                    (SELECT @u:= 0) AS u
      WHERE t.concept_id=concept_from_mapping('PIH','13199')
            ORDER BY encounter_id, obs_group_id ASC
        ) index_ascending );

update temp_labor_encs t
inner join temp_fhr_index_asc tvia on tvia.encounter_id = t.encounter_id
set t.fhr1 = tvia.value_numeric
WHERE tvia.index_asc=1;

update temp_labor_encs t
inner join temp_fhr_index_asc tvia on tvia.encounter_id = t.encounter_id
set t.fhr2 = tvia.value_numeric
WHERE tvia.index_asc=2;

update temp_labor_encs t
inner join temp_fhr_index_asc tvia on tvia.encounter_id = t.encounter_id
set t.fhr3 = tvia.value_numeric
WHERE tvia.index_asc=3;


update temp_labor_encs t
inner join temp_fhr_index_asc tvia on tvia.encounter_id = t.encounter_id
set t.fhr4 = tvia.value_numeric
WHERE tvia.index_asc=4;

UPDATE temp_labor_encs
SET induced_labor =obs_value_coded_list_from_temp(encounter_id, 'PIH','15113','en');
UPDATE temp_labor_encs
SET induction_time=obs_value_datetime_from_temp(encounter_id, 'PIH','15116');
UPDATE temp_labor_encs
SET method_of_induction=obs_value_coded_list_from_temp(encounter_id, 'PIH','15114','en');
UPDATE temp_labor_encs
SET palpation_of_abdomen=obs_value_coded_list_from_temp(encounter_id, 'PIH','14049','en');
UPDATE temp_labor_encs
SET previous_abdominal_scar=obs_value_coded_list_from_temp(encounter_id, 'PIH','15140','en');
UPDATE temp_labor_encs
SET number_previous_csections=obs_value_numeric_from_temp(encounter_id, 'PIH','7011');

UPDATE temp_labor_encs
SET overall_condition=obs_value_coded_list_from_temp(encounter_id, 'PIH','1463','en');
UPDATE temp_labor_encs
SET disposition=obs_value_coded_list_from_temp(encounter_id, 'PIH','8620','en');
UPDATE temp_labor_encs
SET transfer_in=obs_value_coded_list_from_temp(encounter_id, 'PIH','14973','en');
UPDATE temp_labor_encs
SET transfer_out=obs_value_coded_list_from_temp(encounter_id, 'PIH','14424','en');
UPDATE temp_labor_encs
SET transfer_location=COALESCE(transfer_in, transfer_out);
UPDATE temp_labor_encs
SET death_date=obs_value_datetime_from_temp(encounter_id, 'PIH','14399');
UPDATE temp_labor_encs
SET partogram_uploaded=latest_obs_from_temp_from_concept_id(patient_id, concept_from_mapping('PIH','13756'));


SELECT 
concat(@partition,"-",patient_id) as patient_id,
emr_id,
concat(@partition,"-",encounter_id) as encounter_id,
concat(@partition,"-",visit_id) as visit_id,
encounter_datetime,
encounter_location,
datetime_entered,
user_entered,
concat(@partition,"-",pregnancy_program_id) as pregnancy_program_id,
provider,
admission_date,
gravida,
partiy,
gestational_age,
gestational_age_source,
temperature,
heart_rate,
bp_systolic,
bp_diastolic,
respiratory_rate,
o2_saturation,
pregnancy_complications,
labor_start,
membranes_status,
membrane_rupture_date,
membrane_color,
meconium_classification,
fundal_height,
uc_status,
fetal_heart_rate_method,
fhr1,
fhr2,
fhr3,
fhr4,
fhr5,
CASE 
		WHEN upper(induced_labor)= 'YES' then 1
		WHEN upper(induced_labor)= 'NO' then 0
END AS induced_labor ,
induction_time,
method_of_induction,
palpation_of_abdomen,
CASE 
		WHEN upper(previous_abdominal_scar)= 'YES' then 1
		WHEN upper(previous_abdominal_scar)= 'NO' then 0
END AS previous_abdominal_scar ,
number_previous_csections,
overall_condition,
disposition,
transfer_location,
death_date,
CASE WHEN partogram_uploaded IS NOT NULL THEN TRUE ELSE FALSE END AS partogram_uploaded,
index_asc,
index_desc
FROM temp_labor_encs;
