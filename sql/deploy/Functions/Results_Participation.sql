-- Deploy jcl:Functions/Results_Participation to pg
-- requires: Tables/Student
-- requires: Tables/School
-- requires: Tables/Level
-- requires: Views/Test_Result_View

BEGIN;

/*

Show all students for each school along with what events they participated in

*/
create or replace function Results_Participation()
returns table (
	 School_Name         School.School_Name%type
	,Level_Name          Level.Level_Name%type
	,Last_Name           Student.Last_Name%type
	,First_Name          Student.First_Name%type
	,Competition_Name    Competition.Competition_Name%type
	,Score               Test_Result.Score%type
)
as $$

with delegate as (
	select sch.School_Name
	      ,stu.Student_Id,stu.Last_Name,stu.First_Name
	      ,lvl.Level_Name
	from           Student stu
	          join School  sch on sch.School_Id = stu.School_Id
	     left join Level   lvl on lvl.Level_Id  = stu.Level_Id
	where coalesce(stu.Level_Id,1) between 1 and 6
)
select del.School_Name
      ,del.Level_Name
      ,del.Last_Name,del.First_Name
      ,coalesce(res.Competition_Name,'<Participated in No Events>') as Competition_Name
      ,coalesce(res.Score,0) as Score
from           delegate         del
     left join Test_Result_View res on res.Student_Id = del.Student_Id
order by del.School_Name
        ,del.Level_Name
        ,del.Last_Name,del.First_Name
        ,res.Competition_Id
;
$$ language sql stable;

COMMIT;
