drop table if exists mcoe_encounters;
select * 
into mcoe_encounters
from all_encounters 
where mcoe_location = 1;

drop table if exists mcoe_diagnosis;
select d.* 
into mcoe_diagnosis 
from all_diagnosis d 
inner join mcoe_encounters m on m.encounter_id = d.encounter_id 

drop table if exists mcoe_visits;
select * 
into mcoe_visits
from all_visits v 
where exists 
(select 1 from mcoe_encounters e 
where e.visit_id = v.visit_id);

drop table if exists mcoe_vitals;
select v.* 
into mcoe_vitals 
from all_vitals v 
inner join mcoe_encounters m on m.encounter_id = v.encounter_id;
