set @partition = '${partitionNum}';
select encounter_type_id into @labor_enc
from encounter_type et where uuid='ac5ec970-31b7-4659-9141-284bfbc13c69';
set @pregnancyProgramId = program('Pregnancy');

-- ---------------------------------------------------------------
-- 0. Resolve every concept ONCE up front
--    (each *_from_temp function called concept_from_mapping() and then
--     scanned the whole, unindexed temp_obs table -- ~30 times per encounter)
-- ---------------------------------------------------------------
set @c_admission_date   = concept_from_mapping('PIH','12240');
set @c_gravida          = concept_from_mapping('PIH','5624');
set @c_parity           = concept_from_mapping('PIH','1053');
set @c_gest_age         = concept_from_mapping('PIH','14390');
set @c_gest_age_source  = concept_from_mapping('PIH','15090');
set @c_temperature      = concept_from_mapping('PIH','5088');
set @c_heart_rate       = concept_from_mapping('PIH','5087');
set @c_bp_systolic      = concept_from_mapping('PIH','5085');
set @c_bp_diastolic     = concept_from_mapping('PIH','5086');
set @c_resp_rate        = concept_from_mapping('PIH','5242');
set @c_o2_sat           = concept_from_mapping('PIH','5092');
set @c_preg_compl       = concept_from_mapping('PIH','6644');
set @c_labor_start      = concept_from_mapping('PIH','14377');
set @c_membranes_status = concept_from_mapping('PIH','13549');
set @c_membrane_rupture = concept_from_mapping('PIH','15092');
set @c_membrane_color   = concept_from_mapping('PIH','15111');
set @c_meconium         = concept_from_mapping('PIH','15110');
set @c_fundal_height    = concept_from_mapping('PIH','13028');
set @c_uc_status        = concept_from_mapping('PIH','13215');
set @c_fhr_method       = concept_from_mapping('PIH','15095');
set @c_fhr              = concept_from_mapping('PIH','13199');
set @c_induced          = concept_from_mapping('PIH','15113');
set @c_induction_time   = concept_from_mapping('PIH','15116');
set @c_induction_method = concept_from_mapping('PIH','15114');
set @c_palpation        = concept_from_mapping('PIH','14049');
set @c_prev_scar        = concept_from_mapping('PIH','15140');
set @c_prev_csections   = concept_from_mapping('PIH','7011');
set @c_overall_cond     = concept_from_mapping('PIH','1463');
set @c_disposition      = concept_from_mapping('PIH','8620');
set @c_transfer_in      = concept_from_mapping('PIH','14973');
set @c_transfer_out     = concept_from_mapping('PIH','14424');
set @c_death_date       = concept_from_mapping('PIH','14399');
set @c_partogram        = concept_from_mapping('PIH','13756');

-- ---------------------------------------------------------------
-- 1. Encounters (unchanged)
-- ---------------------------------------------------------------
drop temporary table if exists temp_labor_encs;
create temporary table temp_labor_encs
(
patient_id 			int,
emr_id				varchar(255),
encounter_id        int,
visit_id            int,
encounter_datetime datetime,
encounter_location varchar(255),
datetime_entered datetime,
user_entered     varchar(255),
provider             varchar(255),
pregnancy_program_id varchar(50),
admission_date datetime,
gravida INT,
partiy INT,
gestational_age decimal(5,2),
gestational_age_source varchar(255),
temperature decimal,
heart_rate INT,
bp_systolic INT,
bp_diastolic INT,
respiratory_rate INT,
o2_saturation INT,
pregnancy_complications text,
labor_start datetime,
membranes_status varchar(255),
membrane_rupture_date datetime,
membrane_color varchar(255),
meconium_classification varchar(255),
fundal_height decimal,
uc_status varchar(255),
fetal_heart_rate_method varchar(255),
fhr1 INT,
fhr2 INT,
fhr3 INT,
fhr4 INT,
fhr5 INT,
induced_labor varchar(5),
induction_time datetime,
method_of_induction varchar(255),
palpation_of_abdomen varchar(255),
previous_abdominal_scar varchar(5),
number_previous_csections INT,
overall_condition varchar(255),
disposition varchar(255),
transfer_in varchar(255),
transfer_out varchar(255),
transfer_location varchar(255),
death_date datetime,
partogram_uploaded varchar(255),
index_asc INT,
index_desc INT
);

