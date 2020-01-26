-- Deploy jcl:Tables/Test_Result to pg

BEGIN;

/*

Table holding all the test results

*/
create table if not exists Test_Result
(
	 Competition_Id smallint     not null
	,Student_Id     smallint     not null
	,Score          numeric(4,1)
	,Level          smallint
	,SrcFile        text

	,constraint Test_Result_PK primary key (Competition_Id, Student_Id)
);

comment on table  Test_Result                is 'Table holding test scores for all competitions';
comment on column Test_Result.Competition_Id is 'Link to Competition Table';
comment on column Test_Result.Student_Id     is 'Link to Student Table';
comment on column Test_Result.Score          is 'The student''s score.  For team sports, all students are awarded the team score, and the school is awarded that same score regardless of the number of team members';
comment on column Test_Result.Level          is 'Sanity check to ensure the student took the correct test';
comment on column Test_Result.SrcFile        is 'Name of the file from which the source data were loaded';

COMMIT;
