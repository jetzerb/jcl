-- Verify jcl:Student_View on pg

BEGIN;

do $$
declare
	vSchema text := 'public';
	vObject text := 'Student_View';
	vDiff   text;
	vDiff2  text;
begin
	-- Get list of column mismatches
	select string_agg(trim(trailing ', ' from concat(
		 col.colName
		,': '
		,case when tgt.column_name is null then 'Missing, '
		      when src.column_name is null then 'Extra, '
		 end
		,'data type ',coalesce(src.data_type_pattern,'-'),' vs ',coalesce(tgt.data_type  ,'-'),', '
	       ))
	      ,'; ' order by col.colName)

	into vDiff

	from (values
		-- Column Name                   Data Type Pattern
		 ('Student_Id'                  ,'smallint'         )
		,('Last_Name'                   ,'character varying')
		,('First_Name'                  ,'character varying')
		,('Level_Id'                    ,'smallint'         )
		,('Level'                       ,'smallint'         )
		,('Level_Name'                  ,'character varying')
		,('School_Id'                   ,'smallint'         )
		,('School_Name'                 ,'character varying')
		,('Problem'                     ,'text'             )
		) src(column_name               ,data_type_pattern  )
	full join (
                select column_name
                      ,concat(data_type,case when data_type = 'ARRAY' then concat(':',udt_name) end) as data_type
		from information_schema.columns
		where table_schema = lower(vSchema)
		  and table_name   = lower(vObject)) tgt
	  on tgt.column_name = lower(src.column_name)
	left join lateral (values (coalesce(src.column_name,tgt.column_name))) col(colName) on true
	where src.column_name       is null
	   or tgt.column_name       is null
           or tgt.data_type   not like src.data_type_pattern
	;

	insert into Level (Level_Id,Level_Name,Level) values (-899,'Unit Test Level',0);
	insert into School (School_Id,School_Name) values (-899,'Unit Test School');
	insert into Student(Student_Id,Level_Id,School_Id)
	            values (      -899,    -899,     -899)  -- all valid
	                  ,(      -898,    -898,     -899)  -- invalid level,   valid school
	                  ,(      -897,    -899,     -898)  --   valid level, invalid school
	                  ,(      -896,    -898,     -898); -- invalid level, invalid school

	select string_agg(format('(%s): "%s" vs "%s"',tst.stuId, tst.problem, stu.Problem),'; ')
	into vDiff2
	from (values
		--      RecId    Expected Output
		      ( -899    ,null)
		     ,( -898    ,'Invalid Level_Id')
		     ,( -897    ,'Invalid School_Id')
		     ,( -896    ,'Invalid Level_Id, School_Id')
		) tst (stuId,    problem)
	     left join Student_View stu on stu.Student_Id = tst.stuId
	where stu.Problem is distinct from tst.problem
	;

	select nullif(concat('Schema Check: ' || vDiff || '; '
	                    ,'Test Cases: '   || vDiff2),'') into vDiff;

	assert vDiff is null, vDiff;
end $$;

ROLLBACK;