insert into temp_labor_encs(patient_id, encounter_id, visit_id, encounter_datetime,
datetime_entered, user_entered)
select patient_id, encounter_id, visit_id, encounter_datetime, date_created, creator
from encounter e
where e.voided = 0
AND encounter_type IN (@labor_enc)
ORDER BY encounter_datetime desc;

create index temp_labor_encs_ei on temp_labor_encs(encounter_id);

-- ---------------------------------------------------------------
-- 2. Obs of these encounters, only the concepts used, indexed
-- ---------------------------------------------------------------
DROP TEMPORARY TABLE IF EXISTS temp_obs;
create temporary table temp_obs
select o.obs_id, o.obs_group_id, o.encounter_id, o.person_id, o.concept_id, o.value_coded,
       o.value_numeric, o.value_datetime, o.date_created
from obs o
inner join temp_labor_encs t on t.encounter_id = o.encounter_id
where o.voided = 0
  and o.concept_id in (@c_admission_date, @c_gravida, @c_parity, @c_gest_age, @c_gest_age_source,
                       @c_temperature, @c_heart_rate, @c_bp_systolic, @c_bp_diastolic, @c_resp_rate,
                       @c_o2_sat, @c_preg_compl, @c_labor_start, @c_membranes_status, @c_membrane_rupture,
                       @c_membrane_color, @c_meconium, @c_fundal_height, @c_uc_status, @c_fhr_method,
                       @c_fhr, @c_induced, @c_induction_time, @c_induction_method, @c_palpation,
                       @c_prev_scar, @c_prev_csections, @c_overall_cond, @c_disposition,
                       @c_transfer_in, @c_transfer_out, @c_death_date, @c_partogram);

create index temp_obs_ec on temp_obs(encounter_id, concept_id, date_created);
create index temp_obs_oi on temp_obs(obs_id);

-- ---------------------------------------------------------------
-- 3. Single-value fields: the latest obs per (encounter, concept),
--    "latest" = date_created desc, obs_id desc -- same as
--    obs_value_numeric_from_temp / obs_value_datetime_from_temp
-- ---------------------------------------------------------------
DROP TEMPORARY TABLE IF EXISTS temp_obs_latest_dc;
CREATE TEMPORARY TABLE temp_obs_latest_dc
(encounter_id int, concept_id int, max_date_created datetime,
 primary key (encounter_id, concept_id));
INSERT INTO temp_obs_latest_dc
select encounter_id, concept_id, max(date_created)
from temp_obs
where concept_id in (@c_admission_date, @c_gravida, @c_parity, @c_gest_age, @c_temperature,
                     @c_heart_rate, @c_bp_systolic, @c_bp_diastolic, @c_resp_rate, @c_o2_sat,
                     @c_labor_start, @c_membrane_rupture, @c_fundal_height, @c_induction_time,
                     @c_prev_csections, @c_death_date)
group by encounter_id, concept_id;

DROP TEMPORARY TABLE IF EXISTS temp_obs_latest;
CREATE TEMPORARY TABLE temp_obs_latest
(encounter_id int, concept_id int, obs_id int,
 primary key (encounter_id, concept_id));
INSERT INTO temp_obs_latest
select o.encounter_id, o.concept_id, max(o.obs_id)
from temp_obs o
inner join temp_obs_latest_dc d on d.encounter_id = o.encounter_id
                               and d.concept_id = o.concept_id
                               and d.max_date_created = o.date_created
group by o.encounter_id, o.concept_id;

DROP TEMPORARY TABLE IF EXISTS temp_labor_values;
CREATE TEMPORARY TABLE temp_labor_values
(encounter_id              int primary key,
 admission_date            datetime,
 gravida                   double,
 parity                    double,
 gestational_age           double,
 temperature               double,
 heart_rate                double,
 bp_systolic               double,
 bp_diastolic              double,
 respiratory_rate          double,
 o2_saturation             double,
 labor_start               datetime,
 membrane_rupture_date     datetime,
 fundal_height             double,
 induction_time            datetime,
 number_previous_csections double,
 death_date                datetime);
