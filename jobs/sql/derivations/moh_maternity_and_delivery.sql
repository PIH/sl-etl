drop table if exists final_maternal_table_staging;
create table final_maternal_table_staging
(site          varchar(50),
reporting_date date,
indicator_name varchar(50),
"<10"         int,
"10-14"        int,
"15-19"        int,
"20-25"        int,
"26+"          int);

insert into final_maternal_table_staging (site, reporting_date, indicator_name)
select distinct site, LastDayOfMonth, indicator_name from  dim_date   
cross join 
	(select v.indicator_name from
	 (VALUES ('number_of_deliveries'),
	('live_birth_facility'), 
	('fsb_facility'), 
	('msb_facility'), 
	('uterotonic_prophylactic_after_delivery'), 
	('birth_weighed_24_hours'), 
	('birth_weight_<2.5kg'),
	('live_birth_≤36wks'),  
	('birth_breastfed_within_1hr'), 
	('delivery_monitored_partograph'), 
	('normal_delivery'),
	('assisted_vaginal_delivery'), 
	('cesarean_section')) as v(indicator_name)) a 
cross join
(select v.site from
 (VALUES ('kgh'),('wellbody')) as v(site)) b
where LastDayOfMonth >= '2023-01-01' and Date <= GETDATE();

-- total deliveries
update f 
set f."<10" = i."<10",
	f."10-14" = i."10-14",
	f."15-19" = i."15-19",
	f."20-25" = i."20-25",
	f."26+" = i."26+"	
from final_maternal_table_staging f
inner join
	(select site, reporting_date, 
	SUM(case when age_category = '<10' then 1 else 0 end) "<10",
	SUM(case when age_category = '10-14' then 1 else 0 end) "10-14",
	SUM(case when age_category = '15-19' then 1 else 0 end) "15-19",
	SUM(case when age_category = '20-25' then 1 else 0 end) "20-25",
	SUM(case when age_category = '26+' then 1 else 0 end) "26+"
	from moh_maternity_and_delivery_data
	group by site, reporting_date) i 
	on i.site = f.site and i.reporting_date = f.reporting_date
where f.indicator_name = 'number_of_deliveries'	
;

-- livebirths
update f 
set f."<10" = i."<10",
	f."10-14" = i."10-14",
	f."15-19" = i."15-19",
	f."20-25" = i."20-25",
	f."26+" = i."26+"	
from final_maternal_table_staging f
inner join
	(select site, reporting_date, 
SUM(case when outcome = 'Livebirth' and age_category = '<10' then 1 else 0 end) "<10",
	SUM(case when outcome = 'Livebirth' and age_category = '10-14' then 1 else 0 end) "10-14",
	SUM(case when outcome = 'Livebirth' and age_category = '15-19' then 1 else 0 end) "15-19",
	SUM(case when outcome = 'Livebirth' and age_category = '20-25' then 1 else 0 end) "20-25",
	SUM(case when outcome = 'Livebirth' and age_category = '26+' then 1 else 0 end) "26+"
	from moh_maternity_and_delivery_data
	group by site, reporting_date) i 
	on i.site = f.site and i.reporting_date = f.reporting_date
where f.indicator_name = 'live_birth_facility'	
;

-- fsb
update f 
set f."<10" = i."<10",
	f."10-14" = i."10-14",
	f."15-19" = i."15-19",
	f."20-25" = i."20-25",
	f."26+" = i."26+"	
from final_maternal_table_staging f
inner join
	(select site, reporting_date, 
SUM(case when outcome = 'Fresh stillbirth' and age_category = '<10' then 1 else 0 end) "<10",
	SUM(case when outcome = 'Fresh stillbirth' and age_category = '10-14' then 1 else 0 end) "10-14",
	SUM(case when outcome = 'Fresh stillbirth' and age_category = '15-19' then 1 else 0 end) "15-19",
	SUM(case when outcome = 'Fresh stillbirth' and age_category = '20-25' then 1 else 0 end) "20-25",
	SUM(case when outcome = 'Fresh stillbirth' and age_category = '26+' then 1 else 0 end) "26+"
	from moh_maternity_and_delivery_data
	group by site, reporting_date) i 
	on i.site = f.site and i.reporting_date = f.reporting_date
