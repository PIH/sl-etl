create table all_visits
(
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
