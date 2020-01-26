-- Revert jcl:Tables/Test_Result from pg

BEGIN;

drop table if exists Test_Result;

COMMIT;
