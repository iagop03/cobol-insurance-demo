       IDENTIFICATION DIVISION.
       PROGRAM-ID. DEVOLU.
      *----------------------------------------------------------------*
      * DEVOLU  - Gestion de devoluciones e impagados                  *
      * Llama a: ESTARE COBRAN VALDAT                                  *
      *----------------------------------------------------------------*
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-MAINFRAME.
      *
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY RECREC.
       01 WS-RETURN-CODE         PIC S9(4) COMP VALUE 0.
       01 WS-DIAS-MORA           PIC 9(4) VALUE 0.
       01 WS-RECARGO-DEVOL       PIC S9(9)V9(2) COMP-3 VALUE 0.
       01 WS-FUNCION-VALDAT      PIC X(1).
       01 WS-FECHA-AUX           PIC 9(8).
       01 WS-MESES-AUX           PIC S9(5) COMP VALUE 0.
       01 WS-COD-RETORNO-VALDAT  PIC S9(4) COMP VALUE 0.
      *
       01 DCLGEN-RECIBOS-DEV.
          05 HV-REC-ID           PIC 9(10).
          05 HV-REC-POL-NUMERO   PIC 9(8).
          05 HV-REC-IMPORTE-TOT  PIC S9(9)V9(2) COMP-3.
          05 HV-REC-ESTADO       PIC X(2).
          05 SQLCODE             PIC S9(9) COMP.
      *
       LINKAGE SECTION.
       01 L-REC-ID               PIC 9(10).
       01 L-MOTIVO-DEVOL         PIC X(4).
       01 L-FECHA-DEVOL          PIC 9(8).
       01 L-RETURN-CODE          PIC S9(4) COMP.
      *
       PROCEDURE DIVISION USING L-REC-ID
                                 L-MOTIVO-DEVOL
                                 L-FECHA-DEVOL
                                 L-RETURN-CODE.
           MOVE 0 TO L-RETURN-CODE
           PERFORM 1000-VERIFICAR-RECIBO-COBRADO
           IF L-RETURN-CODE = 0
              PERFORM 2000-REGISTRAR-DEVOLUCION
           END-IF
           IF L-RETURN-CODE = 0
              PERFORM 3000-ACTUALIZAR-ESTADO-POLIZA
           END-IF
           IF L-RETURN-CODE = 0
              PERFORM 4000-GENERAR-RECIBO-REEMPLAZO
           END-IF
           STOP RUN.
      *
       1000-VERIFICAR-RECIBO-COBRADO.
           EXEC SQL
               SELECT REC_POL_NUMERO, REC_IMPORTE_TOTAL, REC_ESTADO
               INTO :HV-REC-POL-NUMERO, :HV-REC-IMPORTE-TOT,
                    :HV-REC-ESTADO
               FROM RECIBOS
               WHERE REC_ID = :L-REC-ID
                 AND REC_ESTADO = 'CO'
           END-EXEC
           IF SQLCODE NOT = 0
              MOVE 10 TO L-RETURN-CODE
           END-IF.
      *
       2000-REGISTRAR-DEVOLUCION.
           EXEC SQL
               UPDATE RECIBOS
               SET REC_ESTADO        = 'DE',
                   REC_FECHA_DEVOL   = :L-FECHA-DEVOL,
                   REC_MOTIVO_DEVOL  = :L-MOTIVO-DEVOL
               WHERE REC_ID = :L-REC-ID
           END-EXEC
           IF SQLCODE NOT = 0
              MOVE 20 TO L-RETURN-CODE
           END-IF.
      *
       3000-ACTUALIZAR-ESTADO-POLIZA.
           CALL 'ESTARE' USING HV-REC-POL-NUMERO
                               'DEVOL'
                               WS-RETURN-CODE.
      *
       4000-GENERAR-RECIBO-REEMPLAZO.
           COMPUTE WS-RECARGO-DEVOL ROUNDED =
               HV-REC-IMPORTE-TOT * 0.03
           CALL 'COBRAN' USING HV-REC-POL-NUMERO
                               L-FECHA-DEVOL
                               WS-RECARGO-DEVOL
                               SPACES
                               SPACES
                               WS-RETURN-CODE.
