       IDENTIFICATION DIVISION.
       PROGRAM-ID. LIQUID.
      *----------------------------------------------------------------*
      * LIQUID  - Liquidacion de comisiones a intermediarios           *
      * Llama a: COBRAN INTMED VALDAT                                  *
      *                                                                *
      * NOTA: Usa prima original para calculo de comision. Si la      *
      * poliza tiene un suplemento que modifico la prima, la comision  *
      * se calcula sobre la prima anterior, no la vigente. Discrepancia*
      * detectada en auditorias de 2024 pero no corregida aun.        *
      *----------------------------------------------------------------*
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-MAINFRAME.
      *
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY RECREC.
       01 WS-RETURN-CODE         PIC S9(4) COMP VALUE 0.
       01 WS-TOTAL-COMISIONES    PIC S9(11)V9(2) COMP-3 VALUE 0.
       01 WS-PERIODO-DESDE       PIC 9(8).
       01 WS-PERIODO-HASTA       PIC 9(8).
       01 WS-FUNCION-VALDAT      PIC X(1).
       01 WS-FECHA-AUX           PIC 9(8).
       01 WS-MESES-AUX           PIC S9(5) COMP VALUE 0.
       01 WS-COD-RETORNO-VALDAT  PIC S9(4) COMP VALUE 0.
       01 WS-NUEVA-LIQ-ID        PIC 9(10).
      *
       01 DCLGEN-LIQUID.
          05 HV-LIQ-AGENTE       PIC 9(6).
          05 HV-LIQ-COMISION     PIC S9(9)V9(2) COMP-3.
          05 HV-LIQ-ID           PIC 9(10).
          05 SQLCODE             PIC S9(9) COMP.
      *
       LINKAGE SECTION.
       01 L-AGENTE               PIC 9(6).
       01 L-FECHA-DESDE          PIC 9(8).
       01 L-FECHA-HASTA          PIC 9(8).
       01 L-TOTAL-LIQUIDADO      PIC S9(11)V9(2) COMP-3.
       01 L-RETURN-CODE          PIC S9(4) COMP.
      *
       PROCEDURE DIVISION USING L-AGENTE
                                 L-FECHA-DESDE
                                 L-FECHA-HASTA
                                 L-TOTAL-LIQUIDADO
                                 L-RETURN-CODE.
           MOVE 0 TO L-RETURN-CODE
           PERFORM 1000-VERIFICAR-AGENTE
           IF L-RETURN-CODE = 0
              PERFORM 2000-CALCULAR-COMISIONES
           END-IF
           IF L-RETURN-CODE = 0
              PERFORM 3000-REGISTRAR-LIQUIDACION
           END-IF
           STOP RUN.
      *
       1000-VERIFICAR-AGENTE.
           CALL 'INTMED' USING L-AGENTE
                               'TODOS'
                               WS-RETURN-CODE
           IF WS-RETURN-CODE NOT = 0
              MOVE 10 TO L-RETURN-CODE
           END-IF.
      *
       2000-CALCULAR-COMISIONES.
           EXEC SQL
               SELECT SUM(REC_COMISION_IMP)
               INTO :WS-TOTAL-COMISIONES
               FROM RECIBOS
               WHERE REC_AGENTE       = :L-AGENTE
                 AND REC_FECHA_COBRO >= :L-FECHA-DESDE
                 AND REC_FECHA_COBRO <= :L-FECHA-HASTA
                 AND REC_ESTADO       = 'CO'
                 AND REC_LIQUIDADO    = 'N'
           END-EXEC
           IF SQLCODE NOT = 0
              MOVE 20 TO L-RETURN-CODE
           ELSE
              MOVE WS-TOTAL-COMISIONES TO L-TOTAL-LIQUIDADO
           END-IF.
      *
       3000-REGISTRAR-LIQUIDACION.
           EXEC SQL
               SELECT MAX(LIQ_ID) + 1
               INTO :WS-NUEVA-LIQ-ID
               FROM LIQUIDACIONES
           END-EXEC
           EXEC SQL
               INSERT INTO LIQUIDACIONES
                   (LIQ_ID, LIQ_AGENTE, LIQ_PERIODO_DESDE,
                    LIQ_PERIODO_HASTA, LIQ_IMPORTE, LIQ_FECHA,
                    LIQ_ESTADO)
               VALUES
                   (:WS-NUEVA-LIQ-ID, :L-AGENTE, :L-FECHA-DESDE,
                    :L-FECHA-HASTA, :L-TOTAL-LIQUIDADO, CURRENT DATE,
                    'PE')
           END-EXEC
           IF SQLCODE NOT = 0
              MOVE 30 TO L-RETURN-CODE
           ELSE
               EXEC SQL
                   UPDATE RECIBOS
                   SET REC_LIQUIDADO = 'S',
                       REC_LIQ_ID    = :WS-NUEVA-LIQ-ID
                   WHERE REC_AGENTE       = :L-AGENTE
                     AND REC_FECHA_COBRO >= :L-FECHA-DESDE
                     AND REC_FECHA_COBRO <= :L-FECHA-HASTA
                     AND REC_ESTADO       = 'CO'
                     AND REC_LIQUIDADO    = 'N'
               END-EXEC
           END-IF.
