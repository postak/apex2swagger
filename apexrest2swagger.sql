--
-- Author  : Luca Postacchini
-- Date    : May 2016
-- Version : 1.0
--
SET SERVEROUTPUT ON FORMAT WRAPPED
SET LINESIZE 10000
SET FEEDBACK OFF

DECLARE

  -- START PARAMETERS (change it)

  c_workspace CONSTANT varchar(100)    := 'telecomitalia';
  c_basepath CONSTANT varchar(100)     := '/ords/telecomitalia';
  c_description CONSTANT varchar(100) := 'Test Api REST su ambiente CRMA e CCSTOP';
  c_title CONSTANT varchar(100)       := 'Test Api REST';
  c_hostname CONSTANT varchar(100)     := '140.86.6.49';
  c_port CONSTANT number(4)            := 80;

  -- END PARAMETERS (change it)

  cur_workspace     APEX_REST_RESOURCE_HANDLERS.workspace%type;
  cur_module_name   APEX_REST_RESOURCE_TEMPLATES.module_name%type;
  cur_method        APEX_REST_RESOURCE_HANDLERS.method%type;
  cur_uri_template  APEX_REST_RESOURCE_HANDLERS.uri_template%type;
  cur_uri_prefix    APEX_REST_RESOURCE_MODULES.uri_prefix%type;
  cur_source_type   APEX_REST_RESOURCE_HANDLERS.source_type%type;
  cur_source        APEX_REST_RESOURCE_HANDLERS.source%type;
  cur_format        APEX_REST_RESOURCE_HANDLERS.format%type;
  cur_pattern       user_ords_services.pattern%type;

  v_lastpath varchar(100);
  v_singleparam varchar(100);
  v_allparams varchar(100);
  v_prefix varchar(100);

  TYPE pattern IS TABLE OF varchar(100) INDEX BY PLS_INTEGER;

  v_pattern pattern;

  CURSOR cur_services is
         SELECT  DISTINCT APEX_REST_RESOURCE_HANDLERS.workspace workspace,
            APEX_REST_RESOURCE_TEMPLATES.module_name,
            method, APEX_REST_RESOURCE_MODULES.uri_prefix,
            APEX_REST_RESOURCE_TEMPLATES.uri_template, source_type , to_char(source ) source, format
          FROM  APEX_REST_RESOURCE_HANDLERS, APEX_REST_RESOURCE_TEMPLATES,
	     APEX_REST_RESOURCE_MODULES WHERE
             APEX_REST_RESOURCE_HANDLERS.template_id = APEX_REST_RESOURCE_TEMPLATES.template_id AND
             APEX_REST_RESOURCE_MODULES.module_name = APEX_REST_RESOURCE_TEMPLATES.module_name AND
             APEX_REST_RESOURCE_HANDLERS.workspace = UPPER(c_workspace)
          ORDER BY module_name,uri_prefix, uri_template;
BEGIN

   dbms_output.put_line('swagger: "2.0"');
   dbms_output.put_line('info:');
   dbms_output.put_line('  title: ' || c_title);
   dbms_output.put_line('  description: ' || c_description);
   dbms_output.put_line('  version: "1.0.0"');
   dbms_output.put_line('# the domain of the service');
   dbms_output.put_line('host: ' || c_hostname || ':' || c_port);
   dbms_output.put_line('basePath: ' || c_basepath);
   dbms_output.put_line('schemes:');
   dbms_output.put_line('  - http');
   dbms_output.put_line('  - https');
   dbms_output.put_line('consumes:');
   dbms_output.put_line('  - application/json');
   dbms_output.put_line('produces:');
   dbms_output.put_line('  - application/json');
   dbms_output.put_line('paths:');

   v_lastpath := '@';

   OPEN cur_services;
   LOOP
      FETCH cur_services INTO cur_workspace ,cur_module_name, cur_method,
           cur_uri_prefix, cur_uri_template, cur_source_type, cur_source , cur_format;
      EXIT WHEN cur_services%notfound;


      IF INSTR( cur_uri_template, '{' , 1 ) > 0 THEN
          -- c'e' almeno un parametro

          v_prefix := SUBSTR (cur_uri_template, 1, INSTR( cur_uri_template, '{' , 1 ) - 1);
          v_allparams := SUBSTR (cur_uri_template, INSTR( cur_uri_template, '{' , 1 ));

          IF (cur_uri_template != v_lastpath) THEN
            v_lastpath := cur_uri_template;
            dbms_output.put_line('  /' || cur_uri_prefix || cur_uri_template || ':');
          END IF;
          dbms_output.put_line('    ' || LOWER( cur_method ) || ':');
          dbms_output.put_line('      parameters: ');


          FOR i IN 1 .. LENGTH (v_allparams)
            LOOP
              v_pattern (i) := REGEXP_SUBSTR (v_allparams, '[^/]+', 1, i);
              EXIT WHEN v_pattern (i) IS NULL;

              v_singleparam := REPLACE (REPLACE (v_pattern (i), '{', ''), '}' , '');

              dbms_output.put_line('        - name: ' || v_singleparam );
              dbms_output.put_line('          in: path');
              dbms_output.put_line('          type: string');
              dbms_output.put_line('          description: parameter ' || v_singleparam );
              dbms_output.put_line('          required: true');

          END LOOP;

          dbms_output.put_line('      responses:');
          dbms_output.put_line('        200:');

          CASE LOWER( cur_method )
            WHEN 'get' THEN dbms_output.put_line('          description: return data from | ');
            WHEN 'put' THEN dbms_output.put_line('          description: insert data to | ' );
            WHEN 'post' THEN dbms_output.put_line('          description: insert data to | ' );
            WHEN 'delete' THEN dbms_output.put_line('          description: delete record in | ');
            ELSE dbms_output.put_line('          description: unkknown operation | ');
          END CASE;

          dbms_output.put_line('            ' || replace( cur_source, CHR(10) , CHR(10) || '            '));

      ELSE
          -- pattern
          dbms_output.put_line('  /' || REPLACE (cur_uri_prefix || cur_uri_template, '//', '/') || ':');
          dbms_output.put_line('    ' || LOWER( cur_method ) || ':');

          IF (LOWER ( cur_method  ) = 'post') THEN
              dbms_output.put_line('      produces:');
              dbms_output.put_line('        - application/json');
              dbms_output.put_line('      parameters:');
              dbms_output.put_line('        - in: body');
              dbms_output.put_line('          name: body');
              dbms_output.put_line('          description: user data in JSON');
              dbms_output.put_line('          required: true');
              dbms_output.put_line('          schema:');
              dbms_output.put_line('            type: object');
          END IF;

          dbms_output.put_line('      responses:');
          dbms_output.put_line('        200:');
          CASE LOWER( cur_method )
            WHEN 'get' THEN    dbms_output.put_line('          description: get data from the following statement | ' );
            WHEN 'put' THEN    dbms_output.put_line('          description: insert data using the following pl/sql | ');
            WHEN 'post' THEN   dbms_output.put_line('          description: insert data using the following pl/sql | ');
            WHEN 'delete' THEN dbms_output.put_line('          description: delete record using the following pl/sql | ');
            ELSE               dbms_output.put_line('          description: unkknown operation | ');

            dbms_output.put_line('            ' || replace( cur_source, CHR(10) , CHR(10) || '            '));

          END CASE;
      END IF;
   END LOOP;
   CLOSE cur_services;
END;
/