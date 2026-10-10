       IDENTIFICATION DIVISION.
       PROGRAM-ID. TARIFA.
      *----------------------------------------------------------------*
      * TARIFA  - Calculo de prima segun producto, tomador y fechas    *
      * Llama a: VALDAT COBDEF GARDEF                                  *
      *----------------------------------------------------------------*
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-MAINFRAME.
      *
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY PRODREC.
       01 WS-EDAD-TOMADOR        PIC 9(3) VALUE 0.
       01 WS-FACTOR-EDAD         PIC S9(3)V9(6) COMP-3 VALUE 1.
       01 WS-FACTOR-MODALIDAD    PIC S9(3)V9(4) COMP-3 VALUE 1.
       01 WS-PRIMA-BASE          PIC S9(9)V9(2) COMP-3 VALUE 0.
       01 WS-FUNCION-VALDAT      PIC X(1).
       01 WS-FECHA-NACIM         PIC 9(8).
       01 WS-FECHA-HOY           PIC 9(8).
       01 WS-MESES-EDAD          PIC S9(5) COMP VALUE 0.
       01 WS-COD-RETORNO-VALDAT  PIC S9(4) COMP VALUE 0.
       01 WS-FECHA-AUX           PIC 9(8).
       01 WS-MESES-AUX           PIC S9(5) COMP VALUE 0.
      *
       01 DCLGEN-TARIFAS.
          05 HV-TAR-PRODUCTO     PIC X(6).
          05 HV-TAR-EDAD-MIN     PIC 9(3).
          05 HV-TAR-EDAD-MAX     PIC 9(3).
          05 HV-TAR-PRIMA-BASE   PIC S9(9)V9(2) COMP-3.
          05 HV-TAR-FACTOR       PIC S9(3)V9(6) COMP-3.
          05 SQLCODE             PIC S9(9) COMP.
      *
       01 DCLGEN-PERSONAS-TAR.
          05 HV-PER-FECHA-NACIM  PIC 9(8).
          05 SQLCODE-PER         PIC S9(9) COMP.
      *
       LINKAGE SECTION.
       01 L-PRODUCTO             PIC X(6).
       01 L-TOMADOR              PIC 9(10).
       01 L-FECHA-EFECTO         PIC 9(8).
       01 L-MODALIDAD            PIC X(3).
       01 L-PRIMA-CALCULADA      PIC S9(9)V9(2) COMP-3.
       01 L-RETURN-CODE          PIC S9(4) COMP.
      *
       PROCEDURE DIVISION USING L-PRODUCTO
                                 L-TOMADOR
                                 L-FECHA-EFECTO
                                 L-MODALIDAD
                                 L-PRIMA-CALCULADA
                                 L-RETURN-CODE.
           MOVE 0 TO L-RETURN-CODE
           PERFORM 1000-OBTENER-FECHA-NACIM
           IF L-RETURN-CODE = 0
              PERFORM 2000-CALCULAR-EDAD
           END-IF
           IF L-RETURN-CODE = 0
              PERFORM 3000-BUSCAR-TARIFA
           END-IF
           IF L-RETURN-CODE = 0
              PERFORM 4000-APLICAR-FACTORES
           END-IF
           STOP RUN.
      *
       1000-OBTENER-FECHA-NACIM.
           EXEC SQL
               SELECT PER_FECHA_NACIM
               INTO :HV-PER-FECHA-NACIM
               FROM PERSONAS
               WHERE PER_ID = :L-TOMADOR
           END-EXEC
           IF SQLCODE NOT = 0
              MOVE 10 TO L-RETURN-CODE
           ELSE
              MOVE HV-PER-FECHA-NACIM TO WS-FECHA-NACIM
           END-IF.
      *
       2000-CALCULAR-EDAD.
           MOVE '2' TO WS-FUNCION-VALDAT
           CALL 'VALDAT' USING WS-FUNCION-VALDAT
                               WS-FECHA-NACIM
                               L-FECHA-EFECTO
                               WS-MESES-EDAD
                               WS-FECHA-AUX
                               WS-MESES-AUX
                               WS-COD-RETORNO-VALDAT
           COMPUTE WS-EDAD-TOMADOR = WS-MESES-EDAD / 12.
      *
       3000-BUSCAR-TARIFA.
           MOVE L-PRODUCTO TO HV-TAR-PRODUCTO
           EXEC SQL
               SELECT TAR_PRIMA_BASE, TAR_FACTOR
               INTO :HV-TAR-PRIMA-BASE, :HV-TAR-FACTOR
               FROM TARIFAS
               WHERE TAR_PRODUCTO = :HV-TAR-PRODUCTO
                 AND TAR_EDAD_MIN <= :WS-EDAD-TOMADOR
                 AND TAR_EDAD_MAX >= :WS-EDAD-TOMADOR
                 AND TAR_VIGENTE = 'S'
           END-EXEC
           IF SQLCODE NOT = 0
              MOVE 30 TO L-RETURN-CODE
           ELSE
              MOVE HV-TAR-PRIMA-BASE TO WS-PRIMA-BASE
              MOVE HV-TAR-FACTOR     TO WS-FACTOR-EDAD
           END-IF.
      *
       4000-APLICAR-FACTORES.
           EVALUATE L-MODALIDAD
             WHEN 'SEM'
               MOVE 0.52 TO WS-FACTOR-MODALIDAD
             WHEN 'MEN'
               MOVE 0.09 TO WS-FACTOR-MODALIDAD
             WHEN OTHER
               MOVE 1.00 TO WS-FACTOR-MODALIDAD
           END-EVALUATE
           COMPUTE L-PRIMA-CALCULADA ROUNDED =
               WS-PRIMA-BASE * WS-FACTOR-EDAD * WS-FACTOR-MODALIDAD.
