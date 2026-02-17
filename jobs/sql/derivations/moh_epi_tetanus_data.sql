drop table if exists moh_epi_tetanus_data_staging;
create table moh_epi_tetanus_data_staging
(site                        varchar(255),  
obs_id                       varchar(50),  
mcoe_location                bit,          
pregnancy_program_id         varchar(50),  
pregnancy_state              varchar(255), 
reporting_date               date,         
immunization                 varchar(255), 
immunization_date            date,         
immunization_sequence_number int);         

insert into moh_epi_tetanus_data_staging (site, obs_id, mcoe_location, pregnancy_program_id, immunization, immunization_date, immunization_sequence_number)
select site, obs_id, mcoe_location, pregnancy_program_id, immunization, immunization_date, immunization_sequence_number from all_immunizations;
	
UPDATE e
SET e.pregnancy_state = s.state
FROM moh_epi_tetanus_data_staging e
CROSS APPLY (
    SELECT TOP 1 s.state
    FROM mch_pregnancy_state s
    WHERE s.pregnancy_program_id = e.pregnancy_program_id
      AND s.state_start_date <= e.immunization_date
      AND s.state_end_date >= e.immunization_date
    ORDER BY s.state_start_date DESC   -- most recent
) s;

update e  
set e.reporting_date = dd.LastDayOfMonth
from moh_epi_tetanus_data_staging e 
inner join dim_date dd on dd.date = e.immunization_date;

DROP TABLE IF EXISTS moh_epi_tetanus_data;
EXEC sp_rename 'moh_epi_tetanus_data_staging', 'moh_epi_tetanus_data';
