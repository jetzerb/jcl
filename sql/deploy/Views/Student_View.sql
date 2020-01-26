-- Deploy jcl:Student_View to pg
-- requires: Tables/Student

BEGIN;

/*

Flat view of Individual Students

*/
create or replace view Student_View
as
select stu.Student_Id
      ,stu.Last_Name
      ,stu.First_Name
      ,stu.Level_Id
      ,lvl.Level
      ,lvl.Level_Name
      ,stu.School_Id
      ,sch.School_Name
      ,overlay(nullif(concat(case when lvl.Level_Id  is distinct from stu.Level_Id  then ', Level_Id'  end
                            ,case when sch.School_Id is distinct from stu.School_Id then ', School_Id' end)
                     ,'')
               placing 'Invalid' from 1 for 1) as Problem
from           Student stu
     left join Level   lvl on lvl.Level_Id  = stu.Level_Id
     left join School  sch on sch.School_Id = stu.School_Id
;

comment on view   Student_View             is 'Show flat view of student list, with level and school names';
comment on column Student_View.Student_Id  is 'from Student table';
comment on column Student_View.Last_Name   is 'from Student table';
comment on column Student_View.First_Name  is 'from Student table';
comment on column Student_View.Level_Id    is 'from Student table';
comment on column Student_View.Level_Name  is 'from Level table';
comment on column Student_View.School_Id   is 'from Student table';
comment on column Student_View.School_Name is 'from School table';
comment on column Student_View.Problem     is 'Blank unless the Level or School Id is invalid';

COMMIT;
