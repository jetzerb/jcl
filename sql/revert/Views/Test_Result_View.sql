-- Revert jcl:Views/Test_Result_View from pg

BEGIN;

drop view if exists Test_Result_View;

COMMIT;
