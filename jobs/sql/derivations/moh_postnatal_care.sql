drop table if exists final_table_staging;
create table final_table_staging
(site                      varchar(50),
reporting_date             date,
timeframe                  varchar(20),
mother_in_facility         int,
neonate_in_facility_male   int,
neonate_in_facility_female int);

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
set f.mother_in_facility = i.count
from final_table_staging f 
inner join 
	(select site, reporting_date, timeframe_after_delivery, count(distinct mother_patient_id) "count"
	from moh_postnatal_care_data
	group by site, reporting_date, timeframe_after_delivery) i 
	on i.site = f.site  and i.reporting_date = f.reporting_date and i.timeframe_after_delivery = f.timeframe;

update f set f.mother_in_facility = 0 from final_table_staging f where f.mother_in_facility is null;

update f 
set f.neonate_in_facility_male = i.male_baby_count,
	f.neonate_in_facility_female = i.female_baby_count
from final_table_staging f 
inner join 
	(select site, reporting_date, timeframe_after_delivery, 
	count(distinct case when baby_gender = 'Male' then baby_patient_id else null end) "male_baby_count",
	count(distinct case when baby_gender = 'Female' then baby_patient_id else null end) "female_baby_count"
	from moh_postnatal_care_data
	group by site, reporting_date, timeframe_after_delivery) i 
	on i.site = f.site  and i.reporting_date = f.reporting_date and i.timeframe_after_delivery = f.timeframe;

update f set f.neonate_in_facility_male = 0 from final_table_staging f where f.neonate_in_facility_male is null;
update f set f.neonate_in_facility_female = 0 from final_table_staging f where f.neonate_in_facility_female is null;

DROP TABLE IF EXISTS moh_postnatal_care;
EXEC sp_rename 'final_table_staging', 'moh_postnatal_care';
