       IDENTIFICATION DIVISION.
       PROGRAM-ID. PARMGT.
      *----------------------------------------------------------------*
      * PARMGT  - Gestion centralizada de parametros de sistema        *
      *           Lee tabla PARAMETROS_SIS para configuracion          *
      *           Llamado por: EMIPOL RENOVA GENREC SINREG LIQUID      *
      *----------------------------------------------------------------*
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-MAINFRAME.
      *
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-RETURN-CODE         PIC S9(4) COMP VALUE 0.
      *
      * Cache de parametros en memoria (evita multiples lecturas DB2)
       01 WS-CACHE-LOADED        PIC X(1) VALUE 'N'.
       01 WS-TABLA-CACHE.
          05 WS-PARAM-ENTRY OCCURS 50 TIMES.
             10 WS-PARAM-CLAVE   PIC X(30).
             10 WS-PARAM-VALOR   PIC X(100).
             10 WS-PARAM-TIPO    PIC X(3).
       01 WS-CACHE-INDICE        PIC 9(3) VALUE 0.
       01 WS-IDX                 PIC 9(3) VALUE 0.
      *
       01 DCLGEN-PARAMETROS.
          05 HV-PAR-CLAVE        PIC X(30).
          05 HV-PAR-VALOR        PIC X(100).
          05 HV-PAR-TIPO         PIC X(3).
             88 HV-PAR-NUMERICO  VALUE 'NUM'.
             88 HV-PAR-TEXTO     VALUE 'TXT'.
             88 HV-PAR-FECHA     VALUE 'FEC'.
             88 HV-PAR-LOGICO    VALUE 'LOG'.
          05 HV-PAR-DESCRIPCION  PIC X(200).
          05 HV-PAR-ENTORNO      PIC X(5).
          05 SQLCODE             PIC S9(9) COMP.
      *
       LINKAGE SECTION.
       01 L-FUNCION              PIC X(1).
          88 L-OBTENER           VALUE 'G'.
          88 L-ACTUALIZAR        VALUE 'U'.
          88 L-LISTAR-ENTORNO    VALUE 'L'.
       01 L-CLAVE                PIC X(30).
       01 L-VALOR-SALIDA         PIC X(100).
       01 L-TIPO-DATO            PIC X(3).
       01 L-RETURN-CODE          PIC S9(4) COMP.
      *
       PROCEDURE DIVISION USING L-FUNCION
                                 L-CLAVE
                                 L-VALOR-SALIDA
                                 L-TIPO-DATO
                                 L-RETURN-CODE.
           MOVE 0 TO L-RETURN-CODE
           EVALUATE TRUE
             WHEN L-OBTENER
               PERFORM 1000-OBTENER-PARAMETRO
             WHEN L-ACTUALIZAR
               PERFORM 2000-ACTUALIZAR-PARAMETRO
             WHEN L-LISTAR-ENTORNO
               PERFORM 3000-LISTAR-PARAMETROS-ENTORNO
             WHEN OTHER
               MOVE 99 TO L-RETURN-CODE
           END-EVALUATE
           STOP RUN.
      *
       1000-OBTENER-PARAMETRO.
           IF WS-CACHE-LOADED = 'S'
              PERFORM VARYING WS-IDX FROM 1 BY 1
                  UNTIL WS-IDX > WS-CACHE-INDICE
                 IF WS-PARAM-CLAVE(WS-IDX) = L-CLAVE
                    MOVE WS-PARAM-VALOR(WS-IDX) TO L-VALOR-SALIDA
                    MOVE WS-PARAM-TIPO(WS-IDX)  TO L-TIPO-DATO
                    EXIT PERFORM
                 END-IF
              END-PERFORM
           ELSE
              MOVE L-CLAVE TO HV-PAR-CLAVE
              EXEC SQL
                  SELECT PAR_VALOR, PAR_TIPO
                  INTO :HV-PAR-VALOR, :HV-PAR-TIPO
                  FROM PARAMETROS_SIS
                  WHERE PAR_CLAVE  = :HV-PAR-CLAVE
                    AND PAR_ACTIVO = 'S'
              END-EXEC
              IF SQLCODE NOT = 0
                 MOVE 10 TO L-RETURN-CODE
              ELSE
                 MOVE HV-PAR-VALOR TO L-VALOR-SALIDA
                 MOVE HV-PAR-TIPO  TO L-TIPO-DATO
              END-IF
           END-IF.
      *
       2000-ACTUALIZAR-PARAMETRO.
           EXEC SQL
               UPDATE PARAMETROS_SIS
               SET PAR_VALOR = :L-VALOR-SALIDA,
                   PAR_FECHA_MOD = CURRENT TIMESTAMP
               WHERE PAR_CLAVE = :L-CLAVE
           END-EXEC
           IF SQLCODE NOT = 0
              MOVE 20 TO L-RETURN-CODE
           ELSE
              MOVE 'N' TO WS-CACHE-LOADED
           END-IF.
      *
       3000-LISTAR-PARAMETROS-ENTORNO.
           EXEC SQL
               DECLARE CUR_PARAMS CURSOR FOR
               SELECT PAR_CLAVE, PAR_VALOR, PAR_TIPO
               FROM PARAMETROS_SIS
               WHERE PAR_ACTIVO = 'S'
               ORDER BY PAR_CLAVE
           END-EXEC
           EXEC SQL OPEN CUR_PARAMS END-EXEC
           MOVE 1 TO WS-CACHE-INDICE
           PERFORM UNTIL SQLCODE NOT = 0 OR WS-CACHE-INDICE > 50
               EXEC SQL
                   FETCH CUR_PARAMS
                   INTO :HV-PAR-CLAVE, :HV-PAR-VALOR, :HV-PAR-TIPO
               END-EXEC
               IF SQLCODE = 0
                  MOVE HV-PAR-CLAVE  TO WS-PARAM-CLAVE(WS-CACHE-INDICE)
                  MOVE HV-PAR-VALOR  TO WS-PARAM-VALOR(WS-CACHE-INDICE)
                  MOVE HV-PAR-TIPO   TO WS-PARAM-TIPO(WS-CACHE-INDICE)
                  ADD 1 TO WS-CACHE-INDICE
               END-IF
           END-PERFORM
           EXEC SQL CLOSE CUR_PARAMS END-EXEC
           MOVE 'S' TO WS-CACHE-LOADED.
