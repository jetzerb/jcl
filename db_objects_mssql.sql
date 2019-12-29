
drop table if exists dbo.Competition;
go
create table dbo.Competition
(
	 CompetitionId    int
	,CompetitionName  varchar(50)
	,SchoolFullPoints bit
	,ScoreByLevel     bit
);
go

drop table if exists dbo.Level;
go
create table dbo.Level
(
	 LevelId   int
	,LevelName varchar(30)
	,Level     int
);
go

drop table if exists dbo.School;
go
create table dbo.School
(
	 SchoolId   int
	,SchoolName varchar(50)
);
go

drop table if exists dbo.Student;
go
create table dbo.Student
(
	 StudentId int               not null
	,SchoolId  int
	,LastName  varchar(20)
	,FirstName varchar(15)
	,LevelId   int
	,constraint Student_PK primary key(StudentId)
);
go

drop view if exists dbo.Student_View;
go
--
-- Flat view of Individual Students
--
-- *bj 2019-01-31 created
--
create view Student_View
as
select stu.StudentId
      ,stu.LastName
      ,stu.FirstName
      ,stu.LevelId
      ,lvl.Level
      ,lvl.LevelName
      ,stu.SchoolId
      ,sch.SchoolName
      ,Problem = stuff(case when lvl.LevelId  = stu.LevelId  then '' else ', LevelId'  end
                      +case when sch.SchoolId = stu.SchoolId then '' else ', SchoolId' end
                 ,1,2,'Invalid ')
from           Student stu
     left join Level   lvl on lvl.LevelId  = stu.LevelId
     left join School  sch on sch.SchoolId = stu.SchoolId
;
go

drop table if exists dbo.TestResult;
go
create table dbo.TestResult
(
	 CompetitionId int
	,StudentId     int
	,Score         numeric(4,1)
	,Level         int
	,SrcFile       varchar(50)
);
go

drop view if exists dbo.TestResult_View;
go
--
-- Flat view of Individual Student scores for each competition
-- along with their rank within Competition ID + Level ID
--
-- NOTE: Points are awarded based on the top 10 *scores*, not the
-- top 10 students (plus a few extra in case of tie).  The top *score*
-- gets 10 points
--
-- *bj 2016-01-28 created
--
create view TestResult_View
as
with data as (
	select res.CompetitionId,com.CompetitionName,com.SchoolFullPoints
	      ,res.StudentId    ,stu.FirstName      ,stu.LastName
	      ,TestLevel        = case when com.ScoreByLevel = 1 then res.Level     else 0 end
	      ,TestLevelName    = lvlTst.LevelName
	      ,StudentLevelId   = stu.LevelId
	      ,StudentLevelName = lvlStu.LevelName
	      ,stu.SchoolId     ,sch.SchoolName
	      ,res.Score
	      ,StudentRank      =       rank() over (partition by res.CompetitionId, case when com.ScoreByLevel = 1 then res.Level else 0 end order by res.Score desc)
	      ,ScoreRank        = dense_rank() over (partition by res.CompetitionId, case when com.ScoreByLevel = 1 then res.Level else 0 end order by res.Score desc)
	      ,Problem = concat(case when com.CompetitionId is null then 'Unknown Competition; ' end
	                       ,case when stu.StudentId / 1000 <> res.Level and res.Level between 1 and 4
	                               or stu.StudentId / 1000 not in (4,5,6) and res.Level = 4
	                                                            then 'Id / Level Mismatch; ' end
	                       ,case when stu.StudentId     is null then 'Unknown Student; '     end
	                       ,case when lvlTst.LevelId    is null and res.Level > 0 then 'Unknown Level; '       end
	                       ,case when sch.SchoolId      is null then 'Unknown School; '      end
	                  )
	
	from           TestResult  res
	     left join Competition com    on    com.CompetitionId = res.CompetitionId
	     left join Student     stu    on    stu.StudentId     = res.StudentId
	     left join Level       lvlTst on lvlTst.levelId       = res.Level
	     left join Level       lvlStu on lvlStu.LevelId       = stu.LevelId
	     left join School      sch    on    sch.SchoolId      = stu.SchoolId
)
select *
      ,StudentScore = case when ScoreRank between 1 and 10 then 11- ScoreRank else 0 end
from data
;
go

drop procedure if exists dbo.Results_Participation;
go
--
-- Show all students for each school along with what events they participated in
--
-- *bj 2016-01-29 created
--
create proc Results_Participation
as

with delegate as (
	select sch.SchoolName
	      ,stu.StudentId,stu.LastName,stu.FirstName
	      ,lvl.LevelName
	from           Student stu
	          join School  sch on sch.SchoolId = stu.SchoolId
	     left join Level   lvl on lvl.LevelId  = stu.LevelId
	where coalesce(stu.LevelId,1) between 1 and 6
)
select del.SchoolName
      ,del.LevelName
      ,del.LastName,del.FirstName
      ,CompetitionName = coalesce(res.CompetitionName,'<Participated in No Events>')
      ,Score = coalesce(res.Score,0)
from           delegate        del
     left join TestResult_View res on res.StudentId = del.StudentId
order by del.SchoolName
        ,del.LevelName
        ,del.LastName,del.FirstName
        ,res.CompetitionId
;
go

