#set @startDate='2023-05-01';
#set @endDate='2023-05-20';
 
SET @locale = GLOBAL_PROPERTY_VALUE('default_locale', 'en');
SET sql_safe_updates = 0;
set @partition = '${partitionNum}';

-- ---------------------------------------------------------------
-- Resolve lookups once up front
-- ---------------------------------------------------------------
SELECT concept_id INTO @not_performed FROM concept WHERE uuid = '5dc35a2a-228c-41d0-ae19-5b1e23618eda';
SET @result_date     = concept_from_mapping('PIH','10783');
SET @primary_id_uuid = metadata_uuid('org.openmrs.module.emrapi', 'emr.primaryIdentifierType');

-- date window: same meaning as DATE(obs_datetime) between the two dates,
-- written so obs_datetime isn't wrapped in a function
SET @startDateTime = DATE(@startDate);
SET @endDateExcl   = DATE_ADD(DATE(@endDate), INTERVAL 1 DAY);

DROP TEMPORARY TABLE IF EXISTS temp_labresults;
CREATE TEMPORARY TABLE temp_labresults
( 
  patient_id                      INT(11),      
  emr_id                          VARCHAR(50),  
  encounter_id                    INT(11),      
  encounter_type                  VARCHAR(255), 
  obs_id                          INT(11),      
  visit_id                        INT(11),      
  test_concept_id                 INT(11),      
  value_coded_concept_id          INT(11),      
  value_text                      TEXT,         
  value_numeric                   DOUBLE,       
  order_id                        INT(11),      
  loc_registered                  VARCHAR(255), 
  encounter_location_id           INT(11),      
  encounter_location              VARCHAR(255), 
  unknown_patient                 VARCHAR(50),  
  gender                          VARCHAR(50),  
  age_at_encounter                INT(11),      
  order_number                    VARCHAR(50), 
  orderable                       VARCHAR(255), 
  test                            VARCHAR(255), 
  lab_id                          VARCHAR(255),   
  LOINC                           VARCHAR(255),   
  result                          TEXT,         
  specimen_collection_date        DATETIME,     
  specimen_collection_entry_date  DATETIME,     
  user_entered                    TEXT,
  units                           VARCHAR(255), 
  reason_not_performed_concept_id INT(11),      
  reason_not_performed            VARCHAR(255), 
  results_date_obs_id             INT(11),      
  results_date                    DATETIME,     
  results_entry_date              DATETIME,
  index_asc                       INT,
  index_desc                      INT
);

-- The following porcedure populates table temp_lab_concepts with all of the concept_ids of reportable labs
call populate_lab_concepts();

-- insert labs with results
INSERT into temp_labresults
	(obs_id,
	patient_id,
	encounter_id,
	test_concept_id,
	order_id,
	value_coded_concept_id,
	value_numeric,
	value_text)	
select 
	o.obs_id, 
	o.person_id, 
	o.encounter_id , 
	o.concept_id, 
	o.order_id, 
	o.value_coded, 
	o.value_numeric, 
	o.value_text
from obs o 
inner join temp_lab_concepts c on c.concept_id = o.concept_id
where o.voided = 0
and (value_coded is not null or value_numeric is not null or value_text is not null)
and (@startDateTime is null or o.obs_datetime >= @startDateTime)
and (@endDateExcl   is null or o.obs_datetime <  @endDateExcl);

-- insert labs not performed
INSERT into temp_labresults
	(obs_id,
	patient_id,
	encounter_id,
	order_id,
	reason_not_performed_concept_id)
select 
	o.obs_id, 
	o.person_id, 
	o.encounter_id, 
	o.order_id,
	o.value_coded 
from obs o 
where o.voided = 0
and concept_id = @not_performed
and (@startDateTime is null or o.obs_datetime >= @startDateTime)
and (@endDateExcl   is null or o.obs_datetime <  @endDateExcl);

create index temp_labresults_pi on temp_labresults(patient_id);

-- ---------------------------------------------------------------
-- patient level columns (one row per patient, filled in one statement)
-- ---------------------------------------------------------------
DROP TEMPORARY TABLE IF EXISTS temp_lab_patient;
CREATE TEMPORARY TABLE temp_lab_patient
(
 patient_id      INT(11) PRIMARY KEY,      
 emr_id          VARCHAR(50),  
 unknown_patient VARCHAR(50),  
 gender          VARCHAR(50),  
 loc_registered  VARCHAR(255) 
 );
 
