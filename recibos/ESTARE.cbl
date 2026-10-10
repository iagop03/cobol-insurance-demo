       IDENTIFICATION DIVISION.
       PROGRAM-ID. ESTARE.
      *----------------------------------------------------------------*
      * ESTARE  - Gestion de estado de recibos y poliza                *
      * Llama a: (ninguno — punto final)                               *
      *----------------------------------------------------------------*
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-MAINFRAME.
      *
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-RETURN-CODE         PIC S9(4) COMP VALUE 0.
       01 WS-RECIBOS-PENDIENTES  PIC 9(4) VALUE 0.
       01 WS-RECIBOS-DEVUELTOS   PIC 9(4) VALUE 0.
      *
       01 DCLGEN-RECIBOS-EST.
          05 HV-REC-POL-NUMERO   PIC 9(8).
          05 HV-REC-ESTADO       PIC X(2).
          05 SQLCODE             PIC S9(9) COMP.
      *
       01 DCLGEN-POLIZAS-EST.
          05 HV-POL-NUMERO       PIC 9(8).
          05 HV-POL-ESTADO       PIC X(2).
          05 HV-POL-MESES-VENC   PIC 9(3).
          05 SQLCODE-POL         PIC S9(9) COMP.
      *
       LINKAGE SECTION.
       01 L-POL-NUMERO           PIC 9(8).
       01 L-OPERACION            PIC X(6).
       01 L-RETURN-CODE          PIC S9(4) COMP.
      *
       PROCEDURE DIVISION USING L-POL-NUMERO
                                 L-OPERACION
                                 L-RETURN-CODE.
           MOVE 0 TO L-RETURN-CODE
           PERFORM 1000-CONTAR-RECIBOS
           EVALUATE L-OPERACION
             WHEN 'COBRAR'
               PERFORM 2000-PROCESAR-COBRO
             WHEN 'DEVOL'
               PERFORM 3000-PROCESAR-DEVOLUCION
             WHEN 'ANULAN'
               PERFORM 4000-PROCESAR-ANULACION
             WHEN OTHER
               MOVE 99 TO L-RETURN-CODE
           END-EVALUATE
           STOP RUN.
      *
       1000-CONTAR-RECIBOS.
           MOVE L-POL-NUMERO TO HV-REC-POL-NUMERO
           EXEC SQL
               SELECT COUNT(*)
               INTO :WS-RECIBOS-PENDIENTES
               FROM RECIBOS
               WHERE REC_POL_NUMERO = :HV-REC-POL-NUMERO
                 AND REC_ESTADO = 'PE'
           END-EXEC
           EXEC SQL
               SELECT COUNT(*)
               INTO :WS-RECIBOS-DEVUELTOS
               FROM RECIBOS
               WHERE REC_POL_NUMERO = :HV-REC-POL-NUMERO
                 AND REC_ESTADO = 'DE'
           END-EXEC.
      *
       2000-PROCESAR-COBRO.
           IF WS-RECIBOS-PENDIENTES = 0 AND WS-RECIBOS-DEVUELTOS = 0
              EXEC SQL
                  UPDATE POLIZAS
                  SET POL_ESTADO = 'AC',
                      POL_MESES_VENCIDA = 0
                  WHERE POL_NUMERO = :L-POL-NUMERO
                    AND POL_ESTADO IN ('VE', 'SU')
              END-EXEC
           END-IF.
      *
       3000-PROCESAR-DEVOLUCION.
           EXEC SQL
               SELECT POL_MESES_VENCIDA
               INTO :HV-POL-MESES-VENC
               FROM POLIZAS
               WHERE POL_NUMERO = :L-POL-NUMERO
           END-EXEC
           ADD 1 TO HV-POL-MESES-VENC
           EXEC SQL
               UPDATE POLIZAS
               SET POL_ESTADO = 'VE',
                   POL_MESES_VENCIDA = :HV-POL-MESES-VENC
               WHERE POL_NUMERO = :L-POL-NUMERO
           END-EXEC.
      *
       4000-PROCESAR-ANULACION.
           EXEC SQL
               UPDATE RECIBOS
               SET REC_ESTADO = 'AN'
               WHERE REC_POL_NUMERO = :L-POL-NUMERO
                 AND REC_ESTADO = 'PE'
           END-EXEC.
