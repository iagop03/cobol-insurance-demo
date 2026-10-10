       IDENTIFICATION DIVISION.
       PROGRAM-ID. FTPCTL.
      *----------------------------------------------------------------*
      * FTPCTL  - Control de transferencias SFTP/FTP                   *
      *           Gestiona envio y recepcion de ficheros batch         *
      *           Llamado por: LIQUID COBRAN (remesas bancarias)       *
      *----------------------------------------------------------------*
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-MAINFRAME.
      *
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-RETURN-CODE         PIC S9(4) COMP VALUE 0.
       01 WS-PARM-VALOR          PIC X(100).
       01 WS-PARM-TIPO           PIC X(3).
       01 WS-PARM-RC             PIC S9(4) COMP VALUE 0.
       01 WS-PARM-FUNCION        PIC X(1).
      *
       01 WS-SFTP-HOST           PIC X(50).
       01 WS-SFTP-PUERTO         PIC 9(5) VALUE 22.
       01 WS-SFTP-USUARIO        PIC X(30).
       01 WS-SFTP-DIRECTORIO     PIC X(100).
       01 WS-SFTP-TIMEOUT        PIC 9(4) VALUE 30.
      *
       01 WS-FTP-CONTROL.
          05 WS-FTP-ARCHIVO-LOC  PIC X(80).
          05 WS-FTP-ARCHIVO-REM  PIC X(80).
          05 WS-FTP-OPERACION    PIC X(3).
             88 WS-FTP-ENVIAR    VALUE 'SND'.
             88 WS-FTP-RECIBIR   VALUE 'RCV'.
             88 WS-FTP-LISTAR    VALUE 'LST'.
             88 WS-FTP-BORRAR    VALUE 'DEL'.
          05 WS-FTP-MODO         PIC X(3).
             88 WS-FTP-BINARIO   VALUE 'BIN'.
             88 WS-FTP-ASCII     VALUE 'ASC'.
      *
       01 DCLGEN-FTP-AUDITORIA.
          05 HV-AUD-ID           PIC 9(10).
          05 HV-AUD-ENTIDAD      PIC X(20).
          05 HV-AUD-OPERACION    PIC X(3).
          05 HV-AUD-ARCHIVO-LOC  PIC X(80).
          05 HV-AUD-ARCHIVO-REM  PIC X(80).
          05 HV-AUD-ESTADO       PIC X(2).
             88 HV-AUD-OK        VALUE 'OK'.
             88 HV-AUD-ERROR     VALUE 'ER'.
             88 HV-AUD-PENDING   VALUE 'PE'.
          05 HV-AUD-BYTES        PIC 9(12).
          05 HV-AUD-FECHA-INI    PIC X(26).
          05 HV-AUD-FECHA-FIN    PIC X(26).
          05 HV-AUD-MENSAJE-ERR  PIC X(200).
          05 SQLCODE             PIC S9(9) COMP.
      *
       LINKAGE SECTION.
       01 L-ENTIDAD              PIC X(20).
       01 L-ARCHIVO-LOCAL        PIC X(80).
       01 L-ARCHIVO-REMOTO       PIC X(80).
       01 L-OPERACION            PIC X(3).
       01 L-MODO                 PIC X(3).
       01 L-BYTES-TRANSFERIDOS   PIC 9(12).
       01 L-RETURN-CODE          PIC S9(4) COMP.
      *
       PROCEDURE DIVISION USING L-ENTIDAD
                                 L-ARCHIVO-LOCAL
                                 L-ARCHIVO-REMOTO
                                 L-OPERACION
                                 L-MODO
                                 L-BYTES-TRANSFERIDOS
                                 L-RETURN-CODE.
           MOVE 0 TO L-RETURN-CODE
           MOVE 0 TO L-BYTES-TRANSFERIDOS
           PERFORM 1000-CARGAR-PARAMETROS-FTP
           IF L-RETURN-CODE = 0
              PERFORM 2000-REGISTRAR-INICIO-AUDITORIA
           END-IF
           IF L-RETURN-CODE = 0
              MOVE L-ARCHIVO-LOCAL  TO WS-FTP-ARCHIVO-LOC
              MOVE L-ARCHIVO-REMOTO TO WS-FTP-ARCHIVO-REM
              MOVE L-OPERACION      TO WS-FTP-OPERACION
              MOVE L-MODO           TO WS-FTP-MODO
              EVALUATE TRUE
                WHEN WS-FTP-ENVIAR
                  PERFORM 3000-ENVIAR-FICHERO
                WHEN WS-FTP-RECIBIR
                  PERFORM 4000-RECIBIR-FICHERO
                WHEN WS-FTP-LISTAR
                  PERFORM 5000-LISTAR-DIRECTORIO
                WHEN OTHER
                  MOVE 91 TO L-RETURN-CODE
              END-EVALUATE
           END-IF
           PERFORM 6000-CERRAR-AUDITORIA
           STOP RUN.
      *
       1000-CARGAR-PARAMETROS-FTP.
           MOVE 'G' TO WS-PARM-FUNCION
      *    Host SFTP de la entidad bancaria
           STRING 'FTP.' DELIMITED SIZE
                  L-ENTIDAD DELIMITED SPACE
                  '.HOST' DELIMITED SIZE
                  INTO WS-PARM-VALOR
           CALL 'PARMGT' USING WS-PARM-FUNCION
                               WS-PARM-VALOR
                               WS-SFTP-HOST
                               WS-PARM-TIPO
                               WS-PARM-RC
           IF WS-PARM-RC NOT = 0
              MOVE 10 TO L-RETURN-CODE
              STOP RUN
           END-IF
      *    Usuario SFTP
           STRING 'FTP.' DELIMITED SIZE
                  L-ENTIDAD DELIMITED SPACE
                  '.USER' DELIMITED SIZE
                  INTO WS-PARM-VALOR
           CALL 'PARMGT' USING WS-PARM-FUNCION
                               WS-PARM-VALOR
                               WS-SFTP-USUARIO
                               WS-PARM-TIPO
                               WS-PARM-RC
           IF WS-PARM-RC NOT = 0
              MOVE 11 TO L-RETURN-CODE
              STOP RUN
           END-IF
      *    Directorio remoto
           STRING 'FTP.' DELIMITED SIZE
                  L-ENTIDAD DELIMITED SPACE
                  '.DIR' DELIMITED SIZE
                  INTO WS-PARM-VALOR
           CALL 'PARMGT' USING WS-PARM-FUNCION
                               WS-PARM-VALOR
                               WS-SFTP-DIRECTORIO
                               WS-PARM-TIPO
                               WS-PARM-RC.
      *
       2000-REGISTRAR-INICIO-AUDITORIA.
           EXEC SQL
               SELECT MAX(AUD_ID) + 1
               INTO :HV-AUD-ID
               FROM FTP_AUDITORIA
           END-EXEC
           MOVE L-ENTIDAD        TO HV-AUD-ENTIDAD
           MOVE L-OPERACION      TO HV-AUD-OPERACION
           MOVE L-ARCHIVO-LOCAL  TO HV-AUD-ARCHIVO-LOC
           MOVE L-ARCHIVO-REMOTO TO HV-AUD-ARCHIVO-REM
           MOVE 'PE'             TO HV-AUD-ESTADO
           EXEC SQL
               INSERT INTO FTP_AUDITORIA
                   (AUD_ID, AUD_ENTIDAD, AUD_OPERACION,
                    AUD_ARCHIVO_LOCAL, AUD_ARCHIVO_REMOTO,
                    AUD_ESTADO, AUD_FECHA_INICIO)
               VALUES
                   (:HV-AUD-ID, :HV-AUD-ENTIDAD, :HV-AUD-OPERACION,
                    :HV-AUD-ARCHIVO-LOC, :HV-AUD-ARCHIVO-REM,
                    'PE', CURRENT TIMESTAMP)
           END-EXEC.
      *
       3000-ENVIAR-FICHERO.
      *    La transferencia real se delega al subsistema BPXWDYN/USS
      *    mediante CALL al programa ensamblador FTPEXEC que ejecuta
      *    sftp con las credenciales cargadas de PARMGT
           CALL 'FTPEXEC' USING WS-SFTP-HOST
                                WS-SFTP-USUARIO
                                WS-FTP-ARCHIVO-LOC
                                WS-SFTP-DIRECTORIO
                                WS-FTP-ARCHIVO-REM
                                L-BYTES-TRANSFERIDOS
                                WS-RETURN-CODE
           IF WS-RETURN-CODE NOT = 0
              MOVE 30 TO L-RETURN-CODE
           END-IF.
      *
       4000-RECIBIR-FICHERO.
           CALL 'FTPEXEC' USING WS-SFTP-HOST
                                WS-SFTP-USUARIO
                                WS-SFTP-DIRECTORIO
                                WS-FTP-ARCHIVO-REM
                                WS-FTP-ARCHIVO-LOC
                                L-BYTES-TRANSFERIDOS
                                WS-RETURN-CODE
           IF WS-RETURN-CODE NOT = 0
              MOVE 40 TO L-RETURN-CODE
           END-IF.
      *
       5000-LISTAR-DIRECTORIO.
           CALL 'FTPEXEC' USING WS-SFTP-HOST
                                WS-SFTP-USUARIO
                                WS-SFTP-DIRECTORIO
                                SPACES SPACES
                                L-BYTES-TRANSFERIDOS
                                WS-RETURN-CODE
           IF WS-RETURN-CODE NOT = 0
              MOVE 50 TO L-RETURN-CODE
           END-IF.
      *
       6000-CERRAR-AUDITORIA.
           EVALUATE TRUE
             WHEN L-RETURN-CODE = 0
               MOVE 'OK' TO HV-AUD-ESTADO
             WHEN OTHER
               MOVE 'ER' TO HV-AUD-ESTADO
           END-EVALUATE
           EXEC SQL
               UPDATE FTP_AUDITORIA
               SET AUD_ESTADO    = :HV-AUD-ESTADO,
                   AUD_BYTES     = :L-BYTES-TRANSFERIDOS,
                   AUD_FECHA_FIN = CURRENT TIMESTAMP
               WHERE AUD_ID = :HV-AUD-ID
           END-EXEC.
