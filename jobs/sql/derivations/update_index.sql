-- update index asc/desc on all_encounters table
select  patient_id, encounter_datetime,
ROW_NUMBER() over (PARTITION by patient_id order by  encounter_type_id asc, encounter_datetime asc) "index_asc",
ROW_NUMBER() over (PARTITION by patient_id order by encounter_type_id desc, encounter_datetime DESC) "index_desc"
into #all_encounters_indexes
from all_encounters av;

update av
set av.index_asc = avi.index_asc,
	av.index_desc = avi.index_desc 
from all_encounters av
inner join #all_encounters_indexes avi on avi.patient_id = av.patient_id
and avi.encounter_type_id = av.encounter_type_id
and avi.encounter_datetime = av.encounter_datetime; 