       IDENTIFICATION DIVISION.
       PROGRAM-ID. GENREC.
      *----------------------------------------------------------------*
      * GENREC  - Generacion de recibos de prima                       *
      * Llama a: VALDAT PERSOM                                         *
      *----------------------------------------------------------------*
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-MAINFRAME.
      *
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY POLREC.
       COPY RECREC.
       01 WS-RETURN-CODE         PIC S9(4) COMP VALUE 0.
       01 WS-NUEVO-REC-ID        PIC 9(10) VALUE 0.
       01 WS-FUNCION-VALDAT      PIC X(1).
       01 WS-FECHA-AUX           PIC 9(8).
       01 WS-MESES-AUX           PIC S9(5) COMP VALUE 1.
       01 WS-COD-RETORNO-VALDAT  PIC S9(4) COMP VALUE 0.
       01 WS-RECARGO-MORA        PIC S9(9)V9(2) COMP-3 VALUE 0.
      *
       01 DCLGEN-POLIZAS-GEN.
          05 HV-POL-NUMERO       PIC 9(8).
          05 HV-POL-AGENTE       PIC 9(6).
          05 HV-POL-MODALIDAD    PIC X(3).
          05 HV-POL-PRIMA-TOTAL  PIC S9(9)V9(2) COMP-3.
          05 HV-POL-ESTADO       PIC X(2).
          05 SQLCODE             PIC S9(9) COMP.
      *
       01 DCLGEN-INTMED-COM.
          05 HV-INT-COMISION-PCT PIC S9(3)V9(4) COMP-3.
          05 SQLCODE-INT         PIC S9(9) COMP.
      *
       LINKAGE SECTION.
       01 L-POL-NUMERO           PIC 9(8).
       01 L-PRIMA                PIC S9(9)V9(2) COMP-3.
       01 L-FECHA-EMISION        PIC 9(8).
       01 L-RETURN-CODE          PIC S9(4) COMP.
      *
       PROCEDURE DIVISION USING L-POL-NUMERO
                                 L-PRIMA
                                 L-FECHA-EMISION
                                 L-RETURN-CODE.
           MOVE 0 TO L-RETURN-CODE
           PERFORM 1000-OBTENER-DATOS-POLIZA
           IF L-RETURN-CODE = 0
              PERFORM 2000-CALCULAR-FECHA-VENCIMIENTO
           END-IF
           IF L-RETURN-CODE = 0
              PERFORM 3000-OBTENER-COMISION
           END-IF
           IF L-RETURN-CODE = 0
              PERFORM 4000-INSERTAR-RECIBO
           END-IF
           STOP RUN.
      *
       1000-OBTENER-DATOS-POLIZA.
           MOVE L-POL-NUMERO TO HV-POL-NUMERO
           EXEC SQL
               SELECT POL_AGENTE, POL_MODALIDAD,
                      POL_PRIMA_TOTAL, POL_ESTADO
               INTO :HV-POL-AGENTE, :HV-POL-MODALIDAD,
                    :HV-POL-PRIMA-TOTAL, :HV-POL-ESTADO
               FROM POLIZAS
               WHERE POL_NUMERO = :HV-POL-NUMERO
           END-EXEC
           IF SQLCODE NOT = 0
              MOVE 10 TO L-RETURN-CODE
           END-IF.
      *
       2000-CALCULAR-FECHA-VENCIMIENTO.
           MOVE '3' TO WS-FUNCION-VALDAT
           EVALUATE HV-POL-MODALIDAD
             WHEN 'MEN' MOVE 1  TO WS-MESES-AUX
             WHEN 'SEM' MOVE 6  TO WS-MESES-AUX
             WHEN OTHER MOVE 12 TO WS-MESES-AUX
           END-EVALUATE
           CALL 'VALDAT' USING WS-FUNCION-VALDAT
                               L-FECHA-EMISION
                               WS-FECHA-AUX
                               WS-MESES-AUX
                               REC-FECHA-VENC
                               WS-MESES-AUX
                               WS-COD-RETORNO-VALDAT.
      *
       3000-OBTENER-COMISION.
           EXEC SQL
               SELECT INT_COMISION_PCT
               INTO :HV-INT-COMISION-PCT
               FROM INTERMEDIARIOS
               WHERE INT_CODIGO = :HV-POL-AGENTE
                 AND INT_ESTADO = 'A'
           END-EXEC
           IF SQLCODE NOT = 0
              MOVE 0 TO HV-INT-COMISION-PCT
           END-IF.
      *
       4000-INSERTAR-RECIBO.
           EXEC SQL
               SELECT MAX(REC_ID) + 1
               INTO :WS-NUEVO-REC-ID
               FROM RECIBOS
           END-EXEC
           COMPUTE REC-COMISION-IMP ROUNDED =
               L-PRIMA * HV-INT-COMISION-PCT
           MOVE L-POL-NUMERO       TO REC-POL-NUMERO
           MOVE L-PRIMA            TO REC-IMPORTE-NETO
           MOVE WS-RECARGO-MORA    TO REC-IMPORTE-RECARGO
           COMPUTE REC-IMPORTE-TOTAL = L-PRIMA + WS-RECARGO-MORA
           MOVE 'PE'               TO REC-ESTADO
           EXEC SQL
               INSERT INTO RECIBOS
                   (REC_ID, REC_POL_NUMERO, REC_FECHA_EMISION,
                    REC_FECHA_VENC, REC_IMPORTE_NETO,
                    REC_IMPORTE_RECARGO, REC_IMPORTE_TOTAL,
                    REC_AGENTE, REC_COMISION_PCT, REC_COMISION_IMP,
                    REC_ESTADO)
               VALUES
                   (:WS-NUEVO-REC-ID, :REC-POL-NUMERO,
                    :L-FECHA-EMISION, :REC-FECHA-VENC,
                    :REC-IMPORTE-NETO, :REC-IMPORTE-RECARGO,
                    :REC-IMPORTE-TOTAL, :HV-POL-AGENTE,
                    :HV-INT-COMISION-PCT, :REC-COMISION-IMP,
                    :REC-ESTADO)
           END-EXEC
           IF SQLCODE NOT = 0
              MOVE 40 TO L-RETURN-CODE
           END-IF.
