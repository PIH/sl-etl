set @partition = '${partitionNum}';
set @locale = 'en';   

-- ---------------------------------------------------------------
-- 0. Resolve every lookup ONCE up front
-- ---------------------------------------------------------------
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
SELECT order_type_id INTO @order_type_id FROM order_type ot WHERE uuid ='131168f4-15f5-102d-96e4-000c29c2a5d7';

set @prescription_construct = concept_from_mapping('PIH','10742');
set @dosing_units = concept_from_mapping('PIH','10744');
set @med          = concept_from_mapping('PIH','1282');
set @mh_med       = concept_from_mapping('PIH','10634');
set @frequency    = concept_from_mapping('PIH','9363');
set @duration     = concept_from_mapping('PIH','9075');
set @dur_units    = concept_from_mapping('PIH','6412');
set @med_qty      = concept_from_mapping('PIH','9073');
set @completed    = concept_from_mapping('PIH','1267');
set @refused      = concept_from_mapping('PIH','7080');
set @onHold       = concept_from_mapping('PIH','14356');
set @primary_emr_uuid = metadata_uuid('org.openmrs.module.emrapi', 'emr.primaryIdentifierType');
set @now = now();

-- ---------------------------------------------------------------
-- 1. Small lookup tables, each keyed by a primary key
--    (each function runs once per user / provider / drug / concept / patient /
--     encounter, instead of once per row)
-- ---------------------------------------------------------------

-- user names (order creator)
drop temporary table if exists temp_user_entered;
create temporary table temp_user_entered
(creator      int(11) primary key,
 user_entered text);
insert into temp_user_entered
select user_id, person_name_of_user(user_id) from users;

-- provider names (orderer, new orders)
drop temporary table if exists temp_mp_providers;
create temporary table temp_mp_providers
(provider_id int(11) primary key,
 name        text);
insert into temp_mp_providers
select provider_id, provider_name_from_provider_id(provider_id) from provider;

-- drug name + openboxes code
drop temporary table if exists temp_mp_drugs;
create temporary table temp_mp_drugs
(drug_id      int(11) primary key,
 drug_name    varchar(255),
 product_code varchar(50));
insert into temp_mp_drugs
select drug_id, drugName(drug_id), openboxesCode(drug_id) from drug;

-- order frequency names
drop temporary table if exists temp_mp_freq;
create temporary table temp_mp_freq
(order_frequency_id int(11) primary key,
 name               varchar(255));
insert into temp_mp_freq
select order_frequency_id, concept_name(concept_id, 'en') from order_frequency;

-- EMR ids, once per patient (patient_identifier() inlined, same logic)
drop temporary table if exists temp_mp_emr;
create temporary table temp_mp_emr
(patient_id int(11) primary key,
 emr_id     varchar(50));
insert into temp_mp_emr
select x.patient_id,
       (select i.identifier from patient_identifier i
         inner join patient_identifier_type it on it.patient_identifier_type_id = i.identifier_type
         where (it.name = @primary_emr_uuid or it.uuid = @primary_emr_uuid)
           and i.voided = 0 and i.patient_id = x.patient_id
         order by i.preferred desc, i.date_created desc limit 1)
from (select person_id as patient_id from obs
      where voided = 0 and concept_id = @prescription_construct
      union
      select o.patient_id from orders o
      inner join encounter e on e.encounter_id = o.encounter_id
      where o.order_type_id = @order_type_id and o.voided = 0) x;

-- ---------------------------------------------------------------
-- 2. Old form (obs-based prescriptions)
-- ---------------------------------------------------------------

-- obs values, one row per prescription obs group
DROP TEMPORARY TABLE IF EXISTS temp_obs_collated;
CREATE TEMPORARY TABLE temp_obs_collated
(obs_group_id         int(11) primary key,
 encounter_id         int(11),
 drug_concept_id      int(11),
 drug_id              int(11),
 order_dose_unit      varchar(255),
 order_frequency      varchar(255),
 order_duration       double,
 order_duration_units varchar(255),
 order_quantity       double);
