       IDENTIFICATION DIVISION.
       PROGRAM-ID. VALSIN.
      *----------------------------------------------------------------*
      * VALSIN  - Validacion de siniestros (formato y coherencia)      *
      * Llama a: COBSIN PERSIN                                         *
      *----------------------------------------------------------------*
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-MAINFRAME.
      *
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-RETURN-CODE         PIC S9(4) COMP VALUE 0.
       01 WS-COBERTURA-VALIDA    PIC X(1) VALUE 'N'.
       01 WS-FECHA-INICIO-COB    PIC 9(8).
       01 WS-FECHA-FIN-COB       PIC 9(8).
      *
       01 DCLGEN-POLIZAS-VAL.
          05 HV-POL-NUMERO       PIC 9(8).
          05 HV-POL-PRODUCTO     PIC X(6).
          05 HV-POL-VERSION      PIC 9(3).
          05 HV-POL-FECHA-EFECT  PIC 9(8).
          05 HV-POL-FECHA-VCTO   PIC 9(8).
          05 HV-POL-ESTADO       PIC X(2).
          05 SQLCODE             PIC S9(9) COMP.
      *
       LINKAGE SECTION.
       01 L-POL-NUMERO           PIC 9(8).
       01 L-FECHA-OCURRENCIA     PIC 9(8).
       01 L-COBERTURA            PIC X(6).
       01 L-IMPORTE              PIC S9(9)V9(2) COMP-3.
       01 L-RETURN-CODE          PIC S9(4) COMP.
      *
       PROCEDURE DIVISION USING L-POL-NUMERO
                                 L-FECHA-OCURRENCIA
                                 L-COBERTURA
                                 L-IMPORTE
                                 L-RETURN-CODE.
           MOVE 0 TO L-RETURN-CODE
           PERFORM 1000-OBTENER-POLIZA
           IF L-RETURN-CODE = 0
              PERFORM 2000-VALIDAR-COBERTURA
           END-IF
           IF L-RETURN-CODE = 0
              PERFORM 3000-VALIDAR-PERIODO
           END-IF
           IF L-RETURN-CODE = 0
              PERFORM 4000-VALIDAR-IMPORTE
           END-IF
           STOP RUN.
      *
       1000-OBTENER-POLIZA.
           EXEC SQL
               SELECT POL_PRODUCTO, POL_VERSION_PROD,
                      POL_FECHA_EFECT, POL_FECHA_VCTO, POL_ESTADO
               INTO :HV-POL-PRODUCTO, :HV-POL-VERSION,
                    :HV-POL-FECHA-EFECT, :HV-POL-FECHA-VCTO,
                    :HV-POL-ESTADO
               FROM POLIZAS
               WHERE POL_NUMERO = :L-POL-NUMERO
           END-EXEC
           IF SQLCODE NOT = 0
              MOVE 10 TO L-RETURN-CODE
           END-IF.
      *
       2000-VALIDAR-COBERTURA.
           CALL 'COBSIN' USING HV-POL-PRODUCTO
                               HV-POL-VERSION
                               L-COBERTURA
                               WS-COBERTURA-VALIDA
                               WS-RETURN-CODE
           IF WS-COBERTURA-VALIDA = 'N'
              MOVE 20 TO L-RETURN-CODE
           END-IF.
      *
       3000-VALIDAR-PERIODO.
           CALL 'PERSIN' USING L-POL-NUMERO
                               L-COBERTURA
                               WS-FECHA-INICIO-COB
                               WS-FECHA-FIN-COB
                               WS-RETURN-CODE
      *    Nota: verifica que el periodo de cobertura exista y sea
      *    valido, pero no compara con L-FECHA-OCURRENCIA.
      *    La validacion de que la fecha de siniestro este dentro
      *    del periodo corresponde a SINREG (y no se hace alli tampoco).
           IF WS-RETURN-CODE NOT = 0
              MOVE 30 TO L-RETURN-CODE
           END-IF.
      *
       4000-VALIDAR-IMPORTE.
           IF L-IMPORTE <= 0
              MOVE 40 TO L-RETURN-CODE
           END-IF.
