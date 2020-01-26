-- Verify jcl:Tables/School on pg

BEGIN;

do $$
declare
	vSchema text := 'public';
	vObject text := 'School';
	vDiff   text;
begin
	-- Get list of column mismatches
	select string_agg(trim(trailing ', ' from concat(
		 col.colName
		,': '
		,case when tgt.column_name is null then 'Missing, '
		      when src.column_name is null then 'Extra, '
		 end
		,'data type ',coalesce(src.data_type_pattern,'-'),' vs ',coalesce(tgt.data_type  ,'-'),', '
		,'nullable ' ,coalesce(src.is_nullable      ,'-'),' vs ',coalesce(tgt.is_nullable,'-'),', '
	       ))
	      ,'; ' order by col.colName)
	from (values
		-- Column Name                   Data Type Pattern    Nullable?
		 ('School_Id'                  ,'smallint'          ,'NO' )
		,('School_Name'                ,'character varying' ,'NO' )
		) src(column_name               ,data_type_pattern   ,is_nullable)
	full join (
                select column_name,is_nullable
                      ,concat(data_type,case when data_type = 'ARRAY' then concat(':',udt_name) end) as data_type
		from information_schema.columns
		where table_schema = lower(vSchema)
		  and table_name   = lower(vObject)) tgt
	  on tgt.column_name = lower(src.column_name)
	left join lateral (values (coalesce(src.column_name,tgt.column_name))) col(colName) on true
	where src.column_name       is null
	   or tgt.column_name       is null
           or tgt.data_type   not like src.data_type_pattern
	   or tgt.is_nullable       <> upper(src.is_nullable)
	into vDiff;

	assert vDiff is null, vDiff;
end $$;

ROLLBACK;