where f.indicator_name = 'fsb_facility'	
;

-- msb
update f 
set f."<10" = i."<10",
	f."10-14" = i."10-14",
	f."15-19" = i."15-19",
	f."20-25" = i."20-25",
	f."26+" = i."26+"	
from final_maternal_table_staging f
inner join
	(select site, reporting_date, 
SUM(case when outcome = 'Macerated stillbirth' and age_category = '<10' then 1 else 0 end) "<10",
	SUM(case when outcome = 'Macerated stillbirth' and age_category = '10-14' then 1 else 0 end) "10-14",
	SUM(case when outcome = 'Macerated stillbirth' and age_category = '15-19' then 1 else 0 end) "15-19",
	SUM(case when outcome = 'Macerated stillbirth' and age_category = '20-25' then 1 else 0 end) "20-25",
	SUM(case when outcome = 'Macerated stillbirth' and age_category = '26+' then 1 else 0 end) "26+"
	from moh_maternity_and_delivery_data
	group by site, reporting_date) i 
	on i.site = f.site and i.reporting_date = f.reporting_date
where f.indicator_name = 'msb_facility'	
;

-- birth weighed
update f 
set f."<10" = i."<10",
	f."10-14" = i."10-14",
	f."15-19" = i."15-19",
	f."20-25" = i."20-25",
	f."26+" = i."26+"	
from final_maternal_table_staging f
inner join
	(select site, reporting_date, 
	SUM(case when birth_weight is not null and age_category = '<10' then 1 else 0 end) "<10",
	SUM(case when birth_weight is not null and age_category = '10-14' then 1 else 0 end) "10-14",
	SUM(case when birth_weight is not null and age_category = '15-19' then 1 else 0 end) "15-19",
	SUM(case when birth_weight is not null and age_category = '20-25' then 1 else 0 end) "20-25",
	SUM(case when birth_weight is not null and age_category = '26+' then 1 else 0 end) "26+"
	from moh_maternity_and_delivery_data
	group by site, reporting_date) i 
	on i.site = f.site and i.reporting_date = f.reporting_date
where f.indicator_name = 'birth_weighed_24_hours'	
;

-- birth weight < 2.5kg
update f 
set f."<10" = i."<10",
	f."10-14" = i."10-14",
	f."15-19" = i."15-19",
	f."20-25" = i."20-25",
	f."26+" = i."26+"	
from final_maternal_table_staging f
inner join
	(select site, reporting_date, 
	SUM(case when birth_weight < 2.5 and age_category = '<10' then 1 else 0 end) "<10",
	SUM(case when birth_weight < 2.5 and age_category = '10-14' then 1 else 0 end) "10-14",
	SUM(case when birth_weight < 2.5 and age_category = '15-19' then 1 else 0 end) "15-19",
	SUM(case when birth_weight < 2.5 and age_category = '20-25' then 1 else 0 end) "20-25",
	SUM(case when birth_weight < 2.5 and age_category = '26+' then 1 else 0 end) "26+"
	from moh_maternity_and_delivery_data
	group by site, reporting_date) i 
	on i.site = f.site and i.reporting_date = f.reporting_date
where f.indicator_name = 'birth_weight_<2.5kg'	
;

-- normal_delivery
update f 
set f."<10" = i."<10",
	f."10-14" = i."10-14",
	f."15-19" = i."15-19",
	f."20-25" = i."20-25",
	f."26+" = i."26+"	
from final_maternal_table_staging f
inner join
	(select site, reporting_date, 
	SUM(case when delivery_method = 'Spontaneous vaginal delivery' and age_category = '<10' then 1 else 0 end) "<10",
	SUM(case when delivery_method = 'Spontaneous vaginal delivery' and age_category = '10-14' then 1 else 0 end) "10-14",
	SUM(case when delivery_method = 'Spontaneous vaginal delivery' and age_category = '15-19' then 1 else 0 end) "15-19",
	SUM(case when delivery_method = 'Spontaneous vaginal delivery' and age_category = '20-25' then 1 else 0 end) "20-25",
	SUM(case when delivery_method = 'Spontaneous vaginal delivery' and age_category = '26+' then 1 else 0 end) "26+"
	from moh_maternity_and_delivery_data
	group by site, reporting_date) i 
	on i.site = f.site and i.reporting_date = f.reporting_date
