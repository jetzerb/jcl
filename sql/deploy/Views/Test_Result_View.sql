-- Deploy jcl:Views/Test_Result_View to pg
-- requires: Tables/Test_Result
-- requires: Tables/Competition
-- requires: Tables/Student
-- requires: Tables/Level
-- requires: Tables/School

BEGIN;

/*

Flat view of Individual Student scores for each competition
along with their rank within Competition ID + Level ID

NOTE: Points are awarded based on the top 10 *scores*, not the
top 10 students (plus a few extra in case of tie).  The top *score*
gets 10 points

*/
create or replace view Test_Result_View
as

with data as (
	select res.Competition_Id,com.Competition_Name,com.School_Full_Points
	      ,res.Student_Id    ,stu.Last_Name      ,stu.First_Name
	      ,cnv.Test_Level
	      ,lvlTst.Level_Name as Test_Level_Name
	      ,stu.Level_Id      as Student_Level_Id
	      ,lvlStu.Level_Name as Student_Level_Name
	      ,stu.School_Id     ,sch.School_Name
	      ,res.Score
	      ,      rank() over top_By_Comp as Student_Rank
	      ,dense_rank() over top_By_Comp as Score_Rank
	      ,concat(case when com.Competition_Id is null then 'Unknown Competition; ' end
	             ,case when stu.Student_Id / 1000 <> res.Level and res.Level between 1 and 4
	                     or stu.Student_Id / 1000 not in (4,5,6) and res.Level = 4
	                                                   then 'Id / Level Mismatch; ' end
	             ,case when stu.Student_Id     is null then 'Unknown Student; '     end
	             ,case when lvlTst.Level_Id    is null and res.Level > 0 then 'Unknown Level; ' end
	             ,case when sch.School_Id      is null then 'Unknown School; '      end
	       ) as Problem
	
	from           Test_Result  res
	     left join Competition  com    on    com.Competition_Id = res.Competition_Id
	     left join Student      stu    on    stu.Student_Id     = res.Student_Id
	     left join Level        lvlTst on lvlTst.level_Id       = res.Level
	     left join Level        lvlStu on lvlStu.Level_Id       = stu.Level_Id
	     left join School       sch    on    sch.School_Id      = stu.School_Id
	     cross join lateral (values (case when com.Score_By_Level then res.Level else 0 end)) cnv(Test_Level)

	window top_By_Comp as (partition by res.Competition_Id, cnv.Test_Level order by res.Score desc)
)
select *
      ,case when Score_Rank between 1 and 10 then 11 - Score_Rank else 0 end as Student_Score
from data
;

COMMIT;
