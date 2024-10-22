#
-- This will return the date appointment scheduled for a given patient appoointment id
-- if that column does not exist, return null
#
CREATE FUNCTION date_appointment_scheduled(_patient_appointment_id int) RETURNS datetime
    DETERMINISTIC
BEGIN
    DECLARE ret datetime;

IF column_exists('patient_appointment','date_appointment_scheduled') THEN
 select date_appointment_scheduled into ret
 	from patient_appointment where patient_appointment_id = _patient_appointment_id;
ELSE
  select date_created into ret
 	from patient_appointment where patient_appointment_id = _patient_appointment_id;
END IF;

    RETURN ret;
END
