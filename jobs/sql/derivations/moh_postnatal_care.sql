drop  table if exists #temp_postnatal_encounters;
select e.site, dd.LastDayOfMonth, e.patient_id , datediff(day, e2.encounter_datetime, e.encounter_datetime) "days_diff"
into #temp_postnatal_encounters
from all_encounters e
inner join all_encounters e2 on e2.patient_id = e.patient_id  
	and e2.encounter_type = 'Labor and Delivery Summary'
	and e2.encounter_datetime < e.encounter_datetime 
	and datediff(day, e2.encounter_datetime, e.encounter_datetime) < 42
inner join dim_date dd on dd.Date = cast(e.encounter_datetime as date)	
where e.encounter_type in ('ANC Followup', 'ANC Intake','Postnatal Followup'); 

drop table if exists #temp_min_days_after_delivery;
create table #temp_min_days_after_delivery
(site          varchar(50),
reporting_date date,
patient_id     varchar(20),
min_days_after int,
timeframe      varchar(20));

insert into #temp_min_days_after_delivery (site, reporting_date, patient_id, min_days_after)
select site, LastDayOfMonth, patient_id, min(days_diff) "min_days_after" 
from #temp_postnatal_encounters
group by site, LastDayOfMonth, patient_id;
	
update #temp_min_days_after_delivery
set timeframe = 
case 
	when min_days_after <= 1 then 'within 24 hours'
	when min_days_after <= 7 then '2-7 days'
	else  '8 days to 6 weeks'
end	;

drop table if exists #days_after_counts;
select site, reporting_date, timeframe, count(*) "count" 
into #days_after_counts
FROM  #temp_min_days_after_delivery
group by site, reporting_date, timeframe;

drop table if exists final_table_staging;
create table final_table_staging
(site          varchar(50),
reporting_date date,
timeframe      varchar(20),
count          int);

insert into final_table_staging (site, reporting_date, timeframe)
select distinct site, LastDayOfMonth, timeframe from  dim_date   
cross join 
(select v.timeframe from
 (VALUES ('within 24 hours'),('2-7 days'),('8 days to 6 weeks')) as v(timeframe)) a
cross join
(select v.site from
 (VALUES ('kgh'),('wellbody')) as v(site)) b
where LastDayOfMonth >= '2023-01-01' and Date <= GETDATE();

update f 
set f.count = c.count
from final_table_staging f
inner join #days_after_counts c on c.site = f.site
	and c.reporting_date = f.reporting_date 
	and c.timeframe = f.timeframe;

update f 
set f.count = 0
from final_table_staging f
where f.count is null;

DROP TABLE IF EXISTS moh_postnatal_care;
EXEC sp_rename 'final_table_staging', 'moh_postnatal_care';
