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
        ROW_NUMBER() over (PARTITION by mother_emr_id order by encounter_datetime, birthdate, encounter_id) as index_asc,
        ROW_NUMBER() over (PARTITION by mother_emr_id order by encounter_datetime DESC, birthdate DESC, encounter_id DESC) as index_desc
into    #derived_indexes
from    delivery_summary_encounter;

update t
set t.index_asc = i.index_asc,
    t.index_desc = i.index_desc
from delivery_summary_encounter t inner join #derived_indexes i on i.encounter_id = t.encounter_id
;

-- update index asc/desc on anc_encounter table
drop table if exists #derived_indexes;
select  encounter_id,
        ROW_NUMBER() over (PARTITION by emr_id order by encounter_datetime, encounter_id) as index_asc,
        ROW_NUMBER() over (PARTITION by emr_id order by encounter_datetime DESC, encounter_id DESC) as index_desc
into    #derived_indexes
from    anc_encounter;

update t
set t.index_asc = i.index_asc,
    t.index_desc = i.index_desc
from anc_encounter t inner join #derived_indexes i on i.encounter_id = t.encounter_id
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
