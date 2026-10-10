       IDENTIFICATION DIVISION.
       PROGRAM-ID. COBRAN.
      *----------------------------------------------------------------*
      * COBRAN  - Proceso de cobranza de recibos                       *
      * Llama a: ESTARE VALDAT                                         *
      *----------------------------------------------------------------*
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-MAINFRAME.
      *
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY RECREC.
       01 WS-RETURN-CODE         PIC S9(4) COMP VALUE 0.
       01 WS-FUNCION-VALDAT      PIC X(1).
       01 WS-FECHA-AUX           PIC 9(8).
       01 WS-MESES-AUX           PIC S9(5) COMP VALUE 0.
       01 WS-COD-RETORNO-VALDAT  PIC S9(4) COMP VALUE 0.
      *
       01 DCLGEN-RECIBOS-COB.
          05 HV-REC-ID           PIC 9(10).
          05 HV-REC-POL-NUMERO   PIC 9(8).
          05 HV-REC-IMPORTE-TOT  PIC S9(9)V9(2) COMP-3.
          05 HV-REC-ESTADO       PIC X(2).
          05 HV-REC-FECHA-VENC   PIC 9(8).
          05 SQLCODE             PIC S9(9) COMP.
      *
       LINKAGE SECTION.
       01 L-REC-ID               PIC 9(10).
       01 L-FECHA-COBRO          PIC 9(8).
       01 L-IMPORTE-COBRADO      PIC S9(9)V9(2) COMP-3.
       01 L-BANCO                PIC X(20).
       01 L-CUENTA               PIC X(24).
       01 L-RETURN-CODE          PIC S9(4) COMP.
      *
       PROCEDURE DIVISION USING L-REC-ID
                                 L-FECHA-COBRO
                                 L-IMPORTE-COBRADO
                                 L-BANCO
                                 L-CUENTA
                                 L-RETURN-CODE.
           MOVE 0 TO L-RETURN-CODE
           PERFORM 1000-VERIFICAR-RECIBO
           IF L-RETURN-CODE = 0
              PERFORM 2000-VALIDAR-IMPORTE
           END-IF
           IF L-RETURN-CODE = 0
              PERFORM 3000-REGISTRAR-COBRO
           END-IF
           IF L-RETURN-CODE = 0
              PERFORM 4000-ACTUALIZAR-ESTADO-POLIZA
           END-IF
           STOP RUN.
      *
       1000-VERIFICAR-RECIBO.
           EXEC SQL
               SELECT REC_POL_NUMERO, REC_IMPORTE_TOTAL,
                      REC_ESTADO, REC_FECHA_VENC
               INTO :HV-REC-POL-NUMERO, :HV-REC-IMPORTE-TOT,
                    :HV-REC-ESTADO, :HV-REC-FECHA-VENC
               FROM RECIBOS
               WHERE REC_ID = :L-REC-ID
                 AND REC_ESTADO = 'PE'
           END-EXEC
           IF SQLCODE NOT = 0
              MOVE 10 TO L-RETURN-CODE
           END-IF.
      *
       2000-VALIDAR-IMPORTE.
           IF L-IMPORTE-COBRADO < HV-REC-IMPORTE-TOT
              MOVE 20 TO L-RETURN-CODE
           END-IF.
      *
       3000-REGISTRAR-COBRO.
           EXEC SQL
               UPDATE RECIBOS
               SET REC_ESTADO     = 'CO',
                   REC_FECHA_COBRO = :L-FECHA-COBRO,
                   REC_BANCO      = :L-BANCO,
                   REC_CUENTA     = :L-CUENTA
               WHERE REC_ID = :L-REC-ID
           END-EXEC
           IF SQLCODE NOT = 0
              MOVE 30 TO L-RETURN-CODE
           END-IF.
      *
       4000-ACTUALIZAR-ESTADO-POLIZA.
           CALL 'ESTARE' USING HV-REC-POL-NUMERO
                               'COBRAR'
                               WS-RETURN-CODE.
