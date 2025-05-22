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

-- update index asc/desc on scbu_register_encounter table
drop table if exists #derived_indexes;
select  encounter_id,
        ROW_NUMBER() over (PARTITION by emr_id order by encounter_datetime, encounter_id) as index_asc,
        ROW_NUMBER() over (PARTITION by emr_id order by encounter_datetime DESC, encounter_id DESC) as index_desc
into    #derived_indexes
from    scbu_register_encounter;

update t
set t.index_asc = i.index_asc,
    t.index_desc = i.index_desc
from scbu_register_encounter t inner join #derived_indexes i on i.encounter_id = t.encounter_id
;

-- update index asc/desc on maternal_discharge_encounter table
drop table if exists #derived_indexes;
select  encounter_id,
        ROW_NUMBER() over (PARTITION by emr_id order by encounter_datetime, encounter_id) as index_asc,
        ROW_NUMBER() over (PARTITION by emr_id order by encounter_datetime DESC, encounter_id DESC) as index_desc
into    #derived_indexes
from    maternal_discharge_encounter;

update t
set t.index_asc = i.index_asc,
    t.index_desc = i.index_desc
from maternal_discharge_encounter t inner join #derived_indexes i on i.encounter_id = t.encounter_id
;

-- update index asc/desc on labor_progress_encounter table
drop table if exists #derived_indexes;
select  encounter_id,
        ROW_NUMBER() over (PARTITION by emr_id order by encounter_datetime, encounter_id) as index_asc,
        ROW_NUMBER() over (PARTITION by emr_id order by encounter_datetime DESC, encounter_id DESC) as index_desc
into    #derived_indexes
from    labor_progress_encounter;

update t
set t.index_asc = i.index_asc,
    t.index_desc = i.index_desc
from labor_progress_encounter t inner join #derived_indexes i on i.encounter_id = t.encounter_id
;

-- update index asc/desc on delivery_summary_encounter table
drop table if exists #derived_indexes;
select  encounter_id,
        ROW_NUMBER() over (PARTITION by emr_id_mother order by encounter_datetime, birthdate, encounter_id) as index_asc,
        ROW_NUMBER() over (PARTITION by emr_id_mother order by encounter_datetime DESC, birthdate DESC, encounter_id DESC) as index_desc
into    #derived_indexes
from    delivery_summary_encounter;

update t
set t.index_asc = i.index_asc,
    t.index_desc = i.index_desc
from delivery_summary_encounter t inner join #derived_indexes i on i.encounter_id = t.encounter_id
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

-- update index asc/desc on labor_summary_encounter table
drop table if exists #derived_indexes;
select  encounter_id,
        ROW_NUMBER() over (PARTITION by emr_id order by encounter_datetime, encounter_id) as index_asc,
        ROW_NUMBER() over (PARTITION by emr_id order by encounter_datetime DESC, encounter_id DESC) as index_desc
into    #derived_indexes
from    labor_summary_encounter;

update t
set t.index_asc = i.index_asc,
    t.index_desc = i.index_desc
from labor_summary_encounter t inner join #derived_indexes i on i.encounter_id = t.encounter_id
;

-- update index asc/desc on newborn_assessment_encounter table
drop table if exists #derived_indexes;
select  encounter_id,
        ROW_NUMBER() over (PARTITION by emr_id order by encounter_datetime, encounter_id) as index_asc,
        ROW_NUMBER() over (PARTITION by emr_id order by encounter_datetime DESC, encounter_id DESC) as index_desc
into    #derived_indexes
from    newborn_assessment_encounter;

update t
set t.index_asc = i.index_asc,
    t.index_desc = i.index_desc
from newborn_assessment_encounter t inner join #derived_indexes i on i.encounter_id = t.encounter_id
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

-- update index asc/desc on postpartum_daily_encounter table
drop table if exists #derived_indexes;
select  encounter_id,
        ROW_NUMBER() over (PARTITION by emr_id order by encounter_datetime, encounter_id) as index_asc,
        ROW_NUMBER() over (PARTITION by emr_id order by encounter_datetime DESC, encounter_id DESC) as index_desc
into    #derived_indexes
from    postpartum_daily_encounter;

update t
set t.index_asc = i.index_asc,
    t.index_desc = i.index_desc
from postpartum_daily_encounter t inner join #derived_indexes i on i.encounter_id = t.encounter_id
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

-- update index asc/desc on pregnancy_program table
drop table if exists #derived_indexes;
select  pregnancy_program_id,
        ROW_NUMBER() over (PARTITION by patient_id order by date_enrolled, pregnancy_program_id) as index_asc,
        ROW_NUMBER() over (PARTITION by patient_id order by date_enrolled DESC, pregnancy_program_id DESC) as index_desc
into    #derived_indexes
from    pregnancy_program;

update t
set t.index_asc = i.index_asc,
    t.index_desc = i.index_desc
from pregnancy_program t inner join #derived_indexes i on i.pregnancy_program_id = t.pregnancy_program_id
;

-- update index asc/desc on newborn_admission_encounter table
drop table if exists #derived_indexes;
select  encounter_id,
        ROW_NUMBER() over (PARTITION by emr_id order by encounter_datetime, encounter_id) as index_asc,
        ROW_NUMBER() over (PARTITION by emr_id order by encounter_datetime DESC, encounter_id DESC) as index_desc
into    #derived_indexes
from    newborn_admission_encounter;

update t
set t.index_asc = i.index_asc,
    t.index_desc = i.index_desc
from newborn_admission_encounter t inner join #derived_indexes i on i.encounter_id = t.encounter_id
;

-- update patient index asc/desc on pregnancy_state table
drop table if exists #derived_indexes;
select  pregnancy_program_state_id,
        ROW_NUMBER() over (PARTITION by emr_id order by state_start_date, pregnancy_program_state_id) as index_asc,
        ROW_NUMBER() over (PARTITION by emr_id order by state_start_date DESC, pregnancy_program_state_id DESC) as index_desc
into    #derived_indexes
from    pregnancy_state;

update t
set t.index_asc = i.index_asc,
    t.index_desc = i.index_desc
from pregnancy_state t inner join #derived_indexes i on i.pregnancy_program_state_id = t.pregnancy_program_state_id
;

-- update patient program index asc/desc on pregnancy_state table
drop table if exists #derived_indexes;
select  pregnancy_program_state_id,
        ROW_NUMBER() over (PARTITION by pregnancy_program_id order by state_start_date, pregnancy_program_state_id) as index_asc_patient_program,
        ROW_NUMBER() over (PARTITION by pregnancy_program_id order by state_start_date DESC, pregnancy_program_state_id DESC) as index_desc_patient_program
into    #derived_indexes
from    pregnancy_state;

update t
set t.index_asc_patient_program = i.index_asc_patient_program,
    t.index_desc_patient_program = i.index_desc_patient_program
from pregnancy_state t inner join #derived_indexes i on i.pregnancy_program_state_id = t.pregnancy_program_state_id
;
