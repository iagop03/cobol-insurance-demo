       IDENTIFICATION DIVISION.
       PROGRAM-ID. VALDAT.
      *----------------------------------------------------------------*
      * VALDAT  - Validacion y calculo de fechas                       *
      * Llamado por: EMIPOL TARIFA SUPLMT RENOVA ANULAN REHPOL MOVPOL  *
      *              GENREC COBRAN DEVOLU SINREG PERSIN PAGSIN          *
      *----------------------------------------------------------------*
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-MAINFRAME.
      *
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-FECHA-TRABAJO.
          05 WS-ANIO             PIC 9(4).
          05 WS-MES              PIC 9(2).
          05 WS-DIA              PIC 9(2).
       01 WS-MESES-DIFF          PIC S9(5) COMP.
       01 WS-RETURN-CODE         PIC S9(4) COMP VALUE 0.
      *
       LINKAGE SECTION.
       01 L-FUNCION              PIC X(1).
          88 L-VALIDAR           VALUE '1'.
          88 L-DIFF-MESES        VALUE '2'.
          88 L-SUMAR-MESES       VALUE '3'.
          88 L-VALIDAR-PERIODO   VALUE '4'.
       01 L-FECHA1               PIC 9(8).
       01 L-FECHA2               PIC 9(8).
       01 L-RESULTADO-MESES      PIC S9(5) COMP.
       01 L-FECHA-SALIDA         PIC 9(8).
       01 L-MESES-SUMAR          PIC S9(5) COMP.
       01 L-CODIGO-RETORNO       PIC S9(4) COMP.
      *
       PROCEDURE DIVISION USING L-FUNCION
                                 L-FECHA1
                                 L-FECHA2
                                 L-RESULTADO-MESES
                                 L-FECHA-SALIDA
                                 L-MESES-SUMAR
                                 L-CODIGO-RETORNO.
           MOVE 0 TO L-CODIGO-RETORNO
           EVALUATE TRUE
             WHEN L-VALIDAR
               PERFORM 1000-VALIDAR-FECHA
             WHEN L-DIFF-MESES
               PERFORM 2000-DIFF-MESES
             WHEN L-SUMAR-MESES
               PERFORM 3000-SUMAR-MESES
             WHEN L-VALIDAR-PERIODO
               PERFORM 4000-VALIDAR-PERIODO
             WHEN OTHER
               MOVE 99 TO L-CODIGO-RETORNO
           END-EVALUATE
           STOP RUN.
      *
       1000-VALIDAR-FECHA.
           MOVE L-FECHA1(1:4) TO WS-ANIO
           MOVE L-FECHA1(5:2) TO WS-MES
           MOVE L-FECHA1(7:2) TO WS-DIA
           IF WS-ANIO < 1900 OR WS-ANIO > 2099
              MOVE 1 TO L-CODIGO-RETORNO
           ELSE IF WS-MES < 1 OR WS-MES > 12
              MOVE 2 TO L-CODIGO-RETORNO
           ELSE IF WS-DIA < 1 OR WS-DIA > 31
              MOVE 3 TO L-CODIGO-RETORNO
           END-IF.
      *
       2000-DIFF-MESES.
           COMPUTE L-RESULTADO-MESES =
               (L-FECHA2(1:4) - L-FECHA1(1:4)) * 12 +
               (L-FECHA2(5:2) - L-FECHA1(5:2)).
      *
       3000-SUMAR-MESES.
           MOVE L-FECHA1(1:4) TO WS-ANIO
           MOVE L-FECHA1(5:2) TO WS-MES
           MOVE L-FECHA1(7:2) TO WS-DIA
           ADD L-MESES-SUMAR TO WS-MES
           PERFORM UNTIL WS-MES <= 12
               ADD 1 TO WS-ANIO
               SUBTRACT 12 FROM WS-MES
           END-PERFORM
           STRING WS-ANIO WS-MES WS-DIA
               DELIMITED SIZE INTO L-FECHA-SALIDA.
      *
       4000-VALIDAR-PERIODO.
           IF L-FECHA1 <= L-FECHA2
              MOVE 0 TO L-CODIGO-RETORNO
           ELSE
              MOVE 4 TO L-CODIGO-RETORNO
           END-IF.
