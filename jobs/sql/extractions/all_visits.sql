set @partition = '${partitionNum}';
SELECT patient_identifier_type_id INTO @identifier_type
FROM patient_identifier_type pit WHERE uuid ='1a2acce0-7426-11e5-a837-0800200c9a66';
SELECT patient_identifier_type_id INTO @kgh_identifier_type 
FROM patient_identifier_type pit WHERE uuid ='c09a1d24-7162-11eb-8aa6-0242ac110002';

drop temporary table if exists temp_visits;
create temporary table temp_visits
(
patient_id			int,
emr_id				varchar(50),
visit_id			int,
visit_date_started	datetime,
visit_date_stopped	datetime,
visit_date_entered	datetime,
visit_creator		int,
visit_user_entered	varchar(255),
visit_type_id		int,
visit_type			varchar(255),
checkin_encounter_id	int,	
location_id			int,
visit_location		varchar(255),
index_asc			int,
index_desc			int
);

insert into temp_visits(patient_id, visit_id, visit_date_started, visit_date_stopped, visit_date_entered, visit_type_id, visit_creator, location_id)
select patient_id, visit_id, date_started, date_stopped, date_created, visit_type_id, creator, location_id  
from visit v 
where v.voided = 0
and patient_id in (select patient_id from patient where voided=0);

create index temp_visits_vi on temp_visits(visit_id);

-- emr_id
DROP TEMPORARY TABLE IF EXISTS temp_identifiers;
CREATE TEMPORARY TABLE temp_identifiers
(
patient_id						INT,
emr_id							VARCHAR(25)
);

INSERT INTO temp_identifiers(patient_id)
select distinct patient_id from temp_visits;

update temp_identifiers t 
set emr_id = (
select distinct identifier
from patient_identifier 
where identifier_type = CASE WHEN @partition=1 THEN @identifier_type WHEN @partition=2 THEN @kgh_identifier_type END 
and voided = 0
and patient_id = t.patient_id
and preferred=1);

CREATE INDEX temp_identifiers_p ON temp_identifiers (patient_id);

update temp_visits tv 
inner join temp_identifiers ti on ti.patient_id = tv.patient_id
set tv.emr_id = ti.emr_id;

-- visit type
update temp_visits t
inner join visit_type vt on vt.visit_type_id = t.visit_type_id
set t.visit_type = vt.name;

-- locations
update temp_visits tv 
set tv.visit_location = location_name(location_id);

-- user entered
DROP TEMPORARY TABLE IF EXISTS temp_users;
CREATE TEMPORARY TABLE temp_users
(
creator						INT,
creator_name				VARCHAR(255)
);

INSERT INTO temp_users(creator)
select distinct visit_creator from temp_visits;

CREATE INDEX temp_users_c ON temp_users(creator);

update temp_users t set creator_name  = person_name_of_user(creator);	

update temp_visits tv 
inner join temp_users tu on tu.creator = tv.visit_creator
set tv.visit_user_entered = tu.creator_name;


-- ---- Ascending Order ------------------------------------------

drop table if exists int_asc;
create table int_asc
select emr_id, visit_date_started, visit_id from temp_visits vs 
ORDER BY emr_id  asc, visit_date_started  asc, visit_id asc;


set @row_number := 0;

DROP TABLE IF EXISTS asc_order;
CREATE TABLE asc_order
SELECT 
    @row_number:=CASE
        WHEN @emr_id = emr_id  
			THEN @row_number + 1
        ELSE 1
    END AS index_asc,
    @emr_id:=emr_id  emr_id,
    visit_date_started,visit_id
FROM
    int_asc;
   
update temp_visits es
inner join 
(
 select index_asc,emr_id,visit_date_started,visit_id
 from asc_order

) x 
 on x.emr_id=es.emr_id 
 and x.visit_date_started=es.visit_date_started
 and x.visit_id=es.visit_id
set es.index_asc =x.index_asc;
    

-- ---- Descending Order ------------------------------------------

drop table if exists int_desc;
create table int_desc
select emr_id, visit_date_started, visit_id from temp_visits vs 
ORDER BY emr_id asc, visit_date_started  desc, visit_id desc;


set @row_number := 0;

DROP TABLE IF EXISTS desc_order;
CREATE TABLE desc_order
SELECT 
    @row_number:=CASE
        WHEN @emr_id = emr_id  
			THEN @row_number + 1
        ELSE 1
    END AS index_desc,
    @emr_id:=emr_id  emr_id,
    visit_date_started,visit_id
FROM
    int_desc;
   
update temp_visits es
inner join 
(
 select index_desc,emr_id,visit_date_started,visit_id
 from desc_order
) x 
 on x.emr_id=es.emr_id 
 and x.visit_date_started=es.visit_date_started
 and x.visit_id=es.visit_id
set es.index_desc = x.index_desc;



select
emr_id,
concat(@partition,"-",visit_id),
visit_date_started,
visit_date_stopped,
visit_date_entered,
visit_user_entered,
visit_type,
visit_location,
index_asc,
index_desc
from temp_visits
order by patient_id desc, visit_date_started asc;