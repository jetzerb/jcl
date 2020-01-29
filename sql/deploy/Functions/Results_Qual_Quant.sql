-- Deploy jcl:Functions/Results_Qual_Quant to pg
-- requires: Views/Test_Result_View
-- requires: Tables/Test_Result
-- requires: Tables/Competition
-- requires: Tables/Student
-- requires: Tables/Level
-- requires: Tables/School

BEGIN;

/*

1st Place Qual  = Highest Avg Per Delegate of all schools
1st Place Quant = Highest Total Points of remaining schools
2nd Place Qual  = Highest Avg Per Delegate of remaining schools
2nd Place Quant = Highest Total Points of remaining schools
etc

*/
create or replace function Results_Qual_Quant
as


with School_Full_Points as (
	select School_Id, sum(Student_Score) as Points from Test_Result_View where School_Full_Points = 1 group by School_Id
)
,School_Partial_By_Level as (
	select School_Id,Student_Level_Id, avg(Student_Score) as Points from Test_Result_View where School_Full_Points = 0 group by School_Id,Student_Level_Id
)
,School_Partial_Points as (
	select School_Id, sum(Points) as Points from School_Partial_By_Level group by School_Id
)
,School_Total_Points as (
	select ful.School_Id
	      ,coalesce(ful.Points,0) + coalesce(prt.Points,0) as Points
	from           School_Full_Points    ful
	     full join School_Partial_Points prt on prt.School_Id = ful.School_Id
)
,School_Delegates as (
	select School_Id
	      ,count(1) as Num_Delegates
	from Student
	where Level_Id between 1 and 6
	group by School_Id
)
select sch.School_Name
      ,del.Num_Delegates
      ,pts.Points
      ,cast(pts.Points*1.0/del.Num_Delegates as numeric(6,2)) as Avg_Per_Delegate
      ,cast(null as int) as Qual_Place
      ,cast(null as int) as Quant_Place
into #results -- **** TODO from here down
from      School_Delegates    del
     join School_Total_Points pts on pts.School_Id = del.School_Id
     join School              sch on sch.School_Id = del.School_Id
;

declare @Place    int = 1
       ,@School_Id int
;
while exists (select 1 from #results where Qual_Place is null and Quant_Place is null)
begin
	with qual as (
		select top 1* from #results
		where Qual_Place is null and Quant_Place is null
		order by Avg_Per_Delegate desc
	)
	update qual set Qual_Place = @Place
	;
	with quant as (
		select top 1* from #results
		where Qual_Place is null and Quant_Place is null
		order by Points desc
	)
	update quant set Quant_Place = @Place
	;
	set @Place = @Place + 1;
end;

select *
from #results
order by Qual_Place desc,Quant_Place desc
;

COMMIT;
