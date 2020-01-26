-- Revert jcl:Student_View from pg

BEGIN;

drop view if exists Student_View;

COMMIT;