where f.indicator_name = 'normal_delivery'	
;

-- Delivery by cesarean section
update f 
set f."<10" = i."<10",
	f."10-14" = i."10-14",
	f."15-19" = i."15-19",
	f."20-25" = i."20-25",
	f."26+" = i."26+"	
from final_maternal_table_staging f
inner join
	(select site, reporting_date, 
	SUM(case when delivery_method = 'Delivery by cesarean section' and age_category = '<10' then 1 else 0 end) "<10",
	SUM(case when delivery_method = 'Delivery by cesarean section' and age_category = '10-14' then 1 else 0 end) "10-14",
	SUM(case when delivery_method = 'Delivery by cesarean section' and age_category = '15-19' then 1 else 0 end) "15-19",
	SUM(case when delivery_method = 'Delivery by cesarean section' and age_category = '20-25' then 1 else 0 end) "20-25",
	SUM(case when delivery_method = 'Delivery by cesarean section' and age_category = '26+' then 1 else 0 end) "26+"
	from moh_maternity_and_delivery_data
	group by site, reporting_date) i 
	on i.site = f.site and i.reporting_date = f.reporting_date
where f.indicator_name = 'cesarean_section'	
;

-- assisted_vaginal_delivery
update f 
set f."<10" = i."<10",
	f."10-14" = i."10-14",
	f."15-19" = i."15-19",
	f."20-25" = i."20-25",
	f."26+" = i."26+"	
from final_maternal_table_staging f
inner join
	(select site, reporting_date, 
	SUM(case when delivery_method = 'Delivery by vacuum extraction' and age_category = '<10' then 1 else 0 end) "<10",
	SUM(case when delivery_method = 'Delivery by vacuum extraction' and age_category = '10-14' then 1 else 0 end) "10-14",
	SUM(case when delivery_method = 'Delivery by vacuum extraction' and age_category = '15-19' then 1 else 0 end) "15-19",
	SUM(case when delivery_method = 'Delivery by vacuum extraction' and age_category = '20-25' then 1 else 0 end) "20-25",
	SUM(case when delivery_method = 'Delivery by vacuum extraction' and age_category = '26+' then 1 else 0 end) "26+"
	from moh_maternity_and_delivery_data
	group by site, reporting_date) i 
	on i.site = f.site and i.reporting_date = f.reporting_date
where f.indicator_name = 'assisted_vaginal_delivery';

-- uterotonic_prophylactic_after_delivery
update f
set f."<10"   = i."<10",
    f."10-14" = i."10-14",
    f."15-19" = i."15-19",
    f."20-25" = i."20-25",
    f."26+"   = i."26+"
from final_maternal_table_staging f
inner join
(
  select site, reporting_date,
    COUNT(DISTINCT CASE WHEN (oxytocin_for_hemorrhage =1 OR misoprostol_for_hemorrhage = 1)
                        AND age_category = '<10' THEN pregnancy_program_id END)   as "<10",
    COUNT(DISTINCT CASE WHEN (oxytocin_for_hemorrhage =1 OR misoprostol_for_hemorrhage = 1)
                        AND age_category = '10-14' THEN pregnancy_program_id END) as "10-14",
    COUNT(DISTINCT CASE WHEN (oxytocin_for_hemorrhage =1 OR misoprostol_for_hemorrhage = 1)
                        AND age_category = '15-19' THEN pregnancy_program_id END) as "15-19",
    COUNT(DISTINCT CASE WHEN (oxytocin_for_hemorrhage =1 OR misoprostol_for_hemorrhage = 1)
                        AND age_category = '20-25' THEN pregnancy_program_id END) as "20-25",
    COUNT(DISTINCT CASE WHEN (oxytocin_for_hemorrhage =1 OR misoprostol_for_hemorrhage = 1)
                        AND age_category = '26+' THEN pregnancy_program_id END) as "26+"
  from moh_maternity_and_delivery_data
  group by site, reporting_date
) i
  on i.site = f.site and i.reporting_date = f.reporting_date
where f.indicator_name = 'uterotonic_prophylactic_after_delivery';

