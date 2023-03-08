-- update index asc/desc on mch_visit table
{# select  emr_id, visit_date, encounter_id,
ROW_NUMBER() over (PARTITION by emr_id order by visit_date asc, encounter_id asc) "index_asc",
ROW_NUMBER() over (PARTITION by emr_id order by visit_date DESC, encounter_id DESC) "index_desc"
into #mch_visit_indexes
from mch_visit av ;

update av
set av.index_asc = avi.index_asc,
	av.index_desc = avi.index_desc 
from mch_visit av
inner join #mch_visit_indexes avi on avi.emr_id = av.emr_id
and avi.visit_date = av.visit_date
and avi.encounter_id = av.encounter_id;  #}