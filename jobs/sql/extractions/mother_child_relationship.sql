set @partition = '${partitionNum}';

SELECT relationship_type_id INTO @mother FROM relationship_type WHERE uuid = '9a4b3b84-8a9f-11e8-9a94-a6cf71072f73';
SELECT relationship_type_id INTO @parent FROM relationship_type WHERE uuid = '8d91a210-c2cc-11de-8d13-0010c6dffd0f';

drop temporary table if exists temp_mc_relation;
create temporary table temp_mc_relation
(
 relationship_id                    int PRIMARY KEY AUTO_INCREMENT,  
 emr_id                             varchar(255),         
 patient_id                         int,          
 patient_uuid                       char(38),     
 emr_id_mother                      varchar(255),         
 patient_id_mother                  int,          
 relationship_source                varchar(255),         
 creator                            int(11),      
 user_entered                       text,                 
 date_created                       datetime,  
 child_dob                          datetime,
 child_age_at_relationship_creation double,       
 child_age_current                  double                
);

insert into temp_mc_relation(patient_id,patient_id_mother, creator, date_created)
select person_b, person_a, creator, date_created
from relationship r
where relationship in (@mother, @parent)
and voided = 0;

-- delete rows where the "mother" is male
delete t from temp_mc_relation t 
inner join person p on t.patient_id_mother = p.person_id 
where gender = 'M';

-- update information from person table
update temp_mc_relation t 
inner join person p on t.patient_id = p.person_id 
set child_dob = p.birthdate; 

update temp_mc_relation set emr_id = patient_identifier(patient_id, metadata_uuid('org.openmrs.module.emrapi', 'emr.primaryIdentifierType'));

update temp_mc_relation set emr_id_mother = patient_identifier(patient_id_mother, metadata_uuid('org.openmrs.module.emrapi', 'emr.primaryIdentifierType'));

update temp_mc_relation set user_entered = person_name_of_user(creator);

update temp_mc_relation t
inner join person p on p.person_id = t.patient_id
set patient_uuid = p.uuid;

set @person_exists_question = concept_from_mapping('PIH','20150');

update temp_mc_relation t
inner join obs o on o.concept_id = @person_exists_question and o.voided = 0 and o.comments = t.patient_uuid
set relationship_source = 'Delivery Form';

update temp_mc_relation t
set relationship_source = 'Manual Input'
where relationship_source is null;

update temp_mc_relation t
set child_age_current = TIMESTAMPDIFF(YEAR, child_dob,now());

update temp_mc_relation t
set child_age_at_relationship_creation = TIMESTAMPDIFF(YEAR, child_dob,date_created);

select 
 relationship_id,
 emr_id,
 patient_id,
 emr_id_mother, 
 patient_id_mother,
 relationship_source, 
 user_entered,         
 date_created,     
 child_age_at_relationship_creation,   
 child_age_current
from temp_mc_relation;
