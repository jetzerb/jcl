-- Deploy jcl:Tables/Student to pg
-- requires: Tables/School
-- requires: Tables/Level

BEGIN;

create table if not exists Student
(
	 Student_Id smallint    not null -- Based on student level
	,School_Id  smallint             -- Link to student's School
	,Last_Name  varchar(20)
	,First_Name varchar(15)
	,Level_Id   smallint             -- Link to student's level

	,constraint Student_PK primary Key (Student_Id)
);

comment on table  Student            is 'List of participating students';
comment on column Student.Student_Id is 'Numeric identifier for the student; level 1 is 1000+, level 2 is 2000+, etc';
comment on column Student.School_Id  is 'Link key to School table, but not implemented as foreign key so we can move on with sloppy or incomplete data.';
comment on column Student.Last_Name  is 'The student''s last name';
comment on column Student.First_Name is 'The student''s first name';
comment on column Student.Level_Id   is 'Link key to the Level table, but not implemented as a foreign key so we can move on with sloppy or incomplete data.';

COMMIT;