insert into temp_obs_collated
select o.obs_group_id,
       max(o.encounter_id),
       max(case when o.concept_id = @med or o.concept_id = @mh_med then o.value_coded end),
       max(case when o.concept_id = @med or o.concept_id = @mh_med then o.value_drug end),
       max(case when o.concept_id = @dosing_units then concept_name(o.value_coded,'en') end),
       max(case when o.concept_id = @frequency    then concept_name(o.value_coded,'en') end),
       max(case when o.concept_id = @duration     then o.value_numeric end),
       max(case when o.concept_id = @dur_units    then concept_name(o.value_coded,'en') end),
       max(case when o.concept_id = @med_qty      then o.value_numeric end)
from obs g
inner join obs o on o.obs_group_id = g.obs_id
where g.voided = 0
  and g.concept_id = @prescription_construct
  and o.voided = 0
group by o.obs_group_id;

-- drug concept names used by the old form
drop temporary table if exists temp_mp_old_drug_names;
create temporary table temp_mp_old_drug_names
(concept_id int(11) primary key,
 name       varchar(255));
insert into temp_mp_old_drug_names
select c.concept_id, concept_name(c.concept_id, 'en')
from (select distinct drug_concept_id as concept_id from temp_obs_collated
      where drug_concept_id is not null) c;

-- encounter-level columns (same encounter set as before: encounters of the collated obs)
DROP TEMPORARY TABLE IF EXISTS temp_presc_encounters;
CREATE TEMPORARY TABLE temp_presc_encounters
(encounter_id       int(11) primary key,
 visit_id           int(11),
 encounter_datetime datetime,
 date_created       datetime,
 creator            int(11),
 provider           text);
insert into temp_presc_encounters
select e.encounter_id, e.visit_id, e.encounter_datetime, e.date_created, e.creator, provider(e.encounter_id)
from (select distinct encounter_id from temp_obs_collated where encounter_id is not null) x
inner join encounter e on e.encounter_id = x.encounter_id;

-- ---------------------------------------------------------------
-- 3. New orders: concept names and dispensing info
-- ---------------------------------------------------------------

-- concept names used by new orders (drug, reason, units, route), named once
drop temporary table if exists temp_mp_concepts;
create temporary table temp_mp_concepts
(concept_id int(11) primary key,
 name       varchar(255));
insert ignore into temp_mp_concepts(concept_id)
select o.concept_id from orders o where o.order_type_id = @order_type_id and o.voided = 0 and o.concept_id is not null;
insert ignore into temp_mp_concepts(concept_id)
select o.order_reason from orders o where o.order_type_id = @order_type_id and o.voided = 0 and o.order_reason is not null;
insert ignore into temp_mp_concepts(concept_id)
select d.quantity_units from drug_order d where d.quantity_units is not null;
insert ignore into temp_mp_concepts(concept_id)
select d.dose_units from drug_order d where d.dose_units is not null;
insert ignore into temp_mp_concepts(concept_id)
select d.route from drug_order d where d.route is not null;
insert ignore into temp_mp_concepts(concept_id)
select d.duration_units from drug_order d where d.duration_units is not null;
update temp_mp_concepts set name = concept_name(concept_id, 'en');

-- MySQL can't join the same temp table twice in one query, so one copy per role
drop temporary table if exists temp_mp_c_reason;
create temporary table temp_mp_c_reason like temp_mp_concepts;
insert into temp_mp_c_reason select * from temp_mp_concepts;
drop temporary table if exists temp_mp_c_qty_units;
create temporary table temp_mp_c_qty_units like temp_mp_concepts;
insert into temp_mp_c_qty_units select * from temp_mp_concepts;
drop temporary table if exists temp_mp_c_dose_units;
create temporary table temp_mp_c_dose_units like temp_mp_concepts;
insert into temp_mp_c_dose_units select * from temp_mp_concepts;
drop temporary table if exists temp_mp_c_route;
create temporary table temp_mp_c_route like temp_mp_concepts;
insert into temp_mp_c_route select * from temp_mp_concepts;
drop temporary table if exists temp_mp_c_dur_units;
create temporary table temp_mp_c_dur_units like temp_mp_concepts;
insert into temp_mp_c_dur_units select * from temp_mp_concepts;

