drop table if exists moh_family_planning_staging;
create table moh_family_planning_staging
(site                      varchar(50),
reporting_date             date,
fp_type                    varchar(255),
"new 10-14 yrs"            int,
"new 15-19 yrs"            int,
"new 20-24 yrs"            int,
"new 25+ yrs"              int,
continuing                 int
);

insert into moh_family_planning_staging (site, reporting_date, fp_type)
select distinct site, LastDayOfMonth, fp_type
from  dim_date   
cross join
(select v.site from
 (VALUES ('kgh'),('wellbody')) as v(site)) a
cross join 
(select v.fp_type from
 (VALUES ('Combined oral contraceptive pills'),('Condoms'),('Intra uterine device (IUD)'),
 	('Jadelle (implantable contraceptive)'),('Lactational amenorrhea'),('Medroxyprogesterone acetate (Depo-provera)'),
 	('Natural family planning'),('Norethindrone'),('Tubal ligation')) as v(fp_type)) b
where LastDayOfMonth >= '2023-01-01' and Date <= GETDATE();

drop table if exists #temp_aggregated_new; 
select site, reporting_date, fp_type,  
sum(case when age_at_encounter >= 10 and age_at_encounter <= 14 then 1 else null end) "new 10-14 yrs",
sum(case when age_at_encounter >= 15 and age_at_encounter <= 19 then 1 else null end) "new 15-19 yrs",
sum(case when age_at_encounter >= 20 and age_at_encounter <= 24 then 1 else null end) "new 20-24 yrs",
sum(case when age_at_encounter >= 25 then 1 else null end) "new 25+ yrs"
into #temp_aggregated_new
from moh_family_planning_data
where new_fp = 1 
group by site, reporting_date, fp_type;

update f 
set f."new 10-14 yrs" = t."new 10-14 yrs",
	f."new 15-19 yrs" = t."new 15-19 yrs",
	f."new 20-24 yrs" = t."new 20-24 yrs",
	f."new 25+ yrs" = t."new 25+ yrs" 
from moh_family_planning_staging f 
inner join #temp_aggregated_new t on f.site = t.site and f.reporting_date = t.reporting_date and f.fp_type = t.fp_type;

update f 
set f.continuing = i.continuing
from  moh_family_planning_staging f 
inner join 
	(select site, reporting_date, fp_type, count(*) "continuing"
	from moh_family_planning_data 
	where new_fp = 0
	group by site, reporting_date, fp_type) i 
on f.site = i.site and f.reporting_date = i.reporting_date and f.fp_type = i.fp_type;

DROP TABLE IF EXISTS moh_family_planning;
EXEC sp_rename 'moh_family_planning_staging', 'moh_family_planning';
