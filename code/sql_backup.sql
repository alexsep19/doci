create or replace PACKAGE     ODS.PK_BACKUP AUTHID CURRENT_USER IS
   PROCEDURE BACKUP_TABLE(p_table   VARCHAR2, p_version   VARCHAR2);
   PROCEDURE ROLLBACK_TABLE(p_schema VARCHAR2, p_table   VARCHAR2, p_version   VARCHAR2);
   PROCEDURE DROP_TABLE(p_table VARCHAR2);
   PROCEDURE DROP_SEQUENCE(p_seq VARCHAR2);
   PROCEDURE DROP_VIEW(p_VIEW VARCHAR2);
   PROCEDURE DROP_TRIGGER(p_TRIGGER VARCHAR2);
   PROCEDURE DROP_INDEX(p_INDEX VARCHAR2);
   PROCEDURE DROP_TYPE(p_TYPE VARCHAR2);
   PROCEDURE DROP_TYPE_BODY(p_BODY VARCHAR2);
   PROCEDURE DROP_JOB(p_JOB VARCHAR2);
   PROCEDURE DROP_PROCEDURE(p_PROCEDURE VARCHAR2);
   PROCEDURE DROP_SYNONYM(p_SYNONYM VARCHAR2);
   PROCEDURE DROP_COLUMN(p_table VARCHAR2, p_column VARCHAR2);
   PROCEDURE SET_FK_CONSTRAINTS(p_schema VARCHAR2, p_TABLE VARCHAR2, p_flag number);
   PROCEDURE DROP_GRANT(p_grant VARCHAR2, p_object VARCHAR2, p_user VARCHAR2);
END PK_BACKUP;
/
create or replace PACKAGE BODY      ODS.PK_BACKUP AS
----------------------------------------------------------
  PROCEDURE BACKUP_TABLE(p_table VARCHAR2,
                         p_version VARCHAR2) IS
    v_backup_table_name   VARCHAR2(100) := UPPER(TRIM(p_table)) || '_' || UPPER(TRIM(p_version));
    v_table  VARCHAR2(100) := TRIM(p_table);
  BEGIN
     DROP_TABLE(v_backup_table_name);
     EXECUTE IMMEDIATE 'CREATE TABLE ' || v_backup_table_name || ' as (select * from '|| v_table || ')';
  END BACKUP_TABLE;

----------------------------------------------------------
  PROCEDURE ROLLBACK_TABLE(p_schema VARCHAR2,
                           p_table   VARCHAR2,
                           p_version   VARCHAR2) IS
    v_backup_table_name   VARCHAR2(100) := UPPER(TRIM(p_table)) || '_' || UPPER(TRIM(p_version));
    v_table  VARCHAR2(100) := UPPER(TRIM(p_table));
    v_tmp_table VARCHAR2(100) := p_table || 'XXX';
    v_schema VARCHAR2(50) := UPPER(TRIM(p_schema));
  BEGIN
     SET_FK_CONSTRAINTS( v_schema, v_table,  0);
     EXECUTE IMMEDIATE 'TRUNCATE TABLE ' || v_schema || '.' || v_table;
--     DROP_TABLE(v_tmp_table);
--     EXECUTE IMMEDIATE 'CREATE TABLE ' || v_tmp_table || ' as (select * from '|| v_backup_table_name || ')';
--     DROP_TABLE(v_table);
--     EXECUTE IMMEDIATE 'RENAME TABLE ' || v_tmp_table || ' TO ' || v_table;
     EXECUTE IMMEDIATE 'INSERT into ' || v_schema || '.' || v_table || ' select * from '|| v_schema || '.' || v_backup_table_name;
     SET_FK_CONSTRAINTS( v_schema, v_table, 1);
  END ROLLBACK_TABLE;

----------------------------------------------------------
-- 0 DISABLE, 1 - ENABLE
  PROCEDURE SET_FK_CONSTRAINTS(p_schema VARCHAR2, p_TABLE VARCHAR2,  p_flag number) is
    v_flag VARCHAR2(50);
  BEGIN
     if (p_flag = 0) then
        v_flag := 'DISABLE';
     ELSE
        v_flag := 'ENABLE';
     END IF;

     FOR rec in ( SELECT c.CONSTRAINT_NAME, c.table_name FROM ALL_CONSTRAINTS c
                  join ALL_CONSTRAINTS p on c.r_constraint_name = p.constraint_name and p.TABLE_NAME = p_TABLE
                  and p.owner = p_schema
                  WHERE c.constraint_type = 'R' and c.owner = p_schema)LOOP
          EXECUTE IMMEDIATE 'ALTER TABLE ' || p_schema || '.' || rec.table_name || ' ' || v_flag || ' CONSTRAINT ' || rec.CONSTRAINT_NAME;
     END LOOP;
  END SET_FK_CONSTRAINTS;

----------------------------------------------------------
  PROCEDURE DROP_TABLE(p_table VARCHAR2) AS BEGIN
     BEGIN
       EXECUTE IMMEDIATE 'DROP TABLE ' || p_table;
     EXCEPTION
       WHEN OTHERS THEN
       dbms_output.put_line('SQLCODE = '||SQLCODE);
         IF SQLCODE != -942 THEN
            RAISE;
         END IF;
     END;
  END DROP_TABLE;

