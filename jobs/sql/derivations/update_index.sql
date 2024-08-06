-- update index asc/desc on all_encounters table
drop table if exists #all_encounters_indexes;
select  patient_id, encounter_datetime,encounter_type_id,
ROW_NUMBER() over (PARTITION by patient_id, encounter_type_id order by  encounter_datetime asc) "index_asc",
ROW_NUMBER() over (PARTITION by patient_id, encounter_type_id order by  encounter_datetime DESC) "index_desc"
into #all_encounters_indexes
from all_encounters av;

update av
set av.index_asc = avi.index_asc,
	av.index_desc = avi.index_desc 
from all_encounters av
inner join #all_encounters_indexes avi on avi.patient_id = av.patient_id
and avi.encounter_type_id = av.encounter_type_id
and avi.encounter_datetime = av.encounter_datetime;

-- update index asc/desc on ncd_encounter table
drop table if exists #ncd_encounter_indexes;
select  patient_id, encounter_datetime,
ROW_NUMBER() over (PARTITION by patient_id order by  encounter_datetime asc) "index_asc",
ROW_NUMBER() over (PARTITION by patient_id order by  encounter_datetime DESC) "index_desc"
into #ncd_encounter_indexes
from ncd_encounter nv;

update nv
set nv.index_asc = nvi.index_asc,
	nv.index_desc = nvi.index_desc 
from ncd_encounter nv
inner join #ncd_encounter_indexes nvi on nvi.patient_id = nv.patient_id
and nvi.encounter_datetime = nv.encounter_datetime;


-- update index asc/desc on scbu_register_encounter table
drop table if exists #scbu_encounter_indexes;
select  emr_id, encounter_datetime,
ROW_NUMBER() over (PARTITION by emr_id order by  encounter_datetime asc) "index_asc",
ROW_NUMBER() over (PARTITION by emr_id order by  encounter_datetime DESC) "index_desc"
into #scbu_encounter_indexes
from scbu_register_encounter nv;

update nv
set nv.index_asc = nvi.index_asc,
	nv.index_desc = nvi.index_desc 
from scbu_register_encounter nv
inner join #scbu_encounter_indexes nvi on nvi.emr_id = nv.emr_id
and nvi.encounter_datetime = nv.encounter_datetime;

-- update index asc/desc on maternal_discharge_encounter table
drop table if exists #disch_encounter_indexes;
select  emr_id, encounter_datetime,
ROW_NUMBER() over (PARTITION by emr_id order by  encounter_datetime asc) "index_asc",
ROW_NUMBER() over (PARTITION by emr_id order by  encounter_datetime DESC) "index_desc"
into #disch_encounter_indexes
from maternal_discharge_encounter nv;

update nv
set nv.index_asc = nvi.index_asc,
	nv.index_desc = nvi.index_desc 
from maternal_discharge_encounter nv
inner join #disch_encounter_indexes nvi on nvi.emr_id = nv.emr_id
and nvi.encounter_datetime = nv.encounter_datetime;

-- update index asc/desc on labor_progress_encounter table
drop table if exists #lp_encounter_indexes;
select  emr_id, encounter_datetime,
ROW_NUMBER() over (PARTITION by emr_id order by  encounter_datetime asc) "index_asc",
ROW_NUMBER() over (PARTITION by emr_id order by  encounter_datetime DESC) "index_desc"
into #lp_encounter_indexes
from labor_progress_encounter nv;

update nv
set nv.index_asc = nvi.index_asc,
	nv.index_desc = nvi.index_desc 
from labor_progress_encounter nv
inner join #lp_encounter_indexes nvi on nvi.emr_id = nv.emr_id
and nvi.encounter_datetime = nv.encounter_datetime;

-- update index asc/desc on delivery_summary_encounter table
drop table if exists #dl_encounter_indexes;
select  mother_emr_id, encounter_datetime, birthdate, 
ROW_NUMBER() over (PARTITION by mother_emr_id order by  encounter_datetime ASC, birthdate ASC) "index_asc",
ROW_NUMBER() over (PARTITION by mother_emr_id order by  encounter_datetime DESC, birthdate DESC) "index_desc"
into #dl_encounter_indexes
from delivery_summary_encounter nv;

