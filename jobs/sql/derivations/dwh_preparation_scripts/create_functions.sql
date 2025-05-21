DROP FUNCTION IF EXISTS estimated_gestational_age;
CREATE FUNCTION estimated_gestational_age(@pregnancy_program_id varchar(50), @actual_delivery_date date, @latest_lmp_entered date)
RETURNS float
AS
BEGIN
	
DECLARE @estimated_gestational_age_entered            float,
        @estimated_gestational_age_entered_datetime   datetime,
        @pregnancy_calculation_end_date               datetime,
        @estimated_gestational_age_entered_calculated float,
        @estimated_gestational_age                    float
    
 -- retrieve latest gestational age entered and the corresponding datetime   
	select top 1 @estimated_gestational_age_entered = estimated_gestational_age,
				@estimated_gestational_age_entered_datetime = encounter_datetime
	from 
	(select estimated_gestational_age, encounter_datetime
	from mch_anc_encounter e
	where e.pregnancy_program_id = @pregnancy_program_id
	and estimated_gestational_age is not null
	union
	select gestational_age, lpe.encounter_datetime  from labor_progress_encounter lpe
	where pregnancy_program_id = @pregnancy_program_id
	and  lpe.gestational_age is not null) a
	order by encounter_datetime desc
 
 -- gestational age will be calculated through the current date or actual delivery date, if patient has delivered
	set @pregnancy_calculation_end_date = iif(@actual_delivery_date is not null, @actual_delivery_date, getdate()) 

-- if entered, gestational age is adjusted through the calculation end date	
	set @estimated_gestational_age_entered_calculated =  datediff(week, @estimated_gestational_age_entered_datetime, @pregnancy_calculation_end_date) + @estimated_gestational_age_entered

-- set estimated_gestational_age as previously calculated unless latest lmp has been entered, then calculate from that date 
	set @estimated_gestational_age = 
	CASE
		when @latest_lmp_entered is not null then datediff(week, @latest_lmp_entered, @pregnancy_calculation_end_date)
	    else @estimated_gestational_age_entered_calculated 
	END
	
    RETURN @estimated_gestational_age
 
END;
