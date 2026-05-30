drop table if exists duplicate_patient_staging;
create table duplicate_patient_staging
(warning_type                       text,
patient_1_patient_id                varchar(30),
patient_2_patient_id                varchar(30),
patient_1_emr_id                    varchar(30),
patient_2_emr_id                    varchar(30),
patient_1_birthdate                 date,
patient_2_birthdate                 date,
same_day_registration               bit,
siblings                            bit,
patient_1_telephone_number          text,
patient_2_telephone_number          text,
patient_1_name                      text,
patient_2_name                      text,
patient_1_mothers_first_name        text,
patient_2_mothers_first_name        text,
patient_1_date_registration_entered datetime,
patient_2_date_registration_entered datetime,
patient_1_user_entered              text,
patient_2_user_entered              text,
patient_1_site                      varchar(100),
patient_2_site                      varchar(100)
);

-- pre-normalize matching fields once so the self-join and filter use indexed columns
-- rather than re-evaluating replace()/lower() expressions per-row
drop table if exists #temp_normalized;
    select
    patient_id,
    replace(replace(telephone_number,' ',''),'-','') as phone_normalized,
    lower(replace(name,' ',''))                      as name_normalized,
    lower(replace(family_name,' ',''))               as family_name_normalized,
    lower(replace(mothers_first_name,' ',''))        as mothers_first_name_normalized
into #temp_normalized
from all_patients
where telephone_number > '0';

create index ix_norm_phone on #temp_normalized(phone_normalized);
create index ix_norm_pid   on #temp_normalized(patient_id);

-- drop rows where any matching field is a placeholder value (appears in > 1% of patients).
-- a real personal identifier would never be shared by that fraction of the population;
-- de-identified or clinic-wide values would be, and produce a combinatorial explosion in the self-join.
delete from #temp_normalized
where phone_normalized in (
    select phone_normalized from #temp_normalized
    group by phone_normalized
    having count(*) > (select count(*) * 0.01 from #temp_normalized)
);

-- populate table with all pairs of candidates based on same telephone number
insert into duplicate_patient_staging(patient_1_patient_id, patient_2_patient_id)
select p1.patient_id, p2.patient_id
from #temp_normalized p1
inner join #temp_normalized p2 on p1.patient_id < p2.patient_id
    and p1.phone_normalized = p2.phone_normalized;

-- remove candidates where name, family_name, or mothers_first_name doesn't match
-- (NULL fields are treated as unknown and do not eliminate a pair)
delete t
from duplicate_patient_staging t
inner join #temp_normalized p1 on p1.patient_id = t.patient_1_patient_id
inner join #temp_normalized p2 on p2.patient_id = t.patient_2_patient_id
where p1.name_normalized             <> p2.name_normalized
   or p1.family_name_normalized      <> p2.family_name_normalized
   or p1.mothers_first_name_normalized <> p2.mothers_first_name_normalized;

drop table if exists #temp_normalized;

-- populate all remaining fields
update t
set patient_1_telephone_number          = p1.telephone_number,
    patient_1_name                      = concat(p1.name,' ',p1.family_name),
    patient_1_mothers_first_name        = p1.mothers_first_name,
    patient_1_date_registration_entered = p1.date_registration_entered,
    patient_1_user_entered              = p1.user_entered,
    patient_1_birthdate                 = p1.birthdate,
    patient_1_emr_id                    = p1.emr_id,
    patient_1_site                      = p1.site
from duplicate_patient_staging t
inner join all_patients p1 on p1.patient_id = t.patient_1_patient_id;

update t
set patient_2_telephone_number          = p2.telephone_number,
    patient_2_name                      = concat(p2.name,' ',p2.family_name),
    patient_2_mothers_first_name        = p2.mothers_first_name,
    patient_2_date_registration_entered = p2.date_registration_entered,
    patient_2_user_entered              = p2.user_entered,
    patient_2_birthdate                 = p2.birthdate,
    patient_2_emr_id                    = p2.emr_id,
    patient_2_site                      = p2.site
from duplicate_patient_staging t
inner join all_patients p2 on p2.patient_id = t.patient_2_patient_id;

update t
set t.warning_type =
case
    when patient_1_site = patient_2_site then 'duplicate patients on same EMR'
    else 'duplicate patients on different EMRs'
end
from duplicate_patient_staging t;

update t
set t.siblings = 1
from duplicate_patient_staging t
inner join mother_child_relationship r1 on r1.patient_id = t.patient_1_patient_id
inner join mother_child_relationship r2 on r2.patient_id = t.patient_2_patient_id
    and r1.emr_id_mother = r2.emr_id_mother;

update t
set same_day_registration = iif(cast(patient_1_date_registration_entered as date) = cast(patient_2_date_registration_entered as date),1,0)
from duplicate_patient_staging t;

DROP TABLE IF EXISTS duplicate_patient_warnings;
EXEC sp_rename 'duplicate_patient_staging', 'duplicate_patient_warnings';