INSERT INTO temp_labor_values
select l.encounter_id,
       max(case when l.concept_id = @c_admission_date   then o.value_datetime end),
       max(case when l.concept_id = @c_gravida          then o.value_numeric end),
       max(case when l.concept_id = @c_parity           then o.value_numeric end),
       max(case when l.concept_id = @c_gest_age         then o.value_numeric end),
       max(case when l.concept_id = @c_temperature      then o.value_numeric end),
       max(case when l.concept_id = @c_heart_rate       then o.value_numeric end),
       max(case when l.concept_id = @c_bp_systolic      then o.value_numeric end),
       max(case when l.concept_id = @c_bp_diastolic     then o.value_numeric end),
       max(case when l.concept_id = @c_resp_rate        then o.value_numeric end),
       max(case when l.concept_id = @c_o2_sat           then o.value_numeric end),
       max(case when l.concept_id = @c_labor_start      then o.value_datetime end),
       max(case when l.concept_id = @c_membrane_rupture then o.value_datetime end),
       max(case when l.concept_id = @c_fundal_height    then o.value_numeric end),
       max(case when l.concept_id = @c_induction_time   then o.value_datetime end),
       max(case when l.concept_id = @c_prev_csections   then o.value_numeric end),
       max(case when l.concept_id = @c_death_date       then o.value_datetime end)
from temp_obs_latest l
inner join temp_obs o on o.obs_id = l.obs_id
group by l.encounter_id;

-- ---------------------------------------------------------------
-- 4. Coded fields: all answers per encounter, ' | '-separated --
--    same as obs_value_coded_list_from_temp, one grouped pass
-- ---------------------------------------------------------------
DROP TEMPORARY TABLE IF EXISTS temp_labor_lists;
CREATE TEMPORARY TABLE temp_labor_lists
(encounter_id            int primary key,
 gestational_age_source  text,
 pregnancy_complications text,
 membranes_status        text,
 membrane_color          text,
 meconium_classification text,
 uc_status               text,
 fetal_heart_rate_method text,
 induced_labor           text,
 method_of_induction     text,
 palpation_of_abdomen    text,
 previous_abdominal_scar text,
 overall_condition       text,
 disposition             text,
 transfer_in             text,
 transfer_out            text);
INSERT INTO temp_labor_lists
select o.encounter_id,
       group_concat(distinct case when o.concept_id = @c_gest_age_source  then concept_name(o.value_coded,'en') end separator ' | '),
       group_concat(distinct case when o.concept_id = @c_preg_compl       then concept_name(o.value_coded,'en') end separator ' | '),
       group_concat(distinct case when o.concept_id = @c_membranes_status then concept_name(o.value_coded,'en') end separator ' | '),
       group_concat(distinct case when o.concept_id = @c_membrane_color   then concept_name(o.value_coded,'en') end separator ' | '),
       group_concat(distinct case when o.concept_id = @c_meconium         then concept_name(o.value_coded,'en') end separator ' | '),
       group_concat(distinct case when o.concept_id = @c_uc_status        then concept_name(o.value_coded,'en') end separator ' | '),
       group_concat(distinct case when o.concept_id = @c_fhr_method       then concept_name(o.value_coded,'en') end separator ' | '),
       group_concat(distinct case when o.concept_id = @c_induced          then concept_name(o.value_coded,'en') end separator ' | '),
       group_concat(distinct case when o.concept_id = @c_induction_method then concept_name(o.value_coded,'en') end separator ' | '),
       group_concat(distinct case when o.concept_id = @c_palpation        then concept_name(o.value_coded,'en') end separator ' | '),
       group_concat(distinct case when o.concept_id = @c_prev_scar        then concept_name(o.value_coded,'en') end separator ' | '),
       group_concat(distinct case when o.concept_id = @c_overall_cond     then concept_name(o.value_coded,'en') end separator ' | '),
       group_concat(distinct case when o.concept_id = @c_disposition      then concept_name(o.value_coded,'en') end separator ' | '),
       group_concat(distinct case when o.concept_id = @c_transfer_in      then concept_name(o.value_coded,'en') end separator ' | '),
       group_concat(distinct case when o.concept_id = @c_transfer_out     then concept_name(o.value_coded,'en') end separator ' | ')
