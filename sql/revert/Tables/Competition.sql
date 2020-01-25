-- Revert jcl:Tables/Competition from pg

BEGIN;

drop table if exists Competition;

COMMIT;
