-- Deploy jcl:Tables/Competition to pg

BEGIN;

/*

List of Competitions at the JCL event

*/
create table if not exists Competition
(
	 Competition_Id     smallint    not null -- identifier for competition
	,Competition_Name   varchar(50) not null -- descriptive name
	,School_Full_Points boolean     not null -- true if school gets full points, false for team sports where students each get same # points, but school gets that same number rather than the sum of the student's points
	,Score_By_Level     boolean     not null -- true if compute rankings by level, false if overall
	,Description        text

	,constraint Competition_PK primary key (Competition_Id)
);
comment on table  Competition                    is 'Competition Master Table.  Each competition is represented in this table.';
comment on column Competition.Competition_Id     is 'Numeric Identifier for the competition.  There are few enough competitions that people generally remember which number goes with which competition.';
comment on column Competition.Competition_Name   is 'Human-readable name for the competition';
comment on column Competition.School_Full_Points is 'True if the school gets the sum of the scores from the students on the team, False if the school gets the score awarded to the team (i.e. each student gets credit for NN points, and the school also gets NN points instead of NN * <#team members> points).';
comment on column Competition.Score_By_Level     is 'True if the competition awards are given out at each level, False if one set of awards are given out across all levels.';
comment on column Competition.Description        is 'Explanation of the competition, including rules and any subtleties or nuances';

COMMIT;
