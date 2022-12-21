create table all_visits
(
patient_id			int(11),
emr_id				varchar(50),
visit_id			int(11),
visit_date_started	datetime,
visit_date_stopped	datetime,
visit_date_entered	datetime,
visit_creator		int(11),
visit_user_entered	varchar(255),
visit_type_id		int(11),
visit_type			varchar(255),
checkin_encounter_id	int(11),	
location_id			int(11),
visit_location		varchar(255),
index_asc			int,
index_desc			int
);
