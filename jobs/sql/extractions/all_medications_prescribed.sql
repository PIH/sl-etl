set @partition = '${partitionNum}';

SELECT patient_identifier_type_id INTO @identifier_type FROM patient_identifier_type pit WHERE uuid ='1a2acce0-7426-11e5-a837-0800200c9a66';
SELECT patient_identifier_type_id INTO @kgh_identifier_type FROM patient_identifier_type pit WHERE uuid ='c09a1d24-7162-11eb-8aa6-0242ac110002';
SELECT encounter_type_id INTO @anc_intake_enc FROM encounter_type et WHERE uuid ='00e5e810-90ec-11e8-9eb6-529269fb1459';
SELECT encounter_type_id INTO @anc_followup_enc FROM encounter_type et WHERE uuid ='00e5e946-90ec-11e8-9eb6-529269fb1459';
SELECT encounter_type_id INTO @outpat_init_enc FROM encounter_type et WHERE uuid ='7d5853d4-67b7-4742-8492-fcf860690ed5';
SELECT encounter_type_id INTO @outpat_followup_enc FROM encounter_type et WHERE uuid ='d8a038b5-90d2-43dc-b94b-8338b76674f3';
SELECT encounter_type_id INTO @mch_delivery_enc FROM encounter_type et WHERE uuid ='00e5ebb2-90ec-11e8-9eb6-529269fb1459';
SELECT encounter_type_id INTO @mh_consult_enc FROM encounter_type et WHERE uuid ='a8584ab8-cc2a-11e5-9956-625662870761';
SELECT encounter_type_id INTO @mh_followup_enc FROM encounter_type et WHERE uuid ='9d701a81-bb83-40ea-9efc-af50f05575f2';
SELECT encounter_type_id INTO @ncd_init_enc FROM encounter_type et WHERE uuid ='ae06d311-1866-455b-8a64-126a9bd74171';

DROP TEMPORARY TABLE IF EXISTS all_medication_prescribed;
CREATE TEMPORARY TABLE all_medication_prescribed
(
medication_prescription_id  int(11) not null auto_increment,
patient_id                  int(11),
obs_group_id                int(11),
emr_id                      varchar(25),
order_type                  varchar(30),
encounter_id                int(11),
visit_id                    int(11),
order_id                    int(11),
order_location              varchar(255),
order_created_date          date,
order_date_activated        date,
orderer                     int(11),
user_entered                text,
prescriber                  varchar(255),
drug_concept_id             int(11),
drug_id                     int(11),
order_drug                  varchar(255),
order_formulation           varchar(255),
order_formulation_non_coded text,
product_code                varchar(50),
order_creator               int(11),
order_quantity              double,
order_quantity_units        varchar(50),
order_quantity_num_refills  int,
order_dose                  int,
order_dose_unit             varchar(50),
order_dosing_instructions   text,
order_route                 varchar(50),
order_frequency_id          int(11),
order_frequency             varchar(50),
order_duration              int,
order_duration_units        varchar(50),
order_reason                text,
order_comments              text,
PRIMARY KEY (medication_prescription_id)
);

-- ------------------------------- add "orders" added via observations (the "old" way)
set @prescription_construct = concept_from_mapping('PIH','10742');
insert into all_medication_prescribed(obs_group_id, patient_id, encounter_id, order_type)
select obs_id, person_id, encounter_id, 'Old Form' from obs o
where o.voided = 0
and o.concept_id=  @prescription_construct;

create index all_medication_prescribed_ei on all_medication_prescribed(encounter_id);

-- obs level columns
set @dosing_units = concept_from_mapping('PIH','10744');
set @med =  concept_from_mapping('PIH','1282');
set @mh_med =  concept_from_mapping('PIH','10634');
set @frequency = concept_from_mapping('PIH','9363');
set @duration = concept_from_mapping('PIH','9075');
set @dur_units = concept_from_mapping('PIH','6412');
set @med_qty = concept_from_mapping('PIH','9073');

DROP TEMPORARY TABLE IF EXISTS temp_obs_collated;
CREATE TEMPORARY TABLE temp_obs_collated AS
select o.obs_group_id,
max(o.encounter_id) "encounter_id",
max(case when concept_id = @med or concept_id = @mh_med then value_coded end) "drug_concept_id",
max(case when concept_id = @med or concept_id = @mh_med then value_drug end) "drug_id",
max(case when concept_id = @dosing_units then concept_name(value_coded,'en') end) "order_dose_unit",
max(case when concept_id = @frequency then concept_name(value_coded,'en') end) "order_frequency",
max(case when concept_id = @duration then value_numeric end) "order_duration",
max(case when concept_id = @dur_units then concept_name(value_coded,'en') end) "order_duration_units",
max(case when concept_id = @med_qty then value_numeric end) "order_quantity"
FROM all_medication_prescribed t
INNER JOIN obs o ON o.obs_group_id = t.obs_group_id
WHERE o.voided = 0
group by obs_group_id;

create index temp_obs_collated_ogi on temp_obs_collated(obs_group_id); 
create index temp_obs_collated_di on temp_obs_collated(drug_id); 

update all_medication_prescribed t 
inner join temp_obs_collated o on o.obs_group_id = t.obs_group_id
set t.drug_concept_id = o.drug_concept_id,
	t.drug_id = o.drug_id,
	t.order_dose_unit = o.order_dose_unit,
	t.order_frequency = o.order_frequency,
	t.order_duration = o.order_duration,
	t.order_duration_units = o.order_duration_units,
	t.order_quantity = o.order_quantity;

