-- indicators at the delivered baby level (mch_delivery_summary_encounter)
drop TABLE if exists moh_maternity_and_delivery_data_staging;
create table moh_maternity_and_delivery_data_staging
(site                             varchar(50),  
baby_obs_id                       varchar(50),  
pregnancy_program_id              varchar(50),  
reporting_date                    date,         
age_category                      varchar(50),  
outcome                           varchar(255), 
birth_weight                      float,        
delivery_method                   varchar(255), 
oxytocin_for_hemorrhage           bit,          
misoprostol_for_hemorrhage        bit,          
gestational_age                   int,          
partogram_uploaded                bit,          
birthdate                         datetime,     
breastfeeding_initiation_datetime datetime,      
labor_progress_form_entered       bit,
postpartum_progress_form_entered  bit
);

-- disaggregate deliveries into reporting_date, age categories
insert into moh_maternity_and_delivery_data_staging (site, baby_obs_id, pregnancy_program_id, reporting_date, age_category, outcome, birth_weight, delivery_method, birthdate)
select 
site, 
baby_obs_id,
pregnancy_program_id,
dd.LastDayOfMonth, 
CASE
	when mother_age_at_encounter < 0 then '<10'
	when mother_age_at_encounter < 15 then '10-14'
	when mother_age_at_encounter < 20 then '15-19'
	when mother_age_at_encounter < 26 then '20-25'
	else'26+'
END "age_category",
outcome, 
birth_weight, 
delivery_method,
birthdate
from mch_delivery_summary_encounter d
inner join dim_date dd on dd.Date = cast(d.encounter_datetime as date);

update d 
set d.breastfeeding_initiation_datetime = l.breastfeeding_initiation_datetime
from moh_maternity_and_delivery_data_staging d 
inner join mch_labor_summary_encounter l on l.encounter_id = 
(select top 1 l2.encounter_id  
from mch_labor_summary_encounter l2
where l2.pregnancy_program_id = d.pregnancy_program_id
order by l2.encounter_datetime desc);

update d 
set d.oxytocin_for_hemorrhage = l.oxytocin_for_hemorrhage,
	d.misoprostol_for_hemorrhage = l.misoprostol_for_hemorrhage,
	d.postpartum_progress_form_entered = 1
from moh_maternity_and_delivery_data_staging d 
inner join mch_postpartum_daily_encounter l on l.encounter_id = 
(select top 1 l2.encounter_id  
from mch_postpartum_daily_encounter l2
where l2.pregnancy_program_id = d.pregnancy_program_id
order by l2.encounter_datetime desc);


update d 
set d.gestational_age = l.gestational_age,
	d.partogram_uploaded = l.partogram_uploaded,
	d.labor_progress_form_entered = 1
from moh_maternity_and_delivery_data_staging d 
inner join mch_labor_progress_encounter l on l.encounter_id = 
(select top 1 l2.encounter_id  
from mch_labor_progress_encounter l2
where l2.pregnancy_program_id = d.pregnancy_program_id
order by l2.encounter_datetime desc);

update d 
set d.gestational_age = p.estimated_gestational_age
from moh_maternity_and_delivery_data_staging d 
inner join mch_pregnancy_summary p on p.pregnancy_program_id = d.pregnancy_program_id 
where d.gestational_age is null;

DROP TABLE IF EXISTS moh_maternity_and_delivery_data;
EXEC sp_rename 'moh_maternity_and_delivery_data_staging', 'moh_maternity_and_delivery_data';