----------------------------------------------------------
  PROCEDURE DROP_SEQUENCE(p_seq VARCHAR2) AS BEGIN
     BEGIN
       EXECUTE IMMEDIATE 'DROP SEQUENCE ' || p_seq;
     EXCEPTION
       WHEN OTHERS THEN
         IF SQLCODE != -2289 THEN
            RAISE;
         END IF;
     END;
  END DROP_SEQUENCE;
----------------------------------------------------------
  PROCEDURE DROP_VIEW(p_VIEW VARCHAR2) AS BEGIN
     BEGIN
       EXECUTE IMMEDIATE 'DROP VIEW ' || p_VIEW;
     EXCEPTION
       WHEN OTHERS THEN
         IF SQLCODE != -942 THEN
            RAISE;
         END IF;
     END;
  END DROP_VIEW;

----------------------------------------------------------
  PROCEDURE DROP_TRIGGER(p_TRIGGER VARCHAR2) AS BEGIN
     BEGIN
       EXECUTE IMMEDIATE 'DROP TRIGGER ' || p_TRIGGER;
     EXCEPTION
       WHEN OTHERS THEN
         IF SQLCODE != -4080 THEN
            RAISE;
         END IF;
     END;
  END DROP_TRIGGER;

----------------------------------------------------------
  PROCEDURE DROP_INDEX(p_INDEX VARCHAR2) AS BEGIN
     BEGIN
       EXECUTE IMMEDIATE 'DROP INDEX ' || p_INDEX;
     EXCEPTION
       WHEN OTHERS THEN
         IF SQLCODE != -1418 THEN
            RAISE;
         END IF;
     END;
  END DROP_INDEX;

----------------------------------------------------------
  PROCEDURE DROP_TYPE(p_TYPE VARCHAR2) AS BEGIN
     BEGIN
       EXECUTE IMMEDIATE 'DROP TYPE ' || p_TYPE;
     EXCEPTION
       WHEN OTHERS THEN
         IF SQLCODE != -4043 THEN
            RAISE;
         END IF;
     END;
  END DROP_TYPE;


----------------------------------------------------------
  PROCEDURE DROP_TYPE_BODY(p_BODY VARCHAR2) AS BEGIN
     BEGIN
       EXECUTE IMMEDIATE 'DROP TYPE BODY ' || p_BODY;
     EXCEPTION
       WHEN OTHERS THEN
       IF SQLCODE != -4043 THEN
            RAISE;
       END IF;
     END;
  END DROP_TYPE_BODY;

----------------------------------------------------------
  PROCEDURE DROP_JOB(p_JOB VARCHAR2) AS BEGIN
     BEGIN
       dbms_scheduler.drop_job(p_JOB);
     EXCEPTION
       WHEN OTHERS THEN
         IF SQLCODE != -27475 THEN
            RAISE;
         END IF;
     END;
  END DROP_JOB;

----------------------------------------------------------
  PROCEDURE DROP_PROCEDURE(p_PROCEDURE VARCHAR2) AS BEGIN
     BEGIN
       EXECUTE IMMEDIATE 'DROP PROCEDURE ' || p_PROCEDURE;
     EXCEPTION
       WHEN OTHERS THEN
         IF SQLCODE != -4043 THEN
            RAISE;
         END IF;
     END;
  END DROP_PROCEDURE;

----------------------------------------------------------
  PROCEDURE DROP_SYNONYM(p_SYNONYM VARCHAR2) AS BEGIN
     BEGIN
       EXECUTE IMMEDIATE 'DROP PROCEDURE ' || p_SYNONYM;
     EXCEPTION
       WHEN OTHERS THEN
--        IF SQLCODE != -1031 THEN
        IF SQLCODE != -4043 and SQLCODE != -1031 THEN
            RAISE;
        END IF;
     END;
  END DROP_SYNONYM;


----------------------------------------------------------
  PROCEDURE DROP_COLUMN(p_table VARCHAR2, p_column VARCHAR2) AS BEGIN
     BEGIN
       EXECUTE IMMEDIATE 'ALTER TABLE ' || p_table || ' DROP COLUMN ' || p_column;
     EXCEPTION
       WHEN OTHERS THEN
        IF SQLCODE != -904 THEN
            RAISE;
        END IF;
     END;
  END DROP_COLUMN;

---------------------------------------------------------
  PROCEDURE DROP_GRANT(p_grant VARCHAR2, p_object VARCHAR2, p_user VARCHAR2) AS BEGIN
     BEGIN
       EXECUTE IMMEDIATE 'REVOKE ' || p_grant || ' ON ' || p_object || ' FROM ' || p_user;
     EXCEPTION
       WHEN OTHERS THEN
--          IF SQLCODE != -942 THEN
          IF SQLCODE != -4042 and SQLCODE != -942  THEN
             RAISE;
          END IF;
     END;
  END DROP_GRANT;

END PK_BACKUP;
/