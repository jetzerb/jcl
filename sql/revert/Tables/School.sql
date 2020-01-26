-- Revert jcl:Tables/School from pg

BEGIN;

drop table if exists School;

COMMIT;
