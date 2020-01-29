-- Revert jcl:Functions/Results_Participation from pg

BEGIN;

drop function if exists Results_Participation;

COMMIT;
