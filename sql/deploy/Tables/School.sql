-- Deploy jcl:Tables/School to pg

BEGIN;

create table if not exists School
(
	 School_Id   smallint    not null  -- identifier/surrogate key
	,School_Name varchar(50) not null  -- descriptive name

	,constraint School_PK primary key (School_Id)
);

comment on table  School             is 'List of participating schools';
comment on column School.School_Id   is 'Numeric identifier for the school';
comment on column School.School_Name is 'The official name of the school';

COMMIT;
