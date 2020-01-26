-- Revert jcl:Tables/Student from pg

BEGIN;

drop table if exists Student;

COMMIT;
