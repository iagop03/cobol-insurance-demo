       IDENTIFICATION DIVISION.
       PROGRAM-ID. ANULAN.
      *----------------------------------------------------------------*
      * ANULAN  - Anulacion de polizas                                 *
      * Llama a: MOVPOL VALDAT ESTARE                                  *
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
       01 WS-DEVOLUCION          PIC S9(9)V9(2) COMP-3 VALUE 0.
       01 WS-MESES-CONSUMIDOS    PIC S9(5) COMP VALUE 0.
       01 WS-FUNCION-VALDAT      PIC X(1).
       01 WS-FECHA-AUX           PIC 9(8).
       01 WS-MESES-AUX           PIC S9(5) COMP VALUE 0.
       01 WS-COD-RETORNO-VALDAT  PIC S9(4) COMP VALUE 0.
      *
       01 DCLGEN-POLIZAS-ANU.
          05 HV-POL-NUMERO       PIC 9(8).
          05 HV-POL-ESTADO       PIC X(2).
          05 HV-POL-FECHA-EFECT  PIC 9(8).
          05 HV-POL-FECHA-VCTO   PIC 9(8).
          05 HV-POL-PRIMA-TOTAL  PIC S9(9)V9(2) COMP-3.
          05 SQLCODE             PIC S9(9) COMP.
      *
       LINKAGE SECTION.
       01 L-POL-NUMERO           PIC 9(8).
       01 L-MOTIVO-ANULACION     PIC X(4).
       01 L-FECHA-ANULACION      PIC 9(8).
       01 L-DEVOLUCION-PRIMA     PIC S9(9)V9(2) COMP-3.
       01 L-RETURN-CODE          PIC S9(4) COMP.
      *
       PROCEDURE DIVISION USING L-POL-NUMERO
                                 L-MOTIVO-ANULACION
                                 L-FECHA-ANULACION
                                 L-DEVOLUCION-PRIMA
                                 L-RETURN-CODE.
           MOVE 0 TO L-RETURN-CODE
           PERFORM 1000-OBTENER-POLIZA
           IF L-RETURN-CODE = 0
              PERFORM 2000-CALCULAR-DEVOLUCION
           END-IF
           IF L-RETURN-CODE = 0
              PERFORM 3000-ANULAR-RECIBOS-PENDIENTES
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
               SELECT POL_ESTADO, POL_FECHA_EFECT,
                      POL_FECHA_VCTO, POL_PRIMA_TOTAL
               INTO :HV-POL-ESTADO, :HV-POL-FECHA-EFECT,
                    :HV-POL-FECHA-VCTO, :HV-POL-PRIMA-TOTAL
               FROM POLIZAS
               WHERE POL_NUMERO = :HV-POL-NUMERO
                 AND POL_ESTADO IN ('AC', 'SU', 'VE')
           END-EXEC
           IF SQLCODE NOT = 0
              MOVE 10 TO L-RETURN-CODE
           END-IF.
      *
       2000-CALCULAR-DEVOLUCION.
           MOVE '2' TO WS-FUNCION-VALDAT
           CALL 'VALDAT' USING WS-FUNCION-VALDAT
                               HV-POL-FECHA-EFECT
                               L-FECHA-ANULACION
                               WS-MESES-CONSUMIDOS
                               WS-FECHA-AUX
                               WS-MESES-AUX
                               WS-COD-RETORNO-VALDAT
           COMPUTE WS-MESES-AUX = 12 - WS-MESES-CONSUMIDOS
           IF WS-MESES-AUX > 0
              COMPUTE L-DEVOLUCION-PRIMA ROUNDED =
                  HV-POL-PRIMA-TOTAL / 12 * WS-MESES-AUX
           ELSE
              MOVE 0 TO L-DEVOLUCION-PRIMA
           END-IF.
      *
       3000-ANULAR-RECIBOS-PENDIENTES.
           CALL 'ESTARE' USING L-POL-NUMERO
                               'ANULAN'
                               WS-RETURN-CODE.
      *
       4000-ACTUALIZAR-POLIZA.
           EXEC SQL
               UPDATE POLIZAS
               SET POL_ESTADO = 'AN',
                   POL_FECHA_ANULACION = :L-FECHA-ANULACION,
                   POL_MOTIVO_ANULACION = :L-MOTIVO-ANULACION
               WHERE POL_NUMERO = :HV-POL-NUMERO
           END-EXEC
           IF SQLCODE NOT = 0
              MOVE 40 TO L-RETURN-CODE
           END-IF.
      *
       5000-REGISTRAR-MOVIMIENTO.
           CALL 'MOVPOL' USING L-POL-NUMERO
                               L-DEVOLUCION-PRIMA
                               WS-RETURN-CODE.