insert into temp_lab_patient(patient_id, emr_id, unknown_patient, gender, loc_registered)
select x.patient_id,
       patient_identifier(x.patient_id, @primary_id_uuid),
       unknown_patient(x.patient_id),
       (select p.gender from person p where p.person_id = x.patient_id and p.voided = 0),  -- gender() inlined
       loc_registered(x.patient_id)
from (select distinct patient_id from temp_labresults where patient_id is not null) x;

-- ---------------------------------------------------------------
-- encounter level columns (one row per encounter, filled in one statement)
-- ---------------------------------------------------------------
DROP TEMPORARY TABLE IF EXISTS temp_lab_users;
CREATE TEMPORARY TABLE temp_lab_users
(user_id   INT(11) PRIMARY KEY,
 user_name TEXT);

insert into temp_lab_users
select u.creator, person_name_of_user(u.creator)
from (select distinct e.creator
      from encounter e
      inner join (select distinct encounter_id from temp_labresults where encounter_id is not null) x
              on x.encounter_id = e.encounter_id
      where e.creator is not null) u;

DROP TEMPORARY TABLE IF EXISTS temp_lab_encounter;
CREATE TEMPORARY TABLE temp_lab_encounter
(
 patient_id               INT(11),      
 visit_id                 INT(11),      
 encounter_id             INT(11) PRIMARY KEY,      
 encounter_type_id        INT(11),      
 encounter_type           VARCHAR(255), 
 encounter_location_id    INT(11),      
 encounter_location       VARCHAR(255), 
 date_created             DATETIME,
 creator                  INT(11),
 user_entered             TEXT,
 age_at_encounter         DOUBLE,       
 specimen_collection_date DATETIME,
 results_date             DATETIME,
 results_entry_date       DATETIME
 );

insert into temp_lab_encounter
	(encounter_id, patient_id, encounter_location_id, encounter_type_id, specimen_collection_date,
	 date_created, creator, visit_id, encounter_type, encounter_location, user_entered, age_at_encounter)
select e.encounter_id, e.patient_id, e.location_id, e.encounter_type, e.encounter_datetime,
       e.date_created, e.creator, e.visit_id,
       left(et.name, 50),                                                -- encounter_type_name_from_id() returns varchar(50)
       l.name,                                                           -- location_name() inlined
       u.user_name,
       ROUND((select TIMESTAMPDIFF(YEAR, p.birthdate, e.encounter_datetime)
              from person p where p.person_id = e.patient_id))          -- age_at_enc() inlined
from (select distinct encounter_id from temp_labresults where encounter_id is not null) x
inner join encounter e        on e.encounter_id = x.encounter_id
left join encounter_type et   on et.encounter_type_id = e.encounter_type
left join location l          on l.location_id = e.location_id
left join temp_lab_users u    on u.user_id = e.creator;

-- results date, once per encounter (was one join to obs per result row)
update temp_lab_encounter t
inner join obs o on o.encounter_id = t.encounter_id and o.voided = 0 and o.concept_id = @result_date
set t.results_date = o.value_datetime,
	t.results_entry_date = o.date_created;

-- ---------------------------------------------------------------
-- order level columns
-- ---------------------------------------------------------------
DROP TEMPORARY TABLE IF EXISTS temp_lab_orders;
CREATE TEMPORARY TABLE temp_lab_orders
(
 order_id             INT(11) PRIMARY KEY,      
 order_number         VARCHAR(50),  
 orderable_concept_id INT(11),      
 orderable            VARCHAR(255), 
 lab_id               VARCHAR(255)  
 );

insert into temp_lab_orders (order_id, order_number, orderable_concept_id, orderable, lab_id)
select o.order_id, o.order_number, o.concept_id, concept_name(o.concept_id, @locale), o.accession_number
from (select DISTINCT order_id from temp_labresults where order_id is not null) x
inner join orders o on o.order_id = x.order_id;

-- ---------------------------------------------------------------
-- test / answer level lookups (once per distinct concept, not per row)
-- ---------------------------------------------------------------
DROP TEMPORARY TABLE IF EXISTS temp_lab_tests;
CREATE TEMPORARY TABLE temp_lab_tests
(concept_id INT(11) PRIMARY KEY,
 test       VARCHAR(255),
 loinc      VARCHAR(255),
 units      VARCHAR(255));