update nv
set nv.index_asc = nvi.index_asc,
	nv.index_desc = nvi.index_desc 
from delivery_summary_encounter nv
inner join #dl_encounter_indexes nvi on nvi.mother_emr_id = nv.mother_emr_id
and nvi.encounter_datetime = nv.encounter_datetime
AND nvi.birthdate = nv.birthdate;

-- update index asc/desc on anc_encounter table
drop table if exists #lp_encounter_indexes;
select  emr_id, encounter_datetime,
ROW_NUMBER() over (PARTITION by emr_id order by  encounter_datetime asc) "index_asc",
ROW_NUMBER() over (PARTITION by emr_id order by  encounter_datetime DESC) "index_desc"
into #anc_encounter_indexes
from anc_encounter nv;

update nv
set nv.index_asc = nvi.index_asc,
	nv.index_desc = nvi.index_desc 
from anc_encounter nv
inner join #anc_encounter_indexes nvi on nvi.emr_id = nv.emr_id
and nvi.encounter_datetime = nv.encounter_datetime;

-- update index asc/desc on labor_summary_encounter table
drop table if exists #labor_summary_encounter_indexes;
select  emr_id, encounter_datetime,
ROW_NUMBER() over (PARTITION by emr_id order by  encounter_datetime asc) "index_asc",
ROW_NUMBER() over (PARTITION by emr_id order by  encounter_datetime DESC) "index_desc"
into #labor_summary_encounter_indexes
from labor_summary_encounter nv;

update nv
set nv.index_asc = nvi.index_asc,
	nv.index_desc = nvi.index_desc 
from labor_summary_encounter nv
inner join #labor_summary_encounter_indexes nvi on nvi.emr_id = nv.emr_id
and nvi.encounter_datetime = nv.encounter_datetime;

-- update index asc/desc on newborn_assessment_encounter table
drop table if exists #newborn_assessment_encounter_indexes;
select  emr_id, encounter_datetime,
ROW_NUMBER() over (PARTITION by emr_id order by  encounter_datetime asc) "index_asc",
ROW_NUMBER() over (PARTITION by emr_id order by  encounter_datetime DESC) "index_desc"
into #newborn_assessment_encounter_indexes
from newborn_assessment_encounter nv;

update nv
set nv.index_asc = nvi.index_asc,
    nv.index_desc = nvi.index_desc
from newborn_assessment_encounter nv
inner join #newborn_assessment_encounter_indexes nvi on nvi.emr_id = nv.emr_id
and nvi.encounter_datetime = nv.encounter_datetime;

-- update index asc/desc on admission_note_encounter table
drop table if exists #admission_note_encounter_indexes;
select  emr_id, encounter_datetime,
ROW_NUMBER() over (PARTITION by emr_id order by  encounter_datetime asc) "index_asc",
ROW_NUMBER() over (PARTITION by emr_id order by  encounter_datetime DESC) "index_desc"
into #admission_note_encounter_indexes
from admission_note_encounter nv;

update nv
set nv.index_asc = nvi.index_asc,
    nv.index_desc = nvi.index_desc
    from admission_note_encounter nv
inner join #admission_note_encounter_indexes nvi on nvi.emr_id = nv.emr_id
and nvi.encounter_datetime = nv.encounter_datetime;

-- update index asc/desc on newborn_progress_discharge_encounter table
drop table if exists #newborn_progress_discharge_encounter_indexes;
select  emr_id, encounter_datetime,
ROW_NUMBER() over (PARTITION by emr_id order by  encounter_datetime asc) "index_asc",
ROW_NUMBER() over (PARTITION by emr_id order by  encounter_datetime DESC) "index_desc"
into #newborn_progress_discharge_encounter_indexes
from newborn_progress_discharge_encounter nv;

update nv
set nv.index_asc = nvi.index_asc,
    nv.index_desc = nvi.index_desc
    from newborn_progress_discharge_encounter nv
inner join #newborn_progress_discharge_encounter_indexes nvi on nvi.emr_id = nv.emr_id
and nvi.encounter_datetime = nv.encounter_datetime;