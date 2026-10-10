       IDENTIFICATION DIVISION.
       PROGRAM-ID. PERSIN.
      *----------------------------------------------------------------*
      * PERSIN  - Verificacion de periodos de cobertura                *
      * Llama a: VALDAT                                                *
      *----------------------------------------------------------------*
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-MAINFRAME.
      *
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-RETURN-CODE         PIC S9(4) COMP VALUE 0.
       01 WS-MESES-VIGENCIA      PIC S9(5) COMP VALUE 0.
       01 WS-FUNCION-VALDAT      PIC X(1).
       01 WS-FECHA-AUX           PIC 9(8).
       01 WS-MESES-AUX           PIC S9(5) COMP VALUE 0.
       01 WS-COD-RETORNO-VALDAT  PIC S9(4) COMP VALUE 0.
      *
       01 DCLGEN-PERIODOS.
          05 HV-PER-POL-NUMERO   PIC 9(8).
          05 HV-PER-COBERTURA    PIC X(6).
          05 HV-PER-FECHA-DESDE  PIC 9(8).
          05 HV-PER-FECHA-HASTA  PIC 9(8).
          05 HV-PER-ESTADO       PIC X(1).
          05 SQLCODE             PIC S9(9) COMP.
      *
       LINKAGE SECTION.
       01 L-POL-NUMERO           PIC 9(8).
       01 L-COBERTURA            PIC X(6).
       01 L-FECHA-INICIO-COB     PIC 9(8).
       01 L-FECHA-FIN-COB        PIC 9(8).
       01 L-RETURN-CODE          PIC S9(4) COMP.
      *
       PROCEDURE DIVISION USING L-POL-NUMERO
                                 L-COBERTURA
                                 L-FECHA-INICIO-COB
                                 L-FECHA-FIN-COB
                                 L-RETURN-CODE.
           MOVE 0 TO L-RETURN-CODE
           PERFORM 1000-OBTENER-PERIODO-COBERTURA
           IF L-RETURN-CODE = 0
              PERFORM 2000-CALCULAR-VIGENCIA
           END-IF
           STOP RUN.
      *
       1000-OBTENER-PERIODO-COBERTURA.
           EXEC SQL
               SELECT PER_FECHA_DESDE, PER_FECHA_HASTA, PER_ESTADO
               INTO :HV-PER-FECHA-DESDE, :HV-PER-FECHA-HASTA,
                    :HV-PER-ESTADO
               FROM PERIODOS_COBERTURA
               WHERE PER_POL_NUMERO = :L-POL-NUMERO
                 AND PER_COBERTURA  = :L-COBERTURA
                 AND PER_ESTADO     = 'V'
               ORDER BY PER_FECHA_DESDE DESC
               FETCH FIRST 1 ROW ONLY
           END-EXEC
           IF SQLCODE NOT = 0
              MOVE HV-PER-FECHA-DESDE TO L-FECHA-INICIO-COB
              MOVE HV-PER-FECHA-HASTA TO L-FECHA-FIN-COB
              MOVE 10 TO L-RETURN-CODE
           ELSE
              MOVE HV-PER-FECHA-DESDE TO L-FECHA-INICIO-COB
              MOVE HV-PER-FECHA-HASTA TO L-FECHA-FIN-COB
           END-IF.
      *
       2000-CALCULAR-VIGENCIA.
           MOVE '2' TO WS-FUNCION-VALDAT
           CALL 'VALDAT' USING WS-FUNCION-VALDAT
                               L-FECHA-INICIO-COB
                               L-FECHA-FIN-COB
                               WS-MESES-VIGENCIA
                               WS-FECHA-AUX
                               WS-MESES-AUX
                               WS-COD-RETORNO-VALDAT
           IF WS-MESES-VIGENCIA <= 0
              MOVE 20 TO L-RETURN-CODE
           END-IF.
