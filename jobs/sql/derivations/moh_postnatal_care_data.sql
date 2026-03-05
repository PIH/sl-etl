drop table if exists moh_postnatal_care_data_staging;
create table moh_postnatal_care_data_staging 
(site                    varchar(50),   
reporting_date           date,         
mother_patient_id        varchar(50),  
baby_patient_id          varchar(50),  
pregnancy_program_id     varchar(50),  
mother_emr_id            varchar(50),  
baby_emr_id              varchar(50),  
baby_gender              varchar(50),  
encounter_id             varchar(50),  
encounter_datetime       datetime,     
encounter_type           varchar(255), 
delivery_datetime        datetime,     
days_after_delivery      int,          
timeframe_after_delivery varchar(50));  

-- insert rows for outpatient postnatal care followup 
insert into moh_postnatal_care_data_staging (site, mother_patient_id, pregnancy_program_id, mother_emr_id, encounter_id, encounter_datetime, encounter_type, baby_patient_id, baby_emr_id, baby_gender, delivery_datetime, days_after_delivery)
select mpe.site, mpe.patient_id, mpe.pregnancy_program_id, mpe.emr_id, mpe.encounter_id, mpe.encounter_datetime, 'Postnatal Followup',  mdse.patient_id , 
mdse.emr_id , mdse.sex , mdse.encounter_datetime, datediff(day, mdse.encounter_datetime, mpe.encounter_datetime) 
from mch_pnc_encounter mpe
inner join mch_delivery_summary_encounter mdse on mdse.pregnancy_program_id = mpe.pregnancy_program_id
where datediff(day, mdse.encounter_datetime, mpe.encounter_datetime) between 0 and 42;

-- insert rows for inpatient postnatal care followup 
insert into moh_postnatal_care_data_staging (site, mother_patient_id, pregnancy_program_id, mother_emr_id, encounter_id, encounter_datetime, encounter_type, baby_patient_id, baby_emr_id, baby_gender, delivery_datetime, days_after_delivery)
select mpe.site, mpe.patient_id, mpe.pregnancy_program_id, mpe.emr_id, mpe.encounter_id, mpe.encounter_datetime, 'Postnatal progress',  mdse.patient_id , 
mdse.emr_id , mdse.sex , mdse.encounter_datetime, datediff(day, mdse.encounter_datetime, mpe.encounter_datetime) 
from mch_postpartum_daily_encounter mpe
inner join mch_delivery_summary_encounter mdse on mdse.pregnancy_program_id = mpe.pregnancy_program_id
where datediff(day, mdse.encounter_datetime, mpe.encounter_datetime) between 0 and 42;

update t 
set t.reporting_date = dd.LastDayOfMonth
from moh_postnatal_care_data_staging t 
inner join dim_date dd on dd.Date = cast(encounter_datetime as date); 
 
update t 
set t.timeframe_after_delivery = 
case
	when days_after_delivery < 2 then 'within 24 hours'
	when days_after_delivery < 8 then '2-7 days'
	else '8 days to 6 weeks'
end
from moh_postnatal_care_data_staging t; 

DROP TABLE IF EXISTS moh_postnatal_care_data;
EXEC sp_rename 'moh_postnatal_care_data_staging', 'moh_postnatal_care_data';