insert into temp_lab_tests
select c.test_concept_id,
       concept_name(c.test_concept_id, @locale),
       RETRIEVECONCEPTMAPPING(c.test_concept_id, 'LOINC'),
       cu.units
from (select distinct test_concept_id from temp_labresults where test_concept_id is not null) c
left join concept_numeric cu on cu.concept_id = c.test_concept_id;

DROP TEMPORARY TABLE IF EXISTS temp_lab_answers;
CREATE TEMPORARY TABLE temp_lab_answers
(concept_id INT(11) PRIMARY KEY,
 name       VARCHAR(255));

insert into temp_lab_answers
select c.value_coded_concept_id, concept_name(c.value_coded_concept_id, @locale)
from (select distinct value_coded_concept_id from temp_labresults where value_coded_concept_id is not null) c;

DROP TEMPORARY TABLE IF EXISTS temp_lab_reasons;
CREATE TEMPORARY TABLE temp_lab_reasons
(concept_id INT(11) PRIMARY KEY,
 name       VARCHAR(255));

insert into temp_lab_reasons
select c.reason_not_performed_concept_id, concept_name(c.reason_not_performed_concept_id, @locale)
from (select distinct reason_not_performed_concept_id from temp_labresults where reason_not_performed_concept_id is not null) c;

-- ---------------------------------------------------------------
-- fill everything in one pass
-- ---------------------------------------------------------------
update temp_labresults t
left join temp_lab_patient p   on p.patient_id   = t.patient_id
left join temp_lab_encounter e on e.encounter_id = t.encounter_id
left join temp_lab_orders o    on o.order_id     = t.order_id
left join temp_lab_tests ts    on ts.concept_id  = t.test_concept_id
left join temp_lab_answers a   on a.concept_id   = t.value_coded_concept_id
left join temp_lab_reasons r   on r.concept_id   = t.reason_not_performed_concept_id
set t.emr_id                         = p.emr_id,
	t.unknown_patient                = p.unknown_patient,
	t.gender                         = p.gender,
	t.loc_registered                 = p.loc_registered,
	t.encounter_location_id          = e.encounter_location_id,
	t.encounter_type                 = e.encounter_type,
	t.encounter_location             = e.encounter_location,
	t.specimen_collection_date       = e.specimen_collection_date,
	t.specimen_collection_entry_date = e.date_created,
	t.age_at_encounter               = e.age_at_encounter,
	t.user_entered                   = e.user_entered,
	t.visit_id                       = e.visit_id,
	t.results_date                   = e.results_date,
	t.results_entry_date             = e.results_entry_date,
	t.order_number                   = o.order_number,
	t.orderable                      = o.orderable,
	t.lab_id                         = o.lab_id,
	t.test                           = ts.test,
	t.LOINC                          = ts.loinc,
	t.units                          = ts.units,
	t.reason_not_performed           = r.name,
	t.result = 
		case 
			when t.value_coded_concept_id is not null then a.name
			when t.value_numeric is not null then t.value_numeric
			else t.value_text
		end;

-- select final output
SELECT
	if(@partition REGEXP '^[0-9]+$' = 1,concat(@partition,'-',t.obs_id),t.obs_id) "obs_id",
	if(@partition REGEXP '^[0-9]+$' = 1,concat(@partition,'-',t.patient_id),t.patient_id) "patient_id",
	t.emr_id,
    if(@partition REGEXP '^[0-9]+$' = 1,concat(@partition,'-',t.visit_id),t.visit_id) "visit_id",
    if(@partition REGEXP '^[0-9]+$' = 1,concat(@partition,'-',t.encounter_id),t.encounter_id) "encounter_id",
    t.encounter_type,
    t.encounter_location,
    t.loc_registered,
    t.unknown_patient,
    t.gender,
    t.age_at_encounter,
	if(@partition REGEXP '^[0-9]+$' = 1,concat(@partition,'-',t.order_number),t.order_number) "order_number",    
    t.orderable,
    test,
    t.lab_id,							   
    t.LOINC,							   
    DATE(t.specimen_collection_date) "specimen_collection_date",
    t.specimen_collection_entry_date,
    t.user_entered,
    DATE(t.results_date) "results_date",
    t.results_entry_date,
	t.result,
	t.units,
	t.reason_not_performed,
	t.index_asc,
	t.index_desc
FROM temp_labresults t;
