-- Revert jcl:Functions/Results_Qual_Quant from pg

BEGIN;

drop function if exists Results_Qual_Quant;

COMMIT;