-- live_birth_=36wks
update f 
set f."<10" = i."<10",
	f."10-14" = i."10-14",
	f."15-19" = i."15-19",
	f."20-25" = i."20-25",
	f."26+" = i."26+"	
from final_maternal_table_staging f
inner join
	(select site, reporting_date, 
	SUM(case when outcome = 'Livebirth' and gestational_age <= 36 and age_category = '<10' then 1 else 0 end) "<10",
	SUM(case when outcome = 'Livebirth' and gestational_age <= 36 and age_category = '10-14' then 1 else 0 end) "10-14",
	SUM(case when outcome = 'Livebirth' and gestational_age <= 36 and age_category = '15-19' then 1 else 0 end) "15-19",
	SUM(case when outcome = 'Livebirth' and gestational_age <= 36 and age_category = '20-25' then 1 else 0 end) "20-25",
	SUM(case when outcome = 'Livebirth' and gestational_age <= 36 and age_category = '26+' then 1 else 0 end) "26+"
	from moh_maternity_and_delivery_data
	group by site, reporting_date) i 
	on i.site = f.site and i.reporting_date = f.reporting_date
where f.indicator_name = 'live_birth_=36wks';

-- delivery_monitored_partograph
update f 
set f."<10" = i."<10",
	f."10-14" = i."10-14",
	f."15-19" = i."15-19",
	f."20-25" = i."20-25",
	f."26+" = i."26+"	
from final_maternal_table_staging f
inner join
	(select site, reporting_date, 
	SUM(case when partogram_uploaded = 1 and age_category = '<10' then 1 else 0 end) "<10",
	SUM(case when partogram_uploaded = 1 and age_category = '10-14' then 1 else 0 end) "10-14",
	SUM(case when partogram_uploaded = 1 and age_category = '15-19' then 1 else 0 end) "15-19",
	SUM(case when partogram_uploaded = 1 and age_category = '20-25' then 1 else 0 end) "20-25",
	SUM(case when partogram_uploaded = 1 and age_category = '26+' then 1 else 0 end) "26+"
	from moh_maternity_and_delivery_data
	group by site, reporting_date) i 
	on i.site = f.site and i.reporting_date = f.reporting_date
where f.indicator_name = 'delivery_monitored_partograph';

-- birth_breastfed_within_1hr
update f 
set f."<10" = i."<10",
	f."10-14" = i."10-14",
	f."15-19" = i."15-19",
	f."20-25" = i."20-25",
	f."26+" = i."26+"	
from final_maternal_table_staging f
inner join
	(select site, reporting_date, 
	SUM(case when DATEDIFF(MINUTE, breastfeeding_initiation_datetime, birthdate) <= 60 and age_category = '<10' then 1 else 0 end) "<10",
	SUM(case when DATEDIFF(MINUTE, breastfeeding_initiation_datetime, birthdate) <= 60 and age_category = '10-14' then 1 else 0 end) "10-14",
	SUM(case when DATEDIFF(MINUTE, breastfeeding_initiation_datetime, birthdate) <= 60 and age_category = '15-19' then 1 else 0 end) "15-19",
	SUM(case when DATEDIFF(MINUTE, breastfeeding_initiation_datetime, birthdate) <= 60 and age_category = '20-25' then 1 else 0 end) "20-25",
	SUM(case when DATEDIFF(MINUTE, breastfeeding_initiation_datetime, birthdate) <= 60 and age_category = '26+' then 1 else 0 end) "26+"
	from moh_maternity_and_delivery_data
	group by site, reporting_date) i 
	on i.site = f.site and i.reporting_date = f.reporting_date
where f.indicator_name = 'birth_breastfed_within_1hr';

update f set "<10" = 0 from final_maternal_table_staging f where "<10" is null;
update f set "10-14" = 0 from final_maternal_table_staging f where "10-14" is null;
update f set "15-19" = 0 from final_maternal_table_staging f where "15-19" is null;
update f set "20-25" = 0 from final_maternal_table_staging f where "20-25" is null;
update f set "26+" = 0 from final_maternal_table_staging f where "26+" is null;

DROP TABLE IF EXISTS moh_maternity_and_delivery;
EXEC sp_rename 'final_maternal_table_staging', 'moh_maternity_and_delivery';