-- dispensing per order: totals + latest non-voided dispense
-- (latest = date_created desc, medication_dispense_id desc, as before)
drop temporary table if exists temp_dispense_qty;
create temporary table temp_dispense_qty
(drug_order_id      int(11) primary key,
 quantity_dispensed double,
 num_substitutions  double,
 latest_created     datetime,
 latest_id          int(11));
insert into temp_dispense_qty (drug_order_id, quantity_dispensed, num_substitutions, latest_created)
select drug_order_id, sum(quantity), sum(was_substituted), max(date_created)
from medication_dispense
where voided = 0
  and drug_order_id is not null
group by drug_order_id;

update temp_dispense_qty t
set t.latest_id = (select max(md.medication_dispense_id) from medication_dispense md
                   where md.drug_order_id = t.drug_order_id
                     and md.voided = 0
                     and md.date_created = t.latest_created);

drop temporary table if exists temp_order_statuses;
create temporary table temp_order_statuses
(drug_order_id     int(11) primary key,
 dispensing_status varchar(255),
 status_reason     varchar(255));
insert into temp_order_statuses
select t.drug_order_id,
       case when md.status = @refused then 'Closed'
            when md.status = @onHold  then 'Paused' end,
       concept_name(md.status_reason, @locale)
from temp_dispense_qty t
inner join medication_dispense md on md.medication_dispense_id = t.latest_id
where md.status in (@refused, @onHold);

-- ---------------------------------------------------------------
-- 4. Main table (same column types as before).
--    Each form inserted fully populated in ONE pass; ORDER BY keeps
--    medication_prescription_id in the same order as before
--    (old form by obs_id, then new orders by order_id).
-- ---------------------------------------------------------------
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
date_entered                date,
order_date_activated        date,
expiration_datetime         datetime,
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
quantity_dispensed          int,
dispensing_status           varchar(255),
status_reason               varchar(255),
refills_remaining           int,
num_substitutions           int,
index_asc                   int,
index_desc                  int,
PRIMARY KEY (medication_prescription_id)
);

-- old form
insert into all_medication_prescribed
(obs_group_id, patient_id, encounter_id, order_type, emr_id, order_location,
 drug_concept_id, drug_id, order_drug, order_formulation, product_code,
 order_dose_unit, order_frequency, order_duration, order_duration_units, order_quantity,
 visit_id, order_creator, user_entered, prescriber, order_date_activated, date_entered)
select
 g.obs_id,
 g.person_id,
 g.encounter_id,
 'Old Form',
 em.emr_id,
 l.name,                         -- encounter_location_name() inlined
 c.drug_concept_id,
 c.drug_id,
 cn.name,
 dr.drug_name,
 dr.product_code,
 c.order_dose_unit,
 c.order_frequency,
 c.order_duration,
 c.order_duration_units,
 c.order_quantity,
 pe.visit_id,
 pe.creator,
 u.user_entered,
 pe.provider,
 pe.encounter_datetime,
 pe.date_created
from obs g
left join temp_obs_collated c         on c.obs_group_id  = g.obs_id
left join temp_mp_old_drug_names cn   on cn.concept_id   = c.drug_concept_id
left join temp_mp_drugs dr            on dr.drug_id      = c.drug_id
left join temp_presc_encounters pe    on pe.encounter_id = g.encounter_id
left join temp_user_entered u         on u.creator       = pe.creator
left join temp_mp_emr em              on em.patient_id   = g.person_id
left join encounter e                 on e.encounter_id  = g.encounter_id
left join location l                  on l.location_id   = e.location_id
where g.voided = 0
  and g.concept_id = @prescription_construct
order by g.obs_id;

