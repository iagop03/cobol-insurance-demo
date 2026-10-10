       IDENTIFICATION DIVISION.
       PROGRAM-ID. RENOVA.
      *----------------------------------------------------------------*
      * RENOVA  - Proceso de renovacion de polizas                     *
      * Llama a: TARIFA VALDAT GENREC MOVPOL                           *
      *----------------------------------------------------------------*
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-MAINFRAME.
      *
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY POLREC.
       01 WS-RETURN-CODE         PIC S9(4) COMP VALUE 0.
       01 WS-PRIMA-NUEVA         PIC S9(9)V9(2) COMP-3 VALUE 0.
       01 WS-NUEVA-FECHA-EFECT   PIC 9(8).
       01 WS-NUEVA-FECHA-VCTO    PIC 9(8).
       01 WS-FUNCION-VALDAT      PIC X(1).
       01 WS-MESES-PLAZO         PIC S9(5) COMP VALUE 12.
       01 WS-MESES-AUX           PIC S9(5) COMP VALUE 0.
       01 WS-FECHA-AUX           PIC 9(8).
       01 WS-COD-RETORNO-VALDAT  PIC S9(4) COMP VALUE 0.
      *
       01 DCLGEN-POLIZAS-REN.
          05 HV-POL-NUMERO       PIC 9(8).
          05 HV-POL-ESTADO       PIC X(2).
          05 HV-POL-PRODUCTO     PIC X(6).
          05 HV-POL-TOMADOR      PIC 9(10).
          05 HV-POL-AGENTE       PIC 9(6).
          05 HV-POL-MODALIDAD    PIC X(3).
          05 HV-POL-FECHA-VCTO   PIC 9(8).
          05 HV-POL-RENO-AUTO    PIC X(1).
          05 SQLCODE             PIC S9(9) COMP.
      *
       LINKAGE SECTION.
       01 L-POL-NUMERO           PIC 9(8).
       01 L-MODALIDAD-NUEVA      PIC X(3).
       01 L-RETURN-CODE          PIC S9(4) COMP.
      *
       PROCEDURE DIVISION USING L-POL-NUMERO
                                 L-MODALIDAD-NUEVA
                                 L-RETURN-CODE.
           MOVE 0 TO L-RETURN-CODE
           PERFORM 1000-OBTENER-POLIZA
           IF L-RETURN-CODE = 0
              PERFORM 2000-CALCULAR-NUEVAS-FECHAS
           END-IF
           IF L-RETURN-CODE = 0
              PERFORM 3000-RECALCULAR-PRIMA
           END-IF
           IF L-RETURN-CODE = 0
              PERFORM 4000-ACTUALIZAR-POLIZA
           END-IF
           IF L-RETURN-CODE = 0
              PERFORM 5000-GENERAR-RECIBO-RENOVACION
           END-IF
           IF L-RETURN-CODE = 0
              PERFORM 6000-REGISTRAR-MOVIMIENTO
           END-IF
           STOP RUN.
      *
       1000-OBTENER-POLIZA.
           MOVE L-POL-NUMERO TO HV-POL-NUMERO
           EXEC SQL
               SELECT POL_ESTADO, POL_PRODUCTO, POL_TOMADOR,
                      POL_AGENTE, POL_MODALIDAD, POL_FECHA_VCTO,
                      POL_RENO_AUTO
               INTO :HV-POL-ESTADO, :HV-POL-PRODUCTO, :HV-POL-TOMADOR,
                    :HV-POL-AGENTE, :HV-POL-MODALIDAD, :HV-POL-FECHA-VCTO,
                    :HV-POL-RENO-AUTO
               FROM POLIZAS
               WHERE POL_NUMERO = :HV-POL-NUMERO
                 AND POL_ESTADO IN ('AC', 'VE')
           END-EXEC
           IF SQLCODE NOT = 0
              MOVE 10 TO L-RETURN-CODE
           END-IF.
      *
       2000-CALCULAR-NUEVAS-FECHAS.
           MOVE HV-POL-FECHA-VCTO TO WS-NUEVA-FECHA-EFECT
           MOVE '3' TO WS-FUNCION-VALDAT
           EVALUATE HV-POL-MODALIDAD
             WHEN 'MEN' MOVE 1  TO WS-MESES-PLAZO
             WHEN 'SEM' MOVE 6  TO WS-MESES-PLAZO
             WHEN OTHER MOVE 12 TO WS-MESES-PLAZO
           END-EVALUATE
           CALL 'VALDAT' USING WS-FUNCION-VALDAT
                               WS-NUEVA-FECHA-EFECT
                               WS-FECHA-AUX
                               WS-MESES-AUX
                               WS-NUEVA-FECHA-VCTO
                               WS-MESES-PLAZO
                               WS-COD-RETORNO-VALDAT.
      *
       3000-RECALCULAR-PRIMA.
           CALL 'TARIFA' USING HV-POL-PRODUCTO
                               HV-POL-TOMADOR
                               WS-NUEVA-FECHA-EFECT
                               HV-POL-MODALIDAD
                               WS-PRIMA-NUEVA
                               WS-COD-RETORNO-VALDAT
           IF WS-COD-RETORNO-VALDAT NOT = 0
              MOVE 30 TO L-RETURN-CODE
           END-IF.
      *
       4000-ACTUALIZAR-POLIZA.
           EXEC SQL
               UPDATE POLIZAS
               SET POL_ESTADO      = 'AC',
                   POL_FECHA_EFECT = :WS-NUEVA-FECHA-EFECT,
                   POL_FECHA_VCTO  = :WS-NUEVA-FECHA-VCTO,
                   POL_PRIMA_TOTAL = :WS-PRIMA-NUEVA,
                   POL_MESES_VENCIDA = 0
               WHERE POL_NUMERO = :HV-POL-NUMERO
           END-EXEC
           IF SQLCODE NOT = 0
              MOVE 40 TO L-RETURN-CODE
           END-IF.
      *
       5000-GENERAR-RECIBO-RENOVACION.
           CALL 'GENREC' USING L-POL-NUMERO
                               WS-PRIMA-NUEVA
                               WS-NUEVA-FECHA-EFECT
                               WS-RETURN-CODE.
      *
       6000-REGISTRAR-MOVIMIENTO.
           CALL 'MOVPOL' USING L-POL-NUMERO
                               WS-PRIMA-NUEVA
                               WS-RETURN-CODE.
