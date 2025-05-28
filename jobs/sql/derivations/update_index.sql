-- update index asc/desc on all_encounters table
drop table if exists #derived_indexes;
select  encounter_id,
        ROW_NUMBER() over (PARTITION by patient_id, encounter_type_id order by encounter_datetime, encounter_id) as index_asc,
        ROW_NUMBER() over (PARTITION by patient_id, encounter_type_id order by encounter_datetime DESC, encounter_id DESC) as index_desc
into    #derived_indexes
from    all_encounters;

update t
set t.index_asc = i.index_asc,
	t.index_desc = i.index_desc
from all_encounters t inner join #derived_indexes i on i.encounter_id = t.encounter_id
;

-- update index asc/desc on ncd_encounter table
drop table if exists #derived_indexes;
select  encounter_id,
        ROW_NUMBER() over (PARTITION by patient_id order by encounter_datetime, encounter_id) as index_asc,
        ROW_NUMBER() over (PARTITION by patient_id order by encounter_datetime DESC, encounter_id DESC) as index_desc
into    #derived_indexes
from    ncd_encounter;

update t
set t.index_asc = i.index_asc,
    t.index_desc = i.index_desc
from ncd_encounter t inner join #derived_indexes i on i.encounter_id = t.encounter_id
;

-- update index asc/desc on mch_scbu_register_encounter table
drop table if exists #derived_indexes;
select  encounter_id,
        ROW_NUMBER() over (PARTITION by emr_id order by encounter_datetime, encounter_id) as index_asc,
        ROW_NUMBER() over (PARTITION by emr_id order by encounter_datetime DESC, encounter_id DESC) as index_desc
into    #derived_indexes
from    mch_scbu_register_encounter;

update t
set t.index_asc = i.index_asc,
    t.index_desc = i.index_desc
from mch_scbu_register_encounter t inner join #derived_indexes i on i.encounter_id = t.encounter_id
;

-- update index asc/desc on mch_maternal_discharge_encounter table
drop table if exists #derived_indexes;
select  encounter_id,
        ROW_NUMBER() over (PARTITION by emr_id order by encounter_datetime, encounter_id) as index_asc,
        ROW_NUMBER() over (PARTITION by emr_id order by encounter_datetime DESC, encounter_id DESC) as index_desc
into    #derived_indexes
from    mch_maternal_discharge_encounter;

update t
set t.index_asc = i.index_asc,
    t.index_desc = i.index_desc
from mch_maternal_discharge_encounter t inner join #derived_indexes i on i.encounter_id = t.encounter_id
;

-- update index asc/desc on mch_labor_progress_encounter table
drop table if exists #derived_indexes;
select  encounter_id,
        ROW_NUMBER() over (PARTITION by emr_id order by encounter_datetime, encounter_id) as index_asc,
        ROW_NUMBER() over (PARTITION by emr_id order by encounter_datetime DESC, encounter_id DESC) as index_desc
into    #derived_indexes
from    mch_labor_progress_encounter;

update t
set t.index_asc = i.index_asc,
    t.index_desc = i.index_desc
from mch_labor_progress_encounter t inner join #derived_indexes i on i.encounter_id = t.encounter_id
;

-- update index asc/desc on mch_delivery_summary_encounter table
drop table if exists #derived_indexes;
select  encounter_id,
        ROW_NUMBER() over (PARTITION by emr_id_mother order by encounter_datetime, birthdate, encounter_id) as index_asc,
        ROW_NUMBER() over (PARTITION by emr_id_mother order by encounter_datetime DESC, birthdate DESC, encounter_id DESC) as index_desc
into    #derived_indexes
from    mch_delivery_summary_encounter;

update t
set t.index_asc = i.index_asc,
    t.index_desc = i.index_desc
from mch_delivery_summary_encounter t inner join #derived_indexes i on i.encounter_id = t.encounter_id
;

-- update index asc/desc on mch_anc_encounter table
drop table if exists #derived_indexes;
select  encounter_id,
        ROW_NUMBER() over (PARTITION by emr_id order by encounter_datetime, encounter_id) as index_asc,
        ROW_NUMBER() over (PARTITION by emr_id order by encounter_datetime DESC, encounter_id DESC) as index_desc
