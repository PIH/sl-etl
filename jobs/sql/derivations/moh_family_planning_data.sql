drop table if exists moh_family_planning_data_staging; 
create table moh_family_planning_data_staging
(  
   moh_fp_id          int           IDENTITY(1,1) PRIMARY KEY, 
   site               varchar(50),  
   reporting_date     date,         
   encounter_id       varchar(50),  
   encounter_datetime datetime,     
   patient_id         varchar(50),  
   emr_id             varchar(50),  
   new_fp             bit,          
   age_at_encounter   int,          
   encounter_type     varchar(255), 
   fp_type            varchar(255), 
   index_asc          int,          
   index_desc         int           
); 

-- insert rows from inpatient postnatal encounter
insert into moh_family_planning_data_staging (encounter_id, patient_id, emr_id, encounter_datetime, site, age_at_encounter, encounter_type, fp_type)
select encounter_id, patient_id, emr_id, encounter_datetime, site, age_at_encounter, 'outpatient_pnc','Combined oral contraceptive pills'
from mch_pnc_encounter
where family_planning_method like '%Combined oral contraceptive pills%';

insert into moh_family_planning_data_staging (encounter_id, patient_id, emr_id, encounter_datetime, site, age_at_encounter, encounter_type, fp_type)
select encounter_id, patient_id, emr_id, encounter_datetime, site, age_at_encounter, 'outpatient_pnc', 'Natural family planning'
from mch_pnc_encounter
where family_planning_method like '%Natural family planning%';

insert into moh_family_planning_data_staging (encounter_id, patient_id, emr_id, encounter_datetime, site, age_at_encounter, encounter_type, fp_type)
select encounter_id, patient_id, emr_id, encounter_datetime, site, age_at_encounter, 'outpatient_pnc', 'Medroxyprogesterone acetate (Depo-provera)'
from mch_pnc_encounter
where family_planning_method like '%Medroxyprogesterone acetate (Depo-provera)%';

insert into moh_family_planning_data_staging (encounter_id, patient_id, emr_id, encounter_datetime, site, age_at_encounter, encounter_type, fp_type)
select encounter_id, patient_id, emr_id, encounter_datetime, site, age_at_encounter, 'outpatient_pnc', 'Intra uterine device (IUD)'
from mch_pnc_encounter
where family_planning_method like '%Intra uterine device (IUD)%';

insert into moh_family_planning_data_staging (encounter_id, patient_id, emr_id, encounter_datetime, site, age_at_encounter, encounter_type, fp_type)
select encounter_id, patient_id, emr_id, encounter_datetime, site, age_at_encounter, 'outpatient_pnc', 'Lactational amenorrhea'
from mch_pnc_encounter
where family_planning_method like '%Lactational amenorrhea%';

insert into moh_family_planning_data_staging (encounter_id, patient_id, emr_id, encounter_datetime, site, age_at_encounter, encounter_type, fp_type)
select encounter_id, patient_id, emr_id, encounter_datetime, site, age_at_encounter, 'outpatient_pnc', 'Condoms'
from mch_pnc_encounter
where family_planning_method like '%Condoms%';

insert into moh_family_planning_data_staging (encounter_id, patient_id, emr_id, encounter_datetime, site, age_at_encounter, encounter_type, fp_type)
select encounter_id, patient_id, emr_id, encounter_datetime, site, age_at_encounter, 'outpatient_pnc', 'Norethindrone'
from mch_pnc_encounter
where family_planning_method like '%Norethindrone%';

insert into moh_family_planning_data_staging (encounter_id, patient_id, emr_id, encounter_datetime, site, age_at_encounter, encounter_type, fp_type)
select encounter_id, patient_id, emr_id, encounter_datetime, site, age_at_encounter, 'outpatient_pnc', 'Jadelle (implantable contraceptive)'
from mch_pnc_encounter
where family_planning_method like '%Jadelle (implantable contraceptive)%';

insert into moh_family_planning_data_staging (encounter_id, patient_id, emr_id, encounter_datetime, site, age_at_encounter, encounter_type, fp_type)
select encounter_id, patient_id, emr_id, encounter_datetime, site, age_at_encounter, 'outpatient_pnc', 'Tubal ligation'
from mch_pnc_encounter
where family_planning_method like '%Tubal ligation%';

-- insert rows from outpatient pnc encounter 
insert into moh_family_planning_data_staging (encounter_id, patient_id, emr_id, encounter_datetime, site, age_at_encounter, encounter_type, fp_type)
select encounter_id, patient_id, emr_id, encounter_datetime, site, age_at_encounter, 'inpatient_pnc','Combined oral contraceptive pills'
from mch_postpartum_daily_encounter
where family_planning_method like '%Combined oral contraceptive pills%';

