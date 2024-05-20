select encounter_type_id  into @disch_enc
from encounter_type et where uuid='2110a810-db62-4914-ba95-604b96010164';


drop temporary table if exists temp_disch_encs;
create temporary table temp_disch_encs
(
patient_id          int,
emr_id              varchar(255),
encounter_id        int,
visit_id            int,
encounter_datetime datetime,
datetime_created datetime,
user_entered     varchar(255),
provider             varchar(255),
next_appointment_date  date,
disposition          varchar(255),
transfer_location    varchar(255),
followup_clinic      varchar(255),
index_asc int,
index_desc  int
);

insert into temp_disch_encs(patient_id, encounter_id, visit_id, encounter_datetime, 
datetime_created, user_entered)
select patient_id, encounter_id, visit_id, encounter_datetime, date_created, creator
from encounter e
where e.voided = 0
AND encounter_type IN (@disch_enc)
ORDER BY encounter_datetime desc;

create index temp_disch_encs_ei on temp_disch_encs(encounter_id);


UPDATE temp_disch_encs
set user_entered = person_name_of_user(user_entered);

UPDATE temp_disch_encs
SET provider = provider(encounter_id);

UPDATE temp_disch_encs t
SET emr_id = patient_identifier(patient_id, 'c09a1d24-7162-11eb-8aa6-0242ac110002');


DROP TEMPORARY TABLE IF EXISTS temp_obs;
create temporary table temp_obs 
select o.obs_id, o.voided ,o.obs_group_id , o.encounter_id, o.person_id, o.concept_id, o.value_coded, o.value_numeric, 
o.value_text,o.value_datetime, o.comments, o.date_created
from obs o
inner join temp_disch_encs t on t.encounter_id = o.encounter_id
where o.voided = 0;

UPDATE temp_disch_encs
SET next_appointment_date=obs_value_datetime_from_temp(encounter_id, 'PIH','5096');

UPDATE temp_disch_encs
SET disposition= obs_value_coded_list_from_temp(encounter_id, 'PIH','8620','en');

UPDATE temp_disch_encs
SET transfer_location= obs_value_coded_list_from_temp(encounter_id, 'PIH','14973','en');


UPDATE temp_disch_encs
SET followup_clinic=obs_value_coded_list_from_temp(encounter_id, 'PIH','1272','en');

SELECT 
emr_id,
encounter_id,
visit_id,
encounter_datetime,
datetime_created,
user_entered,
provider,
next_appointment_date,
disposition,
transfer_location,
followup_clinic,
index_asc,
index_desc
FROM temp_disch_encs;