into    #derived_indexes
from    mch_anc_encounter;

update t
set t.index_asc = i.index_asc,
    t.index_desc = i.index_desc
from mch_anc_encounter t inner join #derived_indexes i on i.encounter_id = t.encounter_id
;

-- update index asc/desc on mch_anc_encounter table
drop table if exists #derived_indexes;
select  encounter_id,
        ROW_NUMBER() over (PARTITION by pregnancy_program_id  order by encounter_datetime, encounter_id) as index_asc_patient_program,
        ROW_NUMBER() over (PARTITION by pregnancy_program_id order by encounter_datetime DESC, encounter_id DESC) as index_desc_patient_program
into    #derived_indexes
from    mch_anc_encounter;

update t
set t.index_asc_patient_program = i.index_asc_patient_program,
    t.index_desc_patient_program = i.index_desc_patient_program
from mch_anc_encounter t inner join #derived_indexes i on i.encounter_id = t.encounter_id
;

-- update index asc/desc on mch_labor_summary_encounter table
drop table if exists #derived_indexes;
select  encounter_id,
        ROW_NUMBER() over (PARTITION by emr_id order by encounter_datetime, encounter_id) as index_asc,
        ROW_NUMBER() over (PARTITION by emr_id order by encounter_datetime DESC, encounter_id DESC) as index_desc
into    #derived_indexes
from    mch_labor_summary_encounter;

update t
set t.index_asc = i.index_asc,
    t.index_desc = i.index_desc
from mch_labor_summary_encounter t inner join #derived_indexes i on i.encounter_id = t.encounter_id
;

-- update index asc/desc on mch_newborn_assessment_encounter table
drop table if exists #derived_indexes;
select  encounter_id,
        ROW_NUMBER() over (PARTITION by emr_id order by encounter_datetime, encounter_id) as index_asc,
        ROW_NUMBER() over (PARTITION by emr_id order by encounter_datetime DESC, encounter_id DESC) as index_desc
into    #derived_indexes
from    mch_newborn_assessment_encounter;

update t
set t.index_asc = i.index_asc,
    t.index_desc = i.index_desc
from mch_newborn_assessment_encounter t inner join #derived_indexes i on i.encounter_id = t.encounter_id
;

-- update index asc/desc on admission_note_encounter table
drop table if exists #derived_indexes;
select  encounter_id,
        ROW_NUMBER() over (PARTITION by emr_id order by encounter_datetime, encounter_id) as index_asc,
        ROW_NUMBER() over (PARTITION by emr_id order by encounter_datetime DESC, encounter_id DESC) as index_desc
into    #derived_indexes
from    admission_note_encounter;

update t
set t.index_asc = i.index_asc,
    t.index_desc = i.index_desc
from admission_note_encounter t inner join #derived_indexes i on i.encounter_id = t.encounter_id
;

-- update index asc/desc on newborn_progress_discharge_encounter table
drop table if exists #derived_indexes;
select  encounter_id,
        ROW_NUMBER() over (PARTITION by emr_id order by encounter_datetime, encounter_id) as index_asc,
        ROW_NUMBER() over (PARTITION by emr_id order by encounter_datetime DESC, encounter_id DESC) as index_desc
into    #derived_indexes
from    newborn_progress_discharge_encounter;

update t
set t.index_asc = i.index_asc,
    t.index_desc = i.index_desc
from newborn_progress_discharge_encounter t inner join #derived_indexes i on i.encounter_id = t.encounter_id
;

-- update index asc/desc on mch_postpartum_daily_encounter table
drop table if exists #derived_indexes;
select  encounter_id,
        ROW_NUMBER() over (PARTITION by emr_id order by encounter_datetime, encounter_id) as index_asc,
        ROW_NUMBER() over (PARTITION by emr_id order by encounter_datetime DESC, encounter_id DESC) as index_desc
into    #derived_indexes
from    mch_postpartum_daily_encounter;

update t
set t.index_asc = i.index_asc,
    t.index_desc = i.index_desc
