       IDENTIFICATION DIVISION.
       PROGRAM-ID. SUPLMT.
      *----------------------------------------------------------------*
      * SUPLMT  - Suplementos (modificaciones sobre polizas vigentes)  *
      * Llama a: VALDAT TARIFA MOVPOL ERRMSG                           *
      *----------------------------------------------------------------*
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-MAINFRAME.
      *
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY POLREC.
       COPY MOVREC.
       01 WS-RETURN-CODE         PIC S9(4) COMP VALUE 0.
       01 WS-PRIMA-ANTERIOR      PIC S9(9)V9(2) COMP-3 VALUE 0.
       01 WS-PRIMA-NUEVA         PIC S9(9)V9(2) COMP-3 VALUE 0.
       01 WS-DIFERENCIA-PRIMA    PIC S9(9)V9(2) COMP-3 VALUE 0.
       01 WS-FUNCION-VALDAT      PIC X(1).
       01 WS-FECHA-AUX           PIC 9(8).
       01 WS-MESES-AUX           PIC S9(5) COMP VALUE 0.
       01 WS-COD-RETORNO-VALDAT  PIC S9(4) COMP VALUE 0.
      *
       01 DCLGEN-POLIZAS-SUP.
          05 HV-POL-NUMERO       PIC 9(8).
          05 HV-POL-ESTADO       PIC X(2).
          05 HV-POL-PRODUCTO     PIC X(6).
          05 HV-POL-TOMADOR      PIC 9(10).
          05 HV-POL-PRIMA-TOTAL  PIC S9(9)V9(2) COMP-3.
          05 HV-POL-FECHA-VCTO   PIC 9(8).
          05 SQLCODE             PIC S9(9) COMP.
      *
       LINKAGE SECTION.
       01 L-POL-NUMERO           PIC 9(8).
       01 L-TIPO-SUPLEMENTO      PIC X(4).
       01 L-FECHA-EFECTO         PIC 9(8).
       01 L-DATOS-MODIFICACION   PIC X(200).
       01 L-PRIMA-RESULTANTE     PIC S9(9)V9(2) COMP-3.
       01 L-RETURN-CODE          PIC S9(4) COMP.
      *
       PROCEDURE DIVISION USING L-POL-NUMERO
                                 L-TIPO-SUPLEMENTO
                                 L-FECHA-EFECTO
                                 L-DATOS-MODIFICACION
                                 L-PRIMA-RESULTANTE
                                 L-RETURN-CODE.
           MOVE 0 TO L-RETURN-CODE
           PERFORM 1000-OBTENER-POLIZA
           IF L-RETURN-CODE = 0
              PERFORM 2000-VALIDAR-FECHA-EFECTO
           END-IF
           IF L-RETURN-CODE = 0
              PERFORM 3000-RECALCULAR-PRIMA
           END-IF
           IF L-RETURN-CODE = 0
              PERFORM 4000-ACTUALIZAR-POLIZA
           END-IF
           IF L-RETURN-CODE = 0
              PERFORM 5000-REGISTRAR-MOVIMIENTO
           END-IF
           STOP RUN.
      *
       1000-OBTENER-POLIZA.
           MOVE L-POL-NUMERO TO HV-POL-NUMERO
           EXEC SQL
               SELECT POL_ESTADO, POL_PRODUCTO, POL_TOMADOR,
                      POL_PRIMA_TOTAL, POL_FECHA_VCTO
               INTO :HV-POL-ESTADO, :HV-POL-PRODUCTO, :HV-POL-TOMADOR,
                    :HV-POL-PRIMA-TOTAL, :HV-POL-FECHA-VCTO
               FROM POLIZAS
               WHERE POL_NUMERO = :HV-POL-NUMERO
                 AND POL_ESTADO IN ('AC', 'SU')
           END-EXEC
           IF SQLCODE NOT = 0
              MOVE 10 TO L-RETURN-CODE
           ELSE
              MOVE HV-POL-PRIMA-TOTAL TO WS-PRIMA-ANTERIOR
           END-IF.
      *
       2000-VALIDAR-FECHA-EFECTO.
           MOVE '4' TO WS-FUNCION-VALDAT
           CALL 'VALDAT' USING WS-FUNCION-VALDAT
                               L-FECHA-EFECTO
                               HV-POL-FECHA-VCTO
                               WS-MESES-AUX
                               WS-FECHA-AUX
                               WS-MESES-AUX
                               WS-COD-RETORNO-VALDAT
           IF WS-COD-RETORNO-VALDAT NOT = 0
              MOVE 20 TO L-RETURN-CODE
           END-IF.
      *
       3000-RECALCULAR-PRIMA.
           CALL 'TARIFA' USING HV-POL-PRODUCTO
                               HV-POL-TOMADOR
                               L-FECHA-EFECTO
                               POL-MODALIDAD
                               WS-PRIMA-NUEVA
                               WS-COD-RETORNO-VALDAT
           IF WS-COD-RETORNO-VALDAT NOT = 0
              MOVE 30 TO L-RETURN-CODE
           ELSE
              COMPUTE WS-DIFERENCIA-PRIMA =
                  WS-PRIMA-NUEVA - WS-PRIMA-ANTERIOR
              MOVE WS-PRIMA-NUEVA TO L-PRIMA-RESULTANTE
           END-IF.
      *
       4000-ACTUALIZAR-POLIZA.
           EXEC SQL
               UPDATE POLIZAS
               SET POL_PRIMA_TOTAL = :WS-PRIMA-NUEVA,
                   POL_FECHA_SUPL  = :L-FECHA-EFECTO,
                   POL_TIPO_SUPL   = :L-TIPO-SUPLEMENTO
               WHERE POL_NUMERO = :HV-POL-NUMERO
           END-EXEC
           IF SQLCODE NOT = 0
              MOVE 40 TO L-RETURN-CODE
           END-IF.
      *
       5000-REGISTRAR-MOVIMIENTO.
           CALL 'MOVPOL' USING L-POL-NUMERO
                               WS-DIFERENCIA-PRIMA
                               WS-RETURN-CODE.
