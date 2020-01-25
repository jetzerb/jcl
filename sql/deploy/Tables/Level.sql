-- Deploy jcl:Tables/Level to pg

BEGIN;

create table if not exists Level
(
	 Level_Id   smallint    not null -- 1-6
	,Level_Name varchar(30) not null -- Latin I - Latin VI
	,Level      smallint    not null -- Same as LevelId for 1-4, but 4 for levels 5 & 6

	,constraint Level_PK primary key (Level_Id)
);

comment on table Level             is 'Competition levels, based on student experience';
comment on column Level.Level_Id   is 'Identifier for the level (1-6)';
comment on column Level.Level_Name is 'Descriptive name for the level';
comment on column Level.Level      is 'Scoring grouper (e.g. can map levels 5-6 to 4)';

COMMIT;