-- new orders
INSERT INTO all_medication_prescribed
(order_type, patient_id, encounter_id, visit_id, order_id, order_creator, orderer,
 date_entered, order_date_activated, expiration_datetime,
 order_drug, order_reason, order_comments,
 emr_id, order_location, user_entered, prescriber,
 order_formulation, order_formulation_non_coded, product_code,
 order_quantity, order_quantity_units, order_quantity_num_refills,
 order_dose, order_dose_unit, order_dosing_instructions, order_route,
 order_duration, order_frequency_id, order_frequency, order_duration_units,
 quantity_dispensed, num_substitutions, dispensing_status, status_reason)
SELECT
 'New Orders',
 o.patient_id,
 o.encounter_id,
 e.visit_id,
 o.order_id,
 o.creator,
 o.orderer,
 o.date_created,
 o.date_activated,
 o.auto_expire_date,
 cn.name,
 cr.name,
 o.comment_to_fulfiller,
 em.emr_id,
 l.name,
 u.user_entered,
 pr.name,
 dr.drug_name,
 d.drug_non_coded,
 dr.product_code,
 d.quantity,
 cqu.name,
 d.num_refills,
 d.dose,
 cdu.name,
 d.dosing_instructions,
 crt.name,
 d.duration,
 d.frequency,
 f.name,
 cdur.name,
 case when q.num_substitutions > 0 then null else q.quantity_dispensed end,
 q.num_substitutions,
 s.dispensing_status,
 s.status_reason
FROM orders o
inner join encounter e                on e.encounter_id   = o.encounter_id
left join location l                  on l.location_id    = e.location_id
left join drug_order d                on d.order_id       = o.order_id
left join temp_mp_drugs dr            on dr.drug_id       = d.drug_inventory_id
left join temp_mp_concepts cn         on cn.concept_id    = o.concept_id
left join temp_mp_c_reason cr         on cr.concept_id    = o.order_reason
left join temp_mp_c_qty_units cqu     on cqu.concept_id   = d.quantity_units
left join temp_mp_c_dose_units cdu    on cdu.concept_id   = d.dose_units
left join temp_mp_c_route crt         on crt.concept_id   = d.route
left join temp_mp_c_dur_units cdur    on cdur.concept_id  = d.duration_units
left join temp_mp_freq f              on f.order_frequency_id = d.frequency
left join temp_mp_emr em              on em.patient_id    = o.patient_id
left join temp_user_entered u         on u.creator        = o.creator
left join temp_mp_providers pr        on pr.provider_id   = o.orderer
left join temp_dispense_qty q         on q.drug_order_id  = o.order_id
left join temp_order_statuses s       on s.drug_order_id  = o.order_id
where o.order_type_id = @order_type_id
  and o.voided = 0
order by o.order_id;

-- ---------------------------------------------------------------
-- 5. Dispensing status + refills: ONE update on the stored values
--    (was 3 updates; single-table UPDATE assigns left to right, so each
--     step sees the previous one, exactly like the separate statements)
-- ---------------------------------------------------------------
update all_medication_prescribed a
set a.dispensing_status =
      CASE
        when a.dispensing_status is not null then a.dispensing_status
        when a.quantity_dispensed is null or a.quantity_dispensed = 0 then 'Not Dispensed'
        when a.quantity_dispensed < a.order_quantity then 'Partially Dispensed'
        else 'Dispensed'
      END,
    a.dispensing_status =
      CASE
        when a.dispensing_status = 'Not Dispensed' and a.expiration_datetime < @now then 'Expired'
        else a.dispensing_status
      END,
    a.refills_remaining =
      CASE
        when a.dispensing_status = 'Dispensed' then
          CEILING(a.order_quantity_num_refills - ((a.quantity_dispensed - a.order_quantity)/a.order_quantity))
      END;

-- ---------------------------------------------------------------
-- 6. Final output (unchanged)
-- ---------------------------------------------------------------
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
    date_entered,
    order_date_activated,
    expiration_datetime,
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
    order_comments,
    quantity_dispensed,
    dispensing_status,
    status_reason,
    refills_remaining,
    num_substitutions,
    index_asc,
    index_desc
FROM all_medication_prescribed;