UPDATE all_medication_prescribed tgt
set order_drug = concept_name(drug_concept_id, 'en');

UPDATE all_medication_prescribed tgt
set product_code = openboxesCode(drug_id);

UPDATE all_medication_prescribed tgt
set order_formulation = drugName(drug_id);

-- encounter-level columns
DROP TEMPORARY TABLE IF EXISTS temp_presc_encounters;
CREATE TEMPORARY TABLE temp_presc_encounters
(encounter_id      int(11), 
visit_id           int(11),
encounter_datetime datetime,
date_created       datetime,
creator            int(11),
provider           text);

insert into temp_presc_encounters(encounter_id)
select distinct encounter_id from temp_obs_collated;

create index temp_presc_encounters_e1 on temp_presc_encounters(encounter_id);

update temp_presc_encounters t
inner join encounter e on e.encounter_id = t.encounter_id
set t.visit_id = e.visit_id,
	t.encounter_datetime = e.encounter_datetime,
	t.creator = e.creator,
	t.date_created = e.date_created;

update temp_presc_encounters t set provider = provider(encounter_id);

update all_medication_prescribed t
inner join temp_presc_encounters e on e.encounter_id = t.encounter_id
set t.visit_id = e.visit_id,
	t.order_creator = e.creator,
	t.prescriber = provider,
	t.order_date_activated = e.encounter_datetime,
	t.order_created_date = e.date_created;

-- ------------------------------- add orders added via Lab Order module (the "new" way)
SELECT order_type_id INTO @order_type_id FROM order_type ot WHERE uuid ='131168f4-15f5-102d-96e4-000c29c2a5d7';
INSERT INTO all_medication_prescribed
(order_type, 
patient_id, 
encounter_id, 
visit_id, 
order_id, 
order_creator,
orderer,
order_created_date,
order_date_activated, 
order_drug, 
order_reason, 
order_comments)
SELECT
'New Orders',
o.patient_id,
o.encounter_id,
o.encounter_id,
o.order_id,
o.creator,
o.orderer,
o.date_created,
o.date_activated,
concept_name(o.concept_id, 'en') as order_drug,
concept_name(o.order_reason,'en') AS order_reason,
o.comment_to_fulfiller AS order_comments
FROM orders o
where o.order_type_id = @order_type_id;

create index all_medication_prescribed_oi on all_medication_prescribed(order_id);

-- user entered
drop temporary table if exists temp_user_entered;
create temporary table temp_user_entered
(creator     int(11),
user_entered text);

create index temp_user_entered_c on temp_user_entered(creator);

insert into temp_user_entered(creator)
select distinct order_creator from all_medication_prescribed;

update temp_user_entered t
set user_entered = person_name_of_user(t.creator);

update all_medication_prescribed t 
inner join temp_user_entered u on u.creator = t.order_creator 
set t.user_entered = u.user_entered;

-- prescriber
update all_medication_prescribed t
set prescriber = person_name_of_user(t.orderer)
where t.order_type = 'New Orders';

update all_medication_prescribed t
inner join drug_order do ON t.order_id = do.order_id
set order_formulation = drugName(do.drug_inventory_id), 
    order_formulation_non_coded = do.drug_non_coded, 
    product_code = openboxesCode(do.drug_inventory_id),
    order_quantity = do.quantity , 
    order_quantity_units = concept_name(do.quantity_units,'en'), 
    order_quantity_num_refills = do.num_refills,
    order_dose = do.dose, 
    order_dose_unit = concept_name(do.dose_units,'en'), 
    order_dosing_instructions = do.dosing_instructions, 
    order_route = concept_name(do.route,'en'),
    order_duration = do.duration, 
    order_frequency_id = do.frequency, 
    order_duration_units = concept_name(do.duration_units,'en');

update all_medication_prescribed t
inner join order_frequency ofr ON t.order_frequency_id = ofr.order_frequency_id
set order_frequency = concept_name(ofr.concept_id,'en');

UPDATE all_medication_prescribed SET order_location = encounter_location_name(encounter_id);

set @primary_emr_uuid = metadata_uuid('org.openmrs.module.emrapi', 'emr.primaryIdentifierType');
UPDATE all_medication_prescribed SET emr_id=patient_identifier(patient_id,@primary_emr_uuid );

SELECT 
    concat(@partition, '-', medication_prescription_id) as medication_prescription_id,	
    concat(@partition, '-', order_id) as order_id,
    concat(@partition,'-',obs_group_id) as 'obs_id',
    concat(@partition, '-', encounter_id) as encounter_id,
    concat(@partition, '-', visit_id) as visit_id,
    concat(@partition, '-', patient_id) as patient_id,
    emr_id,
    order_type,
    order_location,
    order_created_date,
    order_date_activated,
    user_entered,
    prescriber,
    order_drug,
    order_formulation,
    order_formulation_non_coded,
    product_code,
    order_quantity,
    order_quantity_units,
    order_quantity_num_refills,
    order_dose,
    order_dose_unit,
    order_dosing_instructions,
    order_route,
    order_frequency,
    order_duration,
    order_duration_units,
    order_reason,
    order_comments
FROM all_medication_prescribed;
