DROP TABLE IF EXISTS all_admissions_staging;
CREATE TABLE all_admissions_staging
(
  patient_id                        varchar(50),
  emr_id                            varchar(15), 
  encounter_id                      varchar(50), 
  visit_id                          varchar(255),
  encounter_type                    varchar(50), 
  start_datetime                    datetime,    
  end_datetime                      datetime,   
  ward_length_days                  int,
  hospital_start_datetime           datetime,
  hospital_end_datetime             datetime,
  hospital_length_days               int,
  user_entered                      varchar(255),
  date_entered                      date,        
  encounter_location                varchar(255),
  mcoe_location                     bit,
  provider                          varchar(255),
  previous_disposition_encounter_id varchar(50), 
  previous_disposition_datetime     datetime,    
  previous_disposition              varchar(255),
  ending_disposition_encounter_id   varchar(50), 
  ending_disposition_datetime       datetime,    
  ending_disposition                varchar(255),
  site                              varchar(255),
  partition_num                     int  
);

INSERT INTO all_admissions_staging (
  patient_id, emr_id, encounter_id, visit_id, encounter_type, start_datetime,
  end_datetime, user_entered, date_entered, encounter_location, mcoe_location, provider, site, partition_num
)
SELECT
  patient_id, 
  emr_id,
  encounter_id,
  visit_id,
  encounter_type,
  encounter_datetime AS start_datetime,
  LAG(encounter_datetime) OVER (PARTITION BY emr_id ORDER BY encounter_datetime DESC) AS end_datetime,
  user_entered AS creator,
  datetime_created AS date_entered,
  encounter_location,
  mcoe_location,
  provider,
  site,
  partition_num
FROM adt_encounters ae;

DELETE FROM all_admissions_staging WHERE encounter_type = 'Exit from Inpatient Care';

-- update end datetime based on visit end date
UPDATE a
SET end_datetime = v.visit_date_stopped
FROM all_admissions_staging a
INNER JOIN all_visits v ON v.visit_id = a.visit_id
WHERE v.visit_date_stopped < a.end_datetime;

-- set previous disposition based on latest prior encounter with a disposition
update a 
 set previous_disposition_datetime = e.encounter_datetime,
 	 previous_disposition = e.disposition,
 	 previous_disposition_encounter_id = e.encounter_id
from all_admissions_staging a
inner join all_encounters e on e.encounter_id = 
	(select top 1 e2.encounter_id from all_encounters e2
	where e2.emr_id = a.emr_id 
	and e2.encounter_datetime <= a.start_datetime
	and e2.disposition is not null
	order by e2.encounter_datetime desc, e2.encounter_id desc);

-- set ending disposition based on latest encounter on or before end_datetime
update a 
 set ending_disposition_datetime = e.encounter_datetime,
 	 ending_disposition = e.disposition,
 	 ending_disposition_encounter_id = e.encounter_id
from all_admissions_staging a
inner join all_encounters e on e.encounter_id = 
	(select top 1 e2.encounter_id from all_encounters e2
	where e2.emr_id = a.emr_id 
	and e2.encounter_datetime <= a.end_datetime
	and e2.encounter_datetime >= a.start_datetime
	and e2.disposition is not null
	order by e2.encounter_datetime desc, e2.encounter_id desc);	

-- update rows based on closed visits. Note that these won't have ending disposition info
UPDATE a
SET end_datetime = v.visit_date_stopped
FROM all_admissions_staging a
INNER JOIN all_visits v ON a.visit_id = v.visit_id
WHERE a.end_datetime IS NULL;

drop table if exists #temp_hospital_datetimes;
select patient_id, visit_id, min(start_datetime) "min_start_datetime", max(end_datetime) "max_start_datetime"
 into #temp_hospital_datetimes
from all_admissions_staging
group by patient_id, visit_id; 

update a
set hospital_start_datetime = min_start_datetime,
	hospital_end_datetime = max_start_datetime
FROM all_admissions_staging a
INNER JOIN #temp_hospital_datetimes t ON t.visit_id = a.visit_id and t.patient_id = a.patient_id;

update a
set ward_length_days =  DATEDIFF(day, start_datetime, end_datetime)
from all_admissions_staging a; 

update a
set hospital_length_days =  DATEDIFF(day, hospital_start_datetime, hospital_end_datetime)
from all_admissions_staging a; 

DROP TABLE IF EXISTS all_admissions;
EXEC sp_rename 'dbo.all_admissions_staging', 'all_admissions';
