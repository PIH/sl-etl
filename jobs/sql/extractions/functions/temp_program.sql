-- You should uncomment this line to check syntax in IDE.  Liquibase handles this internally.
-- DELIMITER #

-- ***************************************************
-- temp_program_patient
-- ***************************************************

DROP PROCEDURE IF EXISTS temp_program_patient_create;
#
CREATE PROCEDURE temp_program_patient_create()
BEGIN
    drop table if exists temp_program_patient;

    create temporary table temp_program_patient
    (
        patient_program_id int,
        patient_id         int,
        location_id        int,
        date_enrolled      date,
        date_completed     date,
        outcome_concept_id int
    );
END
#

DROP PROCEDURE IF EXISTS temp_program_patient_populate;
#
CREATE PROCEDURE temp_program_patient_populate(IN _program_id int)
BEGIN
    insert into temp_program_patient
    (
        patient_program_id,
        patient_id,
        location_id,
        date_enrolled,
        date_completed,
        outcome_concept_id
    )
    select
        pp.patient_program_id,
        pp.patient_id,
        pp.location_id,
        date(pp.date_enrolled),
        date(pp.date_completed),
        pp.outcome_concept_id
    from patient_program pp
    where pp.program_id = _program_id
      and pp.voided = 0;
END
#

DROP PROCEDURE IF EXISTS temp_program_patient_create_indexes;
#
CREATE PROCEDURE temp_program_patient_create_indexes()
BEGIN
    create index temp_program_patient_patient_program_id_idx on temp_program_patient(patient_program_id);
    create index temp_program_patient_patient_id_idx on temp_program_patient(patient_id);
END
#

-- ***************************************************
-- temp_program_encounter
-- ***************************************************

DROP PROCEDURE IF EXISTS temp_program_encounter_create;
#
CREATE PROCEDURE temp_program_encounter_create()
BEGIN
    drop table if exists temp_program_encounter;

    create temporary table temp_program_encounter
    (
        patient_program_id int,
        patient_id         int,
        encounter_id       int,
        encounter_type_id  int,
        location_id        int,
        visit_location_id  int,
        encounter_datetime datetime,
        date_created       datetime,
        created_by         int
    );
END
#

DROP PROCEDURE IF EXISTS temp_program_encounter_populate;
#
CREATE PROCEDURE temp_program_encounter_populate(IN _encounter_type_id int)
BEGIN
    insert into temp_program_encounter
    (
        patient_program_id,
        patient_id,
        encounter_id,
        encounter_type_id,
        location_id,
        visit_location_id,
        encounter_datetime,
        date_created,
        created_by
    )
    select
        pp.patient_program_id,
        e.patient_id,
        e.encounter_id,
        e.encounter_type,
        e.location_id,
        v.location_id,
        e.encounter_datetime,
        e.date_created,
        e.creator
    from encounter e
    left join visit v on e.visit_id = v.visit_id and v.voided = 0
    inner join temp_program_patient pp on e.patient_id = pp.patient_id
    where encounter_type = _encounter_type_id
      and e.encounter_datetime >= pp.date_enrolled
      and (pp.date_completed is null or date(e.encounter_datetime) <= pp.date_completed)
      and e.voided = 0;
END
#

DROP PROCEDURE IF EXISTS temp_program_encounter_create_indexes;
#
CREATE PROCEDURE temp_program_encounter_create_indexes()
BEGIN
    create index temp_program_encounter_patient_program_id_idx on temp_program_encounter(patient_program_id);
    create index temp_program_encounter_patient_id_idx on temp_program_encounter(patient_id);
    create index temp_program_encounter_encounter_id_idx on temp_program_encounter(encounter_id);
    create index temp_program_encounter_encounter_type_idx on temp_program_encounter(encounter_type_id);
END
#

-- ********************************
-- ENCOUNTER-RELATED FUNCTIONS
-- ********************************

DROP FUNCTION IF EXISTS temp_program_encounter_latest_encounter_id;
#
CREATE FUNCTION temp_program_encounter_latest_encounter_id(_patient_program_id int, _encounter_type_id int)
    RETURNS int
    DETERMINISTIC
BEGIN
    DECLARE ret int;
    select      e.encounter_id into ret
    from        temp_program_encounter e
    where       e.patient_program_id = _patient_program_id
      and       e.encounter_type_id = _encounter_type_id
    order by    e.encounter_datetime desc, e.encounter_id desc limit 1;
    RETURN ret;
