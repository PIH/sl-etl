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