drop procedure if exists dbo.Results_QualQuant;
go
--
-- 1st Place Qual  = Highest Avg Per Delegate of all schools
-- 1st Place Quant = Highest Total Points of remaining schools
-- 2nd Place Qual  = Highest Avg Per Delegate of remaining schools
-- 2nd Place Quant = Highest Total Points of remaining schools
-- etc
--
-- *bj 2016-01-29 created
--
create proc Results_QualQuant
as

set nocount on;

with SchoolFullPoints as (
	select SchoolId      ,Points = sum(StudentScore) from TestResult_View where SchoolFullPoints = 1 group by SchoolId
), SchoolPartialByLevel as (
	select SchoolId,StudentLevelId,Points = avg(StudentScore) from TestResult_View where SchoolFullPoints = 0 group by SchoolId,StudentLevelId
), SchoolPartialPoints as (
	select SchoolId      ,Points = sum(Points      ) from SchoolPartialByLevel group by SchoolId
), SchoolTotalPoints as (
	select ful.SchoolId
	      ,Points = coalesce(ful.Points,0) + coalesce(prt.Points,0)
	from           SchoolFullPoints    ful
	     full join SchoolPartialPoints prt on prt.SchoolId = ful.SchoolId
), SchoolDelegates as (
	select SchoolId
	      ,NumDelegates = count(1)
	from Student
	where LevelId between 1 and 6
	group by SchoolId
)
select sch.SchoolName
      ,del.NumDelegates
      ,pts.Points
      ,AvgPerDelegate = cast(pts.Points*1.0/del.NumDelegates as numeric(6,2))
      ,QualPlace      = cast(null as int)
      ,QuantPlace     = cast(null as int)
into #results
from      SchoolDelegates   del
     join SchoolTotalPoints pts on pts.SchoolId = del.SchoolId
     join School            sch on sch.SchoolId = del.SchoolId
;

declare @Place    int = 1
       ,@SchoolId int
;
while exists (select 1 from #results where QualPlace is null and QuantPlace is null)
begin
	with qual as (
		select top 1* from #results
		where QualPlace is null and QuantPlace is null
		order by AvgPerDelegate desc
	)
	update qual set QualPlace = @Place
	;
	with quant as (
		select top 1* from #results
		where QualPlace is null and QuantPlace is null
		order by Points desc
	)
	update quant set QuantPlace = @Place
	;
	set @Place = @Place + 1;
end;

select *
from #results
order by QualPlace desc,QuantPlace desc
;
go

drop procedure if exists dbo.Results_Top10;
go
--
-- Dump out formatted-ish top 10 list by competition and level
--
-- *bj 2016-01-29 created
--
create proc Results_Top10
as

select *
      ,Place  = cast(ScoreRank as varchar(5))
      ,Points = cast(StudentScore as varchar(5))
      ,CompLevel = case when TestLevel = -1 then 'All' else 'Level ' + rtrim(TestLevel) end
      ,Grp1   = CompetitionId
      ,Grp2   = TestLevel
      ,Grp3   = cast(9 as int)
into #results
from TestResult_View
where StudentScore > 0
;
alter table #results drop column Problem;

insert into #results (Grp1,Grp2,Grp3)
	select distinct Grp1,Grp2,0 from #results; -- blank space between competitions
insert into #results (Grp1,Grp2,Grp3)
	select distinct Grp1,Grp2,0 from #results; -- blank space between competitions
insert into #results (Grp1,Grp2,Grp3,CompetitionName)
	select distinct Grp1,Grp2,1,CompetitionName from #results where CompetitionName is not null; -- Competition Header
insert into #results (Grp1,Grp2,Grp3)
	select distinct Grp1,Grp2,2 from #results; -- blank space between levels
insert into #results (Grp1,Grp2,Grp3,CompLevel)
	select distinct Grp1,Grp2,3,CompLevel from #results where CompLevel is not null; -- Level header

update #results
set CompetitionName = coalesce(CompetitionName,'')
   ,CompLevel       = coalesce(CompLevel      ,'')
   ,Place           = coalesce(Place          ,'')
   ,Points          = coalesce(Points         ,'')
   ,SchoolName      = coalesce(SchoolName     ,'')
   ,FirstName       = coalesce(FirstName      ,'')
   ,LastName        = coalesce(LastName       ,'')
   ,StudentLevelName= coalesce(StudentLevelName,'')

select Competition = case when Grp3 = 1 then CompetitionName else '' end
      ,Level       = case when Grp3 = 3 then CompLevel       else '' end
      ,Place
      ,Points
      ,SchoolName,FirstName,LastName
      ,StudentLevelName
from #results
order by Grp1,Grp2,Grp3
        ,StudentScore
;
go

drop procedure if exists dbo.Results_TopOverall;
go
--
-- Show top 10 students overall
--
-- *bj 2016-01-29 created
--
create proc Results_TopOverall
	 @Places int = 10
as

with data as (
	select Place     = row_number() over (order by sum(StudentScore) desc)
	      ,Points    = sum(StudentScore)
	      ,SchoolName
	      ,FirstName,LastName
	      ,StudentLevel = StudentLevelName
	from TestResult_View res
	group by SchoolName,FirstName,LastName,StudentLevelName
)
select *
from data
where Place <= @Places
order by Place desc
;
go