from temp_obs o
where o.concept_id in (@c_gest_age_source, @c_preg_compl, @c_membranes_status, @c_membrane_color,
                       @c_meconium, @c_uc_status, @c_fhr_method, @c_induced, @c_induction_method,
                       @c_palpation, @c_prev_scar, @c_overall_cond, @c_disposition,
                       @c_transfer_in, @c_transfer_out)
group by o.encounter_id;

-- ---------------------------------------------------------------
-- 5. Fetal heart rates 1-4: numbered per encounter by obs_group_id (unchanged)
-- ---------------------------------------------------------------
DROP TEMPORARY TABLE IF EXISTS temp_fhr_index_asc;
CREATE TEMPORARY TABLE temp_fhr_index_asc
(
    SELECT
            encounter_id,
            obs_group_id,
            value_numeric,
            index_asc
FROM (SELECT
            @r:= IF(@u = encounter_id, @r + 1,1) index_asc,
            encounter_id,
            obs_group_id,
            value_numeric,
            @u:= encounter_id
      FROM temp_obs AS t,
                    (SELECT @r:= 1) AS r,
                    (SELECT @u:= 0) AS u
      WHERE t.concept_id = @c_fhr
            ORDER BY encounter_id, obs_group_id ASC
        ) index_ascending );

DROP TEMPORARY TABLE IF EXISTS temp_fhr;
CREATE TEMPORARY TABLE temp_fhr
(encounter_id int primary key, fhr1 double, fhr2 double, fhr3 double, fhr4 double);
INSERT INTO temp_fhr
select encounter_id,
       max(case when index_asc = 1 then value_numeric end),
       max(case when index_asc = 2 then value_numeric end),
       max(case when index_asc = 3 then value_numeric end),
       max(case when index_asc = 4 then value_numeric end)
from temp_fhr_index_asc
group by encounter_id;

-- ---------------------------------------------------------------
-- 6. Partogram uploaded: any partogram obs for the patient on any of
--    their labor encounters (same as latest_obs_from_temp_from_concept_id
--    being non-NULL)
-- ---------------------------------------------------------------
DROP TEMPORARY TABLE IF EXISTS temp_partogram;
CREATE TEMPORARY TABLE temp_partogram
(patient_id int primary key, obs_id int);
INSERT INTO temp_partogram
select person_id, max(obs_id)
from temp_obs
where concept_id = @c_partogram
group by person_id;

-- ---------------------------------------------------------------
-- 7. Small lookups: user names (once per user), emr_id (once per patient)
-- ---------------------------------------------------------------
DROP TEMPORARY TABLE IF EXISTS temp_labor_users;
CREATE TEMPORARY TABLE temp_labor_users
(user_id int primary key, user_name text);
INSERT INTO temp_labor_users
select user_id, person_name_of_user(user_id) from users;

-- patient_identifier() inlined
DROP TEMPORARY TABLE IF EXISTS temp_labor_emr;
CREATE TEMPORARY TABLE temp_labor_emr
(patient_id int primary key, emr_id varchar(50));
INSERT INTO temp_labor_emr
select p.patient_id,
       (select i.identifier from patient_identifier i
         inner join patient_identifier_type it on it.patient_identifier_type_id = i.identifier_type
         where (it.name = 'c09a1d24-7162-11eb-8aa6-0242ac110002' or it.uuid = 'c09a1d24-7162-11eb-8aa6-0242ac110002')
           and i.voided = 0 and i.patient_id = p.patient_id
         order by i.preferred desc, i.date_created desc limit 1)
from (select distinct patient_id from temp_labor_encs) p;

