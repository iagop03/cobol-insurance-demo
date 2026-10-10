       IDENTIFICATION DIVISION.
       PROGRAM-ID. PAGSIN.
      *----------------------------------------------------------------*
      * PAGSIN  - Pagos de siniestros a beneficiarios                  *
      * Llama a: SINREG VALDAT PERSOM                                  *
      *----------------------------------------------------------------*
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-MAINFRAME.
      *
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY SINREC.
       01 WS-RETURN-CODE         PIC S9(4) COMP VALUE 0.
       01 WS-FUNCION-VALDAT      PIC X(1).
       01 WS-FECHA-AUX           PIC 9(8).
       01 WS-MESES-AUX           PIC S9(5) COMP VALUE 0.
       01 WS-COD-RETORNO-VALDAT  PIC S9(4) COMP VALUE 0.
       01 WS-NUEVO-PAG-ID        PIC 9(10).
      *
       01 DCLGEN-SINIESTROS-PAG.
          05 HV-SIN-ID           PIC 9(10).
          05 HV-SIN-ESTADO       PIC X(2).
          05 HV-SIN-IMPORTE-DECL PIC S9(9)V9(2) COMP-3.
          05 HV-SIN-IMPORTE-PAG  PIC S9(9)V9(2) COMP-3.
          05 HV-SIN-IMPORTE-RES  PIC S9(9)V9(2) COMP-3.
          05 HV-SIN-POL-NUMERO   PIC 9(8).
          05 HV-SIN-BENEFICIARIO PIC 9(10).
          05 SQLCODE             PIC S9(9) COMP.
      *
       01 DCLGEN-PAGOS.
          05 HV-PAG-ID           PIC 9(10).
          05 SQLCODE-PAG         PIC S9(9) COMP.
      *
       LINKAGE SECTION.
       01 L-SIN-ID               PIC 9(10).
       01 L-IMPORTE-PAGO         PIC S9(9)V9(2) COMP-3.
       01 L-FECHA-PAGO           PIC 9(8).
       01 L-BENEFICIARIO         PIC 9(10).
       01 L-CONCEPTO             PIC X(50).
       01 L-RETURN-CODE          PIC S9(4) COMP.
      *
       PROCEDURE DIVISION USING L-SIN-ID
                                 L-IMPORTE-PAGO
                                 L-FECHA-PAGO
                                 L-BENEFICIARIO
                                 L-CONCEPTO
                                 L-RETURN-CODE.
           MOVE 0 TO L-RETURN-CODE
           PERFORM 1000-VERIFICAR-SINIESTRO
           IF L-RETURN-CODE = 0
              PERFORM 2000-VERIFICAR-BENEFICIARIO
           END-IF
           IF L-RETURN-CODE = 0
              PERFORM 3000-VERIFICAR-IMPORTE
           END-IF
           IF L-RETURN-CODE = 0
              PERFORM 4000-REGISTRAR-PAGO
           END-IF
           IF L-RETURN-CODE = 0
              PERFORM 5000-ACTUALIZAR-SINIESTRO
           END-IF
           STOP RUN.
      *
       1000-VERIFICAR-SINIESTRO.
           EXEC SQL
               SELECT SIN_ESTADO, SIN_IMPORTE_DECL,
                      SIN_IMPORTE_PAGADO, SIN_IMPORTE_RESERVA,
                      SIN_POL_NUMERO, SIN_BENEFICIARIO
               INTO :HV-SIN-ESTADO, :HV-SIN-IMPORTE-DECL,
                    :HV-SIN-IMPORTE-PAG, :HV-SIN-IMPORTE-RES,
                    :HV-SIN-POL-NUMERO, :HV-SIN-BENEFICIARIO
               FROM SINIESTROS
               WHERE SIN_ID = :L-SIN-ID
                 AND SIN_ESTADO IN ('AB', 'TR')
           END-EXEC
           IF SQLCODE NOT = 0
              MOVE 10 TO L-RETURN-CODE
           END-IF.
      *
       2000-VERIFICAR-BENEFICIARIO.
           CALL 'PERSOM' USING 'C' SPACES SPACES SPACES SPACES SPACES
                               ZEROES L-BENEFICIARIO WS-RETURN-CODE
           IF WS-RETURN-CODE NOT = 0
              MOVE 20 TO L-RETURN-CODE
           END-IF.
      *
       3000-VERIFICAR-IMPORTE.
           COMPUTE WS-MESES-AUX =
               HV-SIN-IMPORTE-DECL - HV-SIN-IMPORTE-PAG
           IF L-IMPORTE-PAGO > WS-MESES-AUX
              MOVE 30 TO L-RETURN-CODE
           END-IF.
      *
       4000-REGISTRAR-PAGO.
           EXEC SQL
               SELECT MAX(PAG_ID) + 1
               INTO :WS-NUEVO-PAG-ID
               FROM PAGOS_SINIESTRO
           END-EXEC
           EXEC SQL
               INSERT INTO PAGOS_SINIESTRO
                   (PAG_ID, PAG_SIN_ID, PAG_IMPORTE,
                    PAG_FECHA, PAG_BENEFICIARIO,
                    PAG_CONCEPTO, PAG_ESTADO)
               VALUES
                   (:WS-NUEVO-PAG-ID, :L-SIN-ID, :L-IMPORTE-PAGO,
                    :L-FECHA-PAGO, :L-BENEFICIARIO,
                    :L-CONCEPTO, 'PE')
           END-EXEC
           IF SQLCODE-PAG NOT = 0
              MOVE 40 TO L-RETURN-CODE
           END-IF.
      *
       5000-ACTUALIZAR-SINIESTRO.
           COMPUTE HV-SIN-IMPORTE-PAG = HV-SIN-IMPORTE-PAG +
               L-IMPORTE-PAGO
           EVALUATE TRUE
             WHEN HV-SIN-IMPORTE-PAG >= HV-SIN-IMPORTE-DECL
               EXEC SQL
                   UPDATE SINIESTROS
                   SET SIN_ESTADO = 'PA',
                       SIN_IMPORTE_PAGADO = :HV-SIN-IMPORTE-PAG
                   WHERE SIN_ID = :L-SIN-ID
               END-EXEC
             WHEN OTHER
               EXEC SQL
                   UPDATE SINIESTROS
                   SET SIN_ESTADO = 'TR',
                       SIN_IMPORTE_PAGADO = :HV-SIN-IMPORTE-PAG
                   WHERE SIN_ID = :L-SIN-ID
               END-EXEC
           END-EVALUATE.