from mch_postpartum_daily_encounter t inner join #derived_indexes i on i.encounter_id = t.encounter_id
;

-- update index asc/desc on all_appointments table
drop table if exists #derived_indexes;
select  appointment_id,
        ROW_NUMBER() over (PARTITION by patient_id order by appointment_datetime, appointment_id) as index_asc,
        ROW_NUMBER() over (PARTITION by patient_id order by appointment_datetime DESC, appointment_id DESC) as index_desc
into    #derived_indexes
from    all_appointments;

update t
set t.index_asc = i.index_asc,
    t.index_desc = i.index_desc
from all_appointments t inner join #derived_indexes i on i.appointment_id = t.appointment_id
;

-- update index asc/desc on mch_pregnancy_program table
drop table if exists #derived_indexes;
select  pregnancy_program_id,
        ROW_NUMBER() over (PARTITION by patient_id order by date_enrolled, pregnancy_program_id) as index_asc,
        ROW_NUMBER() over (PARTITION by patient_id order by date_enrolled DESC, pregnancy_program_id DESC) as index_desc
into    #derived_indexes
from    mch_pregnancy_program;

update t
set t.index_asc = i.index_asc,
    t.index_desc = i.index_desc
from mch_pregnancy_program t inner join #derived_indexes i on i.pregnancy_program_id = t.pregnancy_program_id
;

-- update index asc/desc on mch_newborn_admission_encounter table
drop table if exists #derived_indexes;
select  encounter_id,
        ROW_NUMBER() over (PARTITION by emr_id order by encounter_datetime, encounter_id) as index_asc,
        ROW_NUMBER() over (PARTITION by emr_id order by encounter_datetime DESC, encounter_id DESC) as index_desc
into    #derived_indexes
from    mch_newborn_admission_encounter;

update t
set t.index_asc = i.index_asc,
    t.index_desc = i.index_desc
from mch_newborn_admission_encounter t inner join #derived_indexes i on i.encounter_id = t.encounter_id
;

-- update patient index asc/desc on mch_pregnancy_state table
drop table if exists #derived_indexes;
select  pregnancy_program_state_id,
        ROW_NUMBER() over (PARTITION by emr_id order by state_start_date, pregnancy_program_state_id) as index_asc,
        ROW_NUMBER() over (PARTITION by emr_id order by state_start_date DESC, pregnancy_program_state_id DESC) as index_desc
into    #derived_indexes
from    mch_pregnancy_state;

update t
set t.index_asc = i.index_asc,
    t.index_desc = i.index_desc
from mch_pregnancy_state t inner join #derived_indexes i on i.pregnancy_program_state_id = t.pregnancy_program_state_id
;

-- update patient program index asc/desc on mch_pregnancy_state table
drop table if exists #derived_indexes;
select  pregnancy_program_state_id,
        ROW_NUMBER() over (PARTITION by pregnancy_program_id order by state_start_date, pregnancy_program_state_id) as index_asc_patient_program,
        ROW_NUMBER() over (PARTITION by pregnancy_program_id order by state_start_date DESC, pregnancy_program_state_id DESC) as index_desc_patient_program
into    #derived_indexes
from    mch_pregnancy_state;

update t
set t.index_asc_patient_program = i.index_asc_patient_program,
    t.index_desc_patient_program = i.index_desc_patient_program
from mch_pregnancy_state t inner join #derived_indexes i on i.pregnancy_program_state_id = t.pregnancy_program_state_id
;

-- update patient  index asc/desc on all_medications_prescribed table
drop table if exists #derived_indexes;
select  medication_prescription_id,
        ROW_NUMBER() over (PARTITION by patient_id order by order_date_activated, medication_prescription_id) as index_asc,
        ROW_NUMBER() over (PARTITION by patient_id order by order_date_activated DESC, medication_prescription_id DESC) as index_desc
into    #derived_indexes
from    all_medications_prescribed;

update t
set t.index_asc = i.index_asc,
    t.index_desc = i.index_desc
from all_medications_prescribed t inner join #derived_indexes i on i.medication_prescription_id = t.medication_prescription_id
;

