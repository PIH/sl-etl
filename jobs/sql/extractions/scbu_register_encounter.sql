set @partition = '${partitionNum}';
select encounter_type_id  into @scbu_enc
from encounter_type et where uuid='3790ecc6-bc63-48f8-9104-f81dc90ee21c';

drop temporary table if exists temp_scbu_encs;
create temporary table temp_scbu_encs
(
patient_id 			int,
emr_id				varchar(255),
encounter_id        int,
visit_id            int,
encounter_datetime datetime,
datetime_created datetime,
user_entered     varchar(255),
provider             varchar(255),
chart_patient_number  varchar(255),
arrvial_date		date,
referred_from       varchar(255),
referral_reason     varchar(255),
referred_by           varchar(255),
management_commenced	datetime,
admission_datetime      datetime,
age_at_admission_days   int,
age_at_admission_hours   int,
sex                     varchar(10),
weight_at_admission     decimal(3,2),
delivery_place         varchar(255),
delivery_facility      varchar(255),
number_ancs            int,
delivery_method        varchar(255),
diagnosis_prior_to_admission  varchar(255),
treatment_prior_to_admission   varchar(255),
apgar_1_min                 varchar(255),
apgar_1_min_unknown                varchar(255),
apgar_5_min                varchar(255),
apgar_5_min_unknown              varchar(255),
assisted_ventilation_birth  varchar(255),
weight_at_birth       decimal(3,2),
gestational_age       decimal(5,2),
diagnosis_at_admission    varchar(255),
management_at_admission   varchar(255),
outcome                 varchar(255),
death_date              date,
cause_of_death         varchar(255),
age_at_death           int,
weight_at_death        decimal(3,2),
discharge_date         date,
index_asc int,
index_desc  int
);

insert into temp_scbu_encs(patient_id, encounter_id, visit_id, encounter_datetime, 
datetime_created, user_entered)
select patient_id, encounter_id, visit_id, encounter_datetime, date_created, creator
from encounter e
where e.voided = 0
AND encounter_type IN (@scbu_enc)
ORDER BY encounter_datetime desc;

create index temp_scbu_encs_ei on temp_scbu_encs(encounter_id);


UPDATE temp_scbu_encs
set user_entered = person_name_of_user(user_entered);

UPDATE temp_scbu_encs
SET provider = provider(encounter_id);

UPDATE temp_scbu_encs t
SET emr_id = patient_identifier(patient_id, 'c09a1d24-7162-11eb-8aa6-0242ac110002');


DROP TEMPORARY TABLE IF EXISTS temp_obs;
create temporary table temp_obs 
select o.obs_id, o.voided ,o.obs_group_id , o.encounter_id, o.person_id, o.concept_id, o.value_coded, o.value_numeric, 
o.value_text,o.value_datetime, o.comments, o.date_created
from obs o
inner join temp_scbu_encs t on t.encounter_id = o.encounter_id
where o.voided = 0;

UPDATE temp_scbu_encs
SET chart_patient_number= obs_value_text_from_temp(encounter_id, 'PIH','14396');


UPDATE temp_scbu_encs
SET referred_from=obs_value_coded_list_from_temp(encounter_id, 'PIH','7454','en');

UPDATE temp_scbu_encs
SET referred_by= obs_value_coded_list_from_temp(encounter_id, 'PIH','10635','en');

-- Management
UPDATE temp_scbu_encs
SET management_commenced=obs_value_datetime_from_temp(encounter_id, 'PIH','14398');

-- Admission
UPDATE temp_scbu_encs
SET admission_datetime=obs_value_datetime_from_temp(encounter_id, 'PIH','12240');

UPDATE temp_scbu_encs
SET age_at_admission_days=obs_value_numeric_from_temp(encounter_id, 'PIH','14393');
UPDATE temp_scbu_encs
SET age_at_admission_hours=obs_value_numeric_from_temp(encounter_id, 'PIH','14394');
UPDATE temp_scbu_encs
SET sex= obs_value_coded_list_from_temp(encounter_id, 'PIH','13055','en');
UPDATE temp_scbu_encs
SET weight_at_admission=obs_value_numeric_from_temp(encounter_id, 'PIH','14397');

-- History