-- ---------------------------------------------------------------
-- 8. Fill every column in ONE update (was ~45 UPDATEs)
--    Column types are unchanged, so rounding/truncation is the same.
-- ---------------------------------------------------------------
update temp_labor_encs t
left join temp_labor_users u   on u.user_id      = t.user_entered      -- holds the creator id at this point
left join temp_labor_emr em    on em.patient_id  = t.patient_id
left join encounter e          on e.encounter_id = t.encounter_id
left join location loc         on loc.location_id = e.location_id
left join temp_labor_values v  on v.encounter_id = t.encounter_id
left join temp_labor_lists ls  on ls.encounter_id = t.encounter_id
left join temp_fhr f           on f.encounter_id = t.encounter_id
left join temp_partogram pg    on pg.patient_id  = t.patient_id
set t.user_entered            = u.user_name,
    t.provider                = provider(t.encounter_id),
    t.emr_id                  = em.emr_id,
    t.encounter_location      = loc.name,               -- encounter_location_name() inlined
    t.pregnancy_program_id    = patient_program_id_from_encounter(t.patient_id, @pregnancyProgramId, t.encounter_id),
    t.admission_date          = v.admission_date,
    t.gravida                 = v.gravida,
    t.partiy                  = v.parity,
    t.gestational_age         = v.gestational_age,
    t.gestational_age_source  = ls.gestational_age_source,
    t.temperature             = v.temperature,
    t.heart_rate              = v.heart_rate,
    t.bp_systolic             = v.bp_systolic,
    t.bp_diastolic            = v.bp_diastolic,
    t.respiratory_rate        = v.respiratory_rate,
    t.o2_saturation           = v.o2_saturation,
    t.pregnancy_complications = ls.pregnancy_complications,
    t.labor_start             = v.labor_start,
    t.membranes_status        = ls.membranes_status,
    t.membrane_rupture_date   = v.membrane_rupture_date,
    t.membrane_color          = ls.membrane_color,
    t.meconium_classification = ls.meconium_classification,
    t.fundal_height           = v.fundal_height,
    t.uc_status               = ls.uc_status,
    t.fetal_heart_rate_method = ls.fetal_heart_rate_method,
    t.fhr1                    = f.fhr1,
    t.fhr2                    = f.fhr2,
    t.fhr3                    = f.fhr3,
    t.fhr4                    = f.fhr4,
    t.induced_labor           = ls.induced_labor,
    t.induction_time          = v.induction_time,
    t.method_of_induction     = ls.method_of_induction,
    t.palpation_of_abdomen    = ls.palpation_of_abdomen,
    t.previous_abdominal_scar = ls.previous_abdominal_scar,
    t.number_previous_csections = v.number_previous_csections,
    t.overall_condition       = ls.overall_condition,
    t.disposition             = ls.disposition,
    t.transfer_in             = ls.transfer_in,
    t.transfer_out            = ls.transfer_out,
    t.transfer_location       = COALESCE(ls.transfer_in, ls.transfer_out),
    t.death_date              = v.death_date,
    t.partogram_uploaded      = pg.obs_id;

-- ---------------------------------------------------------------
-- 9. Final output (unchanged)
-- ---------------------------------------------------------------
SELECT
concat(@partition,"-",patient_id) as patient_id,
emr_id,
concat(@partition,"-",encounter_id) as encounter_id,
concat(@partition,"-",visit_id) as visit_id,
encounter_datetime,
encounter_location,
datetime_entered,
user_entered,
concat(@partition,"-",pregnancy_program_id) as pregnancy_program_id,
provider,
admission_date,
gravida,
partiy,
gestational_age,
gestational_age_source,
temperature,
heart_rate,
bp_systolic,
bp_diastolic,
respiratory_rate,
o2_saturation,
pregnancy_complications,
labor_start,
membranes_status,
membrane_rupture_date,
membrane_color,
meconium_classification,
fundal_height,
uc_status,
fetal_heart_rate_method,
fhr1,
fhr2,
fhr3,
fhr4,
fhr5,
CASE
		WHEN upper(induced_labor)= 'YES' then 1
		WHEN upper(induced_labor)= 'NO' then 0
END AS induced_labor ,
induction_time,
method_of_induction,
palpation_of_abdomen,
CASE
		WHEN upper(previous_abdominal_scar)= 'YES' then 1
		WHEN upper(previous_abdominal_scar)= 'NO' then 0
END AS previous_abdominal_scar ,
number_previous_csections,
overall_condition,
disposition,
transfer_location,
death_date,
CASE WHEN partogram_uploaded IS NOT NULL THEN TRUE ELSE FALSE END AS partogram_uploaded,
index_asc,
index_desc
FROM temp_labor_encs;
