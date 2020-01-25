-- Revert jcl:Tables/Level from pg

BEGIN;

drop table if exists Level;

COMMIT;