UPDATE temp_scbu_encs
SET delivery_place=obs_value_coded_list_from_temp(encounter_id, 'PIH','11348','en');
UPDATE temp_scbu_encs
SET delivery_facility=obs_value_coded_list_from_temp(encounter_id, 'PIH','12365','en');
UPDATE temp_scbu_encs
SET number_ancs=obs_value_numeric_from_temp(encounter_id, 'PIH','13321');
UPDATE temp_scbu_encs
SET delivery_method=obs_value_coded_list_from_temp(encounter_id, 'PIH','11663','en');
UPDATE temp_scbu_encs
SET diagnosis_prior_to_admission=obs_value_coded_list_from_temp(encounter_id, 'PIH','3064','en');
UPDATE temp_scbu_encs
SET treatment_prior_to_admission=obs_value_coded_list_from_temp(encounter_id, 'PIH','3513','en');

UPDATE temp_scbu_encs
SET apgar_1_min=obs_value_numeric_from_temp(encounter_id, 'PIH','14419');
UPDATE temp_scbu_encs
SET apgar_1_min_unknown=obs_value_coded_list_from_temp(encounter_id, 'PIH','12377','en');
UPDATE temp_scbu_encs
SET apgar_5_min=obs_value_numeric_from_temp(encounter_id, 'PIH','14417');
UPDATE temp_scbu_encs
SET apgar_5_min_unknown=obs_value_coded_list_from_temp(encounter_id, 'PIH','11932','en');

UPDATE temp_scbu_encs
SET assisted_ventilation_birth=obs_value_coded_list_from_temp(encounter_id, 'PIH','13096','en');
UPDATE temp_scbu_encs
SET weight_at_birth=obs_value_numeric_from_temp(encounter_id, 'PIH','11067');
UPDATE temp_scbu_encs
SET gestational_age=obs_value_numeric_from_temp(encounter_id, 'PIH','14390');
UPDATE temp_scbu_encs
SET diagnosis_at_admission=obs_value_coded_list_from_temp(encounter_id, 'PIH','12564','en');
UPDATE temp_scbu_encs
SET management_at_admission=obs_value_coded_list_from_temp(encounter_id, 'PIH','12943','en');


UPDATE temp_scbu_encs
SET outcome=obs_value_coded_list_from_temp(encounter_id, 'PIH','8620','en');
UPDATE temp_scbu_encs
SET death_date=obs_value_datetime_from_temp(encounter_id, 'PIH','14399');
UPDATE temp_scbu_encs
SET cause_of_death=obs_value_coded_list_from_temp(encounter_id, 'PIH','3355','en');
UPDATE temp_scbu_encs
SET age_at_death=obs_value_numeric_from_temp(encounter_id, 'PIH','14393');
UPDATE temp_scbu_encs
SET weight_at_death=obs_value_numeric_from_temp(encounter_id, 'PIH','5089');
UPDATE temp_scbu_encs
SET discharge_date=obs_value_datetime_from_temp(encounter_id, 'PIH','3800');

SELECT 
concat(@partition,"-",patient_id) as patient_id,
emr_id,
encounter_id,
visit_id,
encounter_datetime,
datetime_created,
user_entered,
provider,
chart_patient_number,
arrvial_date,
referred_from,
referral_reason,
referred_by,
management_commenced,
admission_datetime,
age_at_admission_days,
age_at_admission_hours,
sex,
weight_at_admission,
delivery_place,
delivery_facility,
number_ancs,
delivery_method,
diagnosis_prior_to_admission,
treatment_prior_to_admission,
CASE WHEN apgar_1_min IS NOT NULL THEN apgar_1_min
	 WHEN apgar_1_min_unknown IS NOT NULL THEN 'U' END AS apgar_1_min,
CASE WHEN apgar_5_min IS NOT NULL THEN apgar_5_min
	 WHEN apgar_5_min_unknown IS NOT NULL THEN 'U' END AS apgar_5_min,
assisted_ventilation_birth,
weight_at_birth,
gestational_age,
diagnosis_at_admission,
management_at_admission,
outcome,
death_date,
cause_of_death,
age_at_death,
weight_at_death,
discharge_date,
index_asc,
index_desc
FROM temp_scbu_encs;
