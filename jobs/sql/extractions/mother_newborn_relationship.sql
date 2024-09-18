set @partition = '${partitionNum}';

SELECT relationship_type_id INTO @mother FROM relationship_type WHERE uuid = '9a4b3b84-8a9f-11e8-9a94-a6cf71072f73';
SELECT relationship_type_id INTO @parent FROM relationship_type WHERE uuid = '8d91a210-c2cc-11de-8d13-0010c6dffd0f';

drop temporary table if exists temp_mc_relation;
create temporary table temp_mc_relation
(
 relationship_id     int PRIMARY KEY AUTO_INCREMENT, 
 emr_id              varchar(255), 
 patient_id          int,
 patient_uuid        char(38),
 emr_id_mother       varchar(255), 
 patient_id_mother   int,
 relationship_source varchar(255), 
 creator             int(11),
 user_entered        text,         
 date_created        datetime,     
 index_asc           INT,          
 index_desc          INT 
);

insert into temp_mc_relation(patient_id,patient_id_mother, creator, date_created )
select person_b, person_a, creator, date_created
from relationship r
where relationship in (@mother, @parebnt)
and voided = 0;

-- delete rows where the "mother" is male
delete t from temp_mc_relation t 
inner join person p on t.patient_id_mother = p.person_id 
where gender = 'M';

update temp_mc_relation set emr_id = patient_identifier(patient_id, metadata_uuid('org.openmrs.module.emrapi', 'emr.primaryIdentifierType'));

update temp_mc_relation set emr_id_mother = patient_identifier(patient_id_mother, metadata_uuid('org.openmrs.module.emrapi', 'emr.primaryIdentifierType'));

update temp_mc_relation set user_entered = person_name_of_user(creator);

update temp_mc_relation t
inner join person p on p.person_id = t.patient_id
set patient_uuid = p.uuid;

set @person_exists_question = concept_from_mapping('PIH','20150');

update temp_mc_relation t
inner join obs o on o.concept_id = @person_exists_question and o.voided = 0 and o.comments = t.patient_uuid
set relationship_source = 'Inborn';

update temp_mc_relation t
set relationship_source = 'Manual Input'
where relationship_source is null;

select 
 relationship_id,
 emr_id,
 patient_id,
 emr_id_mother, 
 patient_id_mother,
 relationship_source, 
 user_entered,         
 date_created,     
 index_asc,          
 index_desc 
from temp_mc_relation;
