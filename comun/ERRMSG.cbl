       IDENTIFICATION DIVISION.
       PROGRAM-ID. ERRMSG.
      *----------------------------------------------------------------*
      * ERRMSG  - Gestion centralizada de mensajes de error             *
      * Llamado por: EMIPOL SUPLMT GENREC SINREG COBRAN PAGSIN          *
      *----------------------------------------------------------------*
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-MAINFRAME.
      *
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-MSG-BUFFER          PIC X(200).
       01 WS-RETURN-CODE         PIC S9(4) COMP VALUE 0.
      *
       01 DCLGEN-MENSAJES.
          05 HV-MSG-CODIGO       PIC X(8).
          05 HV-MSG-TEXTO        PIC X(200).
          05 HV-MSG-SEVERIDAD    PIC X(1).
          05 SQLCODE             PIC S9(9) COMP.
      *
       LINKAGE SECTION.
       01 L-CODIGO-ERROR         PIC X(8).
       01 L-PROGRAMA-ORIGEN      PIC X(8).
       01 L-DATOS-ADICIONALES    PIC X(100).
       01 L-TEXTO-MENSAJE        PIC X(200).
       01 L-SEVERIDAD            PIC X(1).
       01 L-RETURN-CODE          PIC S9(4) COMP.
      *
       PROCEDURE DIVISION USING L-CODIGO-ERROR
                                 L-PROGRAMA-ORIGEN
                                 L-DATOS-ADICIONALES
                                 L-TEXTO-MENSAJE
                                 L-SEVERIDAD
                                 L-RETURN-CODE.
           MOVE 0 TO L-RETURN-CODE
           PERFORM 1000-BUSCAR-MENSAJE
           PERFORM 2000-FORMATEAR-MENSAJE
           PERFORM 9000-REGISTRAR-LOG
           STOP RUN.
      *
       1000-BUSCAR-MENSAJE.
           MOVE L-CODIGO-ERROR TO HV-MSG-CODIGO
           EXEC SQL
               SELECT MSG_TEXTO, MSG_SEVERIDAD
               INTO :HV-MSG-TEXTO, :HV-MSG-SEVERIDAD
               FROM MENSAJES_ERROR
               WHERE MSG_CODIGO = :HV-MSG-CODIGO
           END-EXEC
           IF SQLCODE NOT = 0
              MOVE 'Mensaje no encontrado: ' TO L-TEXTO-MENSAJE
              STRING L-TEXTO-MENSAJE L-CODIGO-ERROR
                  DELIMITED SIZE INTO WS-MSG-BUFFER
              MOVE WS-MSG-BUFFER TO L-TEXTO-MENSAJE
              MOVE 'W' TO L-SEVERIDAD
           ELSE
              MOVE HV-MSG-TEXTO TO L-TEXTO-MENSAJE
              MOVE HV-MSG-SEVERIDAD TO L-SEVERIDAD
           END-IF.
      *
       2000-FORMATEAR-MENSAJE.
           IF L-DATOS-ADICIONALES NOT = SPACES
              STRING L-TEXTO-MENSAJE ' [' L-DATOS-ADICIONALES ']'
                  DELIMITED SIZE INTO WS-MSG-BUFFER
              MOVE WS-MSG-BUFFER TO L-TEXTO-MENSAJE
           END-IF.
      *
       9000-REGISTRAR-LOG.
           EXEC SQL
               INSERT INTO LOG_ERRORES
                   (LOG_FECHA, LOG_PROGRAMA, LOG_CODIGO, LOG_TEXTO)
               VALUES
                   (CURRENT TIMESTAMP, :L-PROGRAMA-ORIGEN,
                    :L-CODIGO-ERROR, :L-TEXTO-MENSAJE)
           END-EXEC.