-- update patient  index asc/desc on all_diagnosis table
drop table if exists #derived_indexes;
select  obs_id,
        ROW_NUMBER() over (PARTITION by patient_id order by obs_datetime, obs_id) as index_asc,
        ROW_NUMBER() over (PARTITION by patient_id order by obs_datetime DESC, obs_id DESC) as index_desc
into    #derived_indexes
from    all_diagnosis;

update t
set t.index_asc = i.index_asc,
    t.index_desc = i.index_desc
from all_diagnosis t inner join #derived_indexes i on i.obs_id = t.obs_id
;

-- update patient  index asc/desc on all_lab_orders table
drop table if exists #derived_indexes;
select  order_number,
        ROW_NUMBER() over (PARTITION by patient_id order by order_datetime, order_number) as index_asc,
        ROW_NUMBER() over (PARTITION by patient_id order by order_datetime DESC, order_number DESC) as index_desc
into    #derived_indexes
from    all_lab_orders;

update t
set t.index_asc = i.index_asc,
    t.index_desc = i.index_desc
from all_lab_orders t inner join #derived_indexes i on i.order_number = t.order_number
;

-- update patient  index asc/desc on all_lab_results table
drop table if exists #derived_indexes;
select  lab_obs_id,
        ROW_NUMBER() over (PARTITION by patient_id order by specimen_collection_date, lab_obs_id) as index_asc,
        ROW_NUMBER() over (PARTITION by patient_id order by specimen_collection_date DESC, lab_obs_id DESC) as index_desc
into    #derived_indexes
from    all_lab_results;

update t
set t.index_asc = i.index_asc,
    t.index_desc = i.index_desc
from all_lab_results t inner join #derived_indexes i on i.lab_obs_id = t.lab_obs_id
;

-- update patient  index asc/desc on mch_delivery table
drop table if exists #derived_indexes;
select  encounter_id,
        ROW_NUMBER() over (PARTITION by patient_id order by encounter_datetime, encounter_id) as index_asc,
        ROW_NUMBER() over (PARTITION by patient_id order by encounter_datetime DESC, encounter_id DESC) as index_desc
into    #derived_indexes
from    mch_delivery;

update t
set t.index_asc = i.index_asc,
    t.index_desc = i.index_desc
from mch_delivery t inner join #derived_indexes i on i.encounter_id = t.encounter_id
;

-- update patient  index asc/desc on mh_encounter table
drop table if exists #derived_indexes;
select  encounter_id,
        ROW_NUMBER() over (PARTITION by patient_id order by encounter_datetime, encounter_id) as index_asc,
        ROW_NUMBER() over (PARTITION by patient_id order by encounter_datetime DESC, encounter_id DESC) as index_desc
into    #derived_indexes
from    mh_encounter;

update t
set t.index_asc = i.index_asc,
    t.index_desc = i.index_desc
from mh_encounter t inner join #derived_indexes i on i.encounter_id = t.encounter_id
;

-- update patient  index asc/desc on triage_encounter table
drop table if exists #derived_indexes;
select  encounter_id,
        ROW_NUMBER() over (PARTITION by patient_id order by encounter_datetime, encounter_id) as index_asc,
        ROW_NUMBER() over (PARTITION by patient_id order by encounter_datetime DESC, encounter_id DESC) as index_desc
into    #derived_indexes
from    triage_encounter;

update t
set t.index_asc = i.index_asc,
    t.index_desc = i.index_desc
from triage_encounter t inner join #derived_indexes i on i.encounter_id = t.encounter_id
;


-- update patient  index asc/desc on user_logins table
drop table if exists #derived_indexes;
select  login_id,
        ROW_NUMBER() over (PARTITION by username order by date_logged_in, login_id) as index_asc,
        ROW_NUMBER() over (PARTITION by username order by date_logged_in DESC, login_id DESC) as index_desc
into    #derived_indexes
from    user_logins;

update t
set t.index_asc = i.index_asc,
    t.index_desc = i.index_desc
from user_logins t inner join #derived_indexes i on i.login_id = t.login_id
;