END
#

DROP FUNCTION IF EXISTS temp_program_encounter_latest_encounter_datetime;
#
CREATE FUNCTION temp_program_encounter_latest_encounter_datetime(_patient_program_id int, _encounter_type_id int)
    RETURNS datetime
    DETERMINISTIC
BEGIN
    DECLARE ret datetime;
    select      e.encounter_datetime into ret
    from        temp_program_encounter e
    where       e.patient_program_id = _patient_program_id
      and       e.encounter_type_id = _encounter_type_id
    order by    e.encounter_datetime desc, e.encounter_id desc limit 1;
    RETURN ret;
END
#

DROP FUNCTION IF EXISTS temp_program_encounter_latest_location;
#
CREATE FUNCTION temp_program_encounter_latest_location(_patient_program_id int, _encounter_type_id int)
    RETURNS int
    DETERMINISTIC
BEGIN
    DECLARE ret int;
    select      e.location_id into ret
    from        temp_program_encounter e
    where       e.patient_program_id = _patient_program_id
      and       e.encounter_type_id = _encounter_type_id
    order by    e.encounter_datetime desc, e.encounter_id desc limit 1;
    RETURN ret;
END
#

DROP FUNCTION IF EXISTS temp_program_encounter_latest_visit_location;
#
CREATE FUNCTION temp_program_encounter_latest_visit_location(_patient_program_id int, _encounter_type_id int)
    RETURNS int
    DETERMINISTIC
BEGIN
    DECLARE ret int;
    select      e.visit_location_id into ret
    from        temp_program_encounter e
    where       e.patient_program_id = _patient_program_id
      and       e.encounter_type_id = _encounter_type_id
    order by    e.encounter_datetime desc, e.encounter_id desc limit 1;
    RETURN ret;
END
#

DROP FUNCTION IF EXISTS temp_program_encounter_count;
#
CREATE FUNCTION temp_program_encounter_count(_patient_program_id int, _encounter_type_id int, _end_datetime datetime)
    RETURNS int
    DETERMINISTIC
BEGIN
    DECLARE ret int;
    select      count(e.encounter_id) into ret
    from        temp_program_encounter e
    where       e.patient_program_id = _patient_program_id
      and       e.encounter_type_id = _encounter_type_id
     and        (end_datetime is null or e.encounter_datetime < _end_datetime);
    RETURN ret;
END
#

-- ***************************************************
-- temp_program_obs
-- ***************************************************

DROP PROCEDURE IF EXISTS temp_program_obs_create;
#
CREATE PROCEDURE temp_program_obs_create()
BEGIN
    drop table if exists temp_program_obs;
    create temporary table temp_program_obs
    (
        patient_program_id int,
        encounter_id       int,
        obs_id             int,
        obs_group_id       int,
        patient_id         int,
        encounter_type_id  int,
        order_id           int,
        obs_datetime       datetime,
        concept_id         int,
        value_coded        int,
        value_coded_name   varchar(255),
        value_drug         int,
        value_drug_name    varchar(255),
        value_numeric      double,
        value_datetime     datetime,
        value_text         text,
        comments           varchar(255),
        date_created       datetime,
        created_by         int
    );
END
#
DROP PROCEDURE IF EXISTS temp_program_obs_populate;
#
CREATE PROCEDURE temp_program_obs_populate(IN _locale varchar(10))
BEGIN
    insert into temp_program_obs
    (
        patient_program_id,
        encounter_id,
        obs_id,
        obs_group_id,
        patient_id,
        encounter_type_id,
        order_id,
        obs_datetime,
        concept_id,
        value_coded,
        value_drug,
        value_numeric,
        value_datetime,
        value_text,
        comments,
        date_created,
        created_by
    )
    select
        e.patient_program_id,
        o.encounter_id,
        o.obs_id,
        o.obs_group_id,
        o.person_id,
        e.encounter_type_id,
        o.order_id,
        o.obs_datetime,
        o.concept_id,
        o.value_coded,
        o.value_drug,
        o.value_numeric,
        o.value_datetime,
        o.value_text,
        o.comments,
        o.date_created,
        o.creator
    from obs o
    inner join temp_program_encounter e on o.encounter_id = e.encounter_id
    where o.voided = 0;

    update temp_program_obs set value_coded_name = concept_name(value_coded, _locale);
    update temp_program_obs set value_drug_name = drugName(value_drug);

    create index temp_program_obs_patient_program_id_idx on temp_program_obs(patient_program_id);
    create index temp_program_obs_patient_id_idx on temp_program_obs(patient_id);
    create index temp_program_obs_obs_id_idx on temp_program_obs(obs_id);
    create index temp_program_obs_encounter_id_idx on temp_program_obs(encounter_id);
    create index temp_program_obs_obs_group_id_idx on temp_program_obs(obs_group_id);
    create index temp_program_obs_encounter_and_group_idx on temp_program_obs(encounter_id, obs_group_id);
    create index temp_program_obs_value_coded_idx on temp_program_obs(value_coded);