insert into moh_family_planning_data_staging (encounter_id, patient_id, emr_id, encounter_datetime, site, age_at_encounter, encounter_type, fp_type)
select encounter_id, patient_id, emr_id, encounter_datetime, site, age_at_encounter, 'inpatient_pnc', 'Natural family planning'
from mch_postpartum_daily_encounter
where family_planning_method like '%Natural family planning%';

insert into moh_family_planning_data_staging (encounter_id, patient_id, emr_id, encounter_datetime, site, age_at_encounter, encounter_type, fp_type)
select encounter_id, patient_id, emr_id, encounter_datetime, site, age_at_encounter, 'inpatient_pnc', 'Medroxyprogesterone acetate (Depo-provera)'
from mch_postpartum_daily_encounter
where family_planning_method like '%Medroxyprogesterone acetate (Depo-provera)%';

insert into moh_family_planning_data_staging (encounter_id, patient_id, emr_id, encounter_datetime, site, age_at_encounter, encounter_type, fp_type)
select encounter_id, patient_id, emr_id, encounter_datetime, site, age_at_encounter, 'inpatient_pnc', 'Intra uterine device (IUD)'
from mch_postpartum_daily_encounter
where family_planning_method like '%Intra uterine device (IUD)%';

insert into moh_family_planning_data_staging (encounter_id, patient_id, emr_id, encounter_datetime, site, age_at_encounter, encounter_type, fp_type)
select encounter_id, patient_id, emr_id, encounter_datetime, site, age_at_encounter, 'inpatient_pnc', 'Lactational amenorrhea'
from mch_postpartum_daily_encounter
where family_planning_method like '%Lactational amenorrhea%';

insert into moh_family_planning_data_staging (encounter_id, patient_id, emr_id, encounter_datetime, site, age_at_encounter, encounter_type, fp_type)
select encounter_id, patient_id, emr_id, encounter_datetime, site, age_at_encounter, 'inpatient_pnc', 'Condoms'
from mch_postpartum_daily_encounter
where family_planning_method like '%Condoms%';

insert into moh_family_planning_data_staging (encounter_id, patient_id, emr_id, encounter_datetime, site, age_at_encounter, encounter_type, fp_type)
select encounter_id, patient_id, emr_id, encounter_datetime, site, age_at_encounter, 'inpatient_pnc', 'Norethindrone'
from mch_postpartum_daily_encounter
where family_planning_method like '%Norethindrone%';

insert into moh_family_planning_data_staging (encounter_id, patient_id, emr_id, encounter_datetime, site, age_at_encounter, encounter_type, fp_type)
select encounter_id, patient_id, emr_id, encounter_datetime, site, age_at_encounter, 'inpatient_pnc', 'Jadelle (implantable contraceptive)'
from mch_postpartum_daily_encounter
where family_planning_method like '%Jadelle (implantable contraceptive)%';

insert into moh_family_planning_data_staging (encounter_id, patient_id, emr_id, encounter_datetime, site, age_at_encounter, encounter_type, fp_type)
select encounter_id, patient_id, emr_id, encounter_datetime, site, age_at_encounter, 'inpatient_pnc', 'Tubal ligation'
from mch_postpartum_daily_encounter
where family_planning_method like '%Tubal ligation%';
-- reporting date
update t 
set t.reporting_date = dd.LastDayOfMonth
from moh_family_planning_data_staging t 
inner join dim_date dd on dd.Date = cast(encounter_datetime as date); 

-- update index asc/desc 
drop table if exists #derived_indexes;
select  encounter_id,
        ROW_NUMBER() over (PARTITION by patient_id order by encounter_datetime, encounter_id) as index_asc,
        ROW_NUMBER() over (PARTITION by patient_id order by encounter_datetime DESC, encounter_id DESC) as index_desc
into    #derived_indexes
from    moh_family_planning_data_staging;

update t
set t.index_asc = i.index_asc,
    t.index_desc = i.index_desc
from moh_family_planning_data_staging t inner join #derived_indexes i on i.encounter_id = t.encounter_id
;

update moh_family_planning_data_staging 
set new_fp = 
case
	when index_asc = 1 then 1
	else 0
end;

DROP TABLE IF EXISTS moh_family_planning_data;
EXEC sp_rename 'moh_family_planning_data_staging', 'moh_family_planning_data';
