drop table if exists final_epi_table_staging;
create table final_epi_table_staging
(site                 varchar(50),
mcoe                  bit,
reporting_date        date,
immunization_category varchar(50),
pregnant              int,
non_pregnant          int);

insert into final_epi_table_staging (site, mcoe, reporting_date, immunization_category)
select distinct site, mcoe, LastDayOfMonth, immunization_category from  dim_date   
cross join 
	(select v.immunization_category from
	 (VALUES ('Td 1st dose'),
	('Td 2nd Dose'), 
	('Td 3rd Dose'), 
	('Td 4th Dose'), 
    ('Td 5th Dose')) as v(immunization_category)) a 
cross join
(select v.site from
 (VALUES ('kgh'),('wellbody')) as v(site)) b
left outer join
(select v.mcoe from
 (VALUES ('1'),('0')) as v(mcoe)) c on site = 'kgh'
where LastDayOfMonth >= '2023-01-01' and Date <= GETDATE();

update f 
set f.pregnant = i."1st_dose_pregnant",
	f.non_pregnant = i."1st_dose_non_pregnant"	
from final_epi_table_staging f
inner join 
	(select site, mcoe_location, reporting_date, 
	SUM(case when immunization = 'Td booster' and immunization_sequence_number = 0 and pregnancy_state = 'Antenatal' then 1 else 0 end) "1st_dose_pregnant",
	SUM(case when immunization = 'Td booster' and immunization_sequence_number = 0 and (pregnancy_state <> 'Antenatal' or pregnancy_state is null) then 1 else 0 end) "1st_dose_non_pregnant"
	from moh_epi_tetanus_data e 
	where reporting_date is not NULL 
	group by site, mcoe_location, reporting_date) i 
	on i.site = f.site and i.mcoe_location = f.mcoe and i.reporting_date = f.reporting_date
where f.immunization_category = 'Td 1st dose';	
	
update f 
set f.pregnant = i."2nd_dose_pregnant",
	f.non_pregnant = i."2nd_dose_non_pregnant"	
from final_epi_table_staging f
inner join 
	(select site, mcoe_location, reporting_date, 
	SUM(case when immunization = 'Td booster' and immunization_sequence_number = 1 and pregnancy_state = 'Antenatal' then 1 else 0 end) "2nd_dose_pregnant",
	SUM(case when immunization = 'Td booster' and immunization_sequence_number = 1 and (pregnancy_state <> 'Antenatal' or pregnancy_state is null) then 1 else 0 end) "2nd_dose_non_pregnant"
	from moh_epi_tetanus_data e 
	where reporting_date is not NULL 
	group by site, mcoe_location, reporting_date) i 
	on i.site = f.site and i.mcoe_location = f.mcoe and i.reporting_date = f.reporting_date
where f.immunization_category = 'Td 2nd dose';	
	
update f 
set f.pregnant = i."3rd_dose_pregnant",
	f.non_pregnant = i."3rd_dose_non_pregnant"	
from final_epi_table_staging f
inner join 
	(select site, mcoe_location, reporting_date, 
	SUM(case when immunization = 'Td booster' and immunization_sequence_number = 2 and pregnancy_state = 'Antenatal' then 1 else 0 end) "3rd_dose_pregnant",
	SUM(case when immunization = 'Td booster' and immunization_sequence_number = 2 and (pregnancy_state <> 'Antenatal' or pregnancy_state is null) then 1 else 0 end) "3rd_dose_non_pregnant"
	from moh_epi_tetanus_data e 
	where reporting_date is not NULL 
	group by site, mcoe_location, reporting_date) i 
	on i.site = f.site and i.mcoe_location = f.mcoe and i.reporting_date = f.reporting_date
where f.immunization_category = 'Td 3rd dose';	

update f 
set f.pregnant = i."4th_dose_pregnant",
	f.non_pregnant = i."4th_dose_non_pregnant"	
from final_epi_table_staging f
inner join 
	(select site, mcoe_location, reporting_date, 
	SUM(case when immunization = 'Td booster' and immunization_sequence_number = 3 and pregnancy_state = 'Antenatal' then 1 else 0 end) "4th_dose_pregnant",
	SUM(case when immunization = 'Td booster' and immunization_sequence_number = 3 and (pregnancy_state <> 'Antenatal' or pregnancy_state is null) then 1 else 0 end) "4th_dose_non_pregnant"
	from moh_epi_tetanus_data e 
	where reporting_date is not NULL 
	group by site, mcoe_location, reporting_date) i 
	on i.site = f.site and i.mcoe_location = f.mcoe and i.reporting_date = f.reporting_date
where f.immunization_category = 'Td 4th dose'
;	


update f 
set f.pregnant = i."5th_dose_pregnant",
	f.non_pregnant = i."5th_dose_non_pregnant"	
from final_epi_table_staging f
inner join 
	(select site, mcoe_location, reporting_date, 
	SUM(case when immunization = 'Td booster' and immunization_sequence_number = 4 and pregnancy_state = 'Antenatal' then 1 else 0 end) "5th_dose_pregnant",
	SUM(case when immunization = 'Td booster' and immunization_sequence_number = 4 and (pregnancy_state <> 'Antenatal' or pregnancy_state is null) then 1 else 0 end) "5th_dose_non_pregnant"
	from moh_epi_tetanus_data e 
	where reporting_date is not NULL 
	group by site, mcoe_location, reporting_date) i 
	on i.site = f.site and i.mcoe_location = f.mcoe and i.reporting_date = f.reporting_date
where f.immunization_category = 'Td 5th dose';	

DROP TABLE IF EXISTS moh_epi_tetanus;
EXEC sp_rename 'final_epi_table_staging', 'moh_epi_tetanus';