END
#

-- ********************************
-- OBS-RELATED FUNCTIONS
-- ********************************

DROP FUNCTION IF EXISTS temp_program_obs_latest_obs_datetime;
#
CREATE FUNCTION temp_program_obs_latest_obs_datetime(_patient_program_id int, _source varchar(50), _term varchar(255))
    RETURNS datetime
    DETERMINISTIC
BEGIN
    DECLARE ret datetime;
    select      o.obs_datetime into ret
    from        temp_program_obs o
    where       o.patient_program_id = _patient_program_id
      and       o.concept_id = concept_from_mapping(_source, _term)
    order by    o.obs_datetime desc, o.obs_id desc limit 1;
    RETURN ret;
END
#

DROP FUNCTION IF EXISTS temp_program_obs_latest_value_datetime;
#
CREATE FUNCTION temp_program_obs_latest_value_datetime(_patient_program_id int, _source varchar(50), _term varchar(255))
    RETURNS datetime
    DETERMINISTIC
BEGIN
    DECLARE ret datetime;
    select      o.value_datetime into ret
    from        temp_program_obs o
    where       o.patient_program_id = _patient_program_id
      and       o.concept_id = concept_from_mapping(_source, _term)
    order by    o.obs_datetime desc, o.obs_id desc limit 1;
    RETURN ret;
END
#

DROP FUNCTION IF EXISTS temp_program_obs_latest_value_numeric;
#
CREATE FUNCTION temp_program_obs_latest_value_numeric(_patient_program_id int, _source varchar(50), _term varchar(255))
    RETURNS double
    DETERMINISTIC
BEGIN
    DECLARE ret double;
    select      o.value_numeric into ret
    from        temp_program_obs o
    where       o.patient_program_id = _patient_program_id
      and       o.concept_id = concept_from_mapping(_source, _term)
    order by    o.obs_datetime desc, o.obs_id desc limit 1;
    RETURN ret;
END
#

DROP FUNCTION IF EXISTS temp_program_obs_latest_value_coded_name;
#
CREATE FUNCTION temp_program_obs_latest_value_coded_name(_patient_program_id int, _source varchar(50), _term varchar(255))
    RETURNS varchar(255)
    DETERMINISTIC
BEGIN
    DECLARE ret varchar(255);
    select      o.value_coded_name into ret
    from        temp_program_obs o
    where       o.patient_program_id = _patient_program_id
      and       o.concept_id = concept_from_mapping(_source, _term)
    order by    o.obs_datetime desc, o.obs_id desc limit 1;
    RETURN ret;
END
#

DROP FUNCTION IF EXISTS temp_program_obs_num_with_value_coded;
#
CREATE FUNCTION temp_program_obs_num_with_value_coded(_patient_program_id int, _encounter_type int, _question_source varchar(50), _question_term varchar(255), _answer_source varchar(50), _answer_term varchar(255))
    RETURNS int
    DETERMINISTIC
BEGIN
    DECLARE ret int;
    select      count(o.obs_id) into ret
    from        temp_program_obs o
    where       o.patient_program_id = _patient_program_id
      and       o.concept_id = concept_from_mapping(_question_source, _question_term)
      and       o.value_coded = concept_from_mapping(_answer_source, _answer_term)
      and       (_encounter_type is null or o.encounter_type_id = _encounter_type);
    RETURN ret;
END
#

DROP FUNCTION IF EXISTS temp_program_earliest_patient_state_date;
#
CREATE FUNCTION temp_program_earliest_patient_state_date(_patient_program_id int, _patient_state_id int(11))
    RETURNS date
    DETERMINISTIC
BEGIN
    DECLARE ret date;
	select start_date into ret from patient_state ps 
	where patient_program_id = _patient_program_id
	and ps.state = _patient_state_id
	order by start_date asc limit 1;    
	RETURN ret;
END
#
