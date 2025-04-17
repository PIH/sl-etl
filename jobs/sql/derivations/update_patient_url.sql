update ap
set patient_url = 
CASE
	when patient_url like '%kgh-test%' then
		concat('https://kgh-test.pih-emr.org/openmrs/coreapps/clinicianfacing/patient.page?patientId=', patient_uuid)
	when site = 'kgh' then
		concat('https://kgh.pih-emr.org/openmrs/coreapps/clinicianfacing/patient.page?patientId=', patient_uuid)
	when site = 'wellbody' then
		concat('https://wellbody.pih-emr.org/openmrs/coreapps/clinicianfacing/patient.page?patientId=', patient_uuid)
END
from all_patients ap ;
