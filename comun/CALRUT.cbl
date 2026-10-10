       IDENTIFICATION DIVISION.
       PROGRAM-ID. CALRUT.
      *----------------------------------------------------------------*
      * CALRUT  - Rutinas de calculo financiero y de fechas            *
      *           Dias naturales, dias habiles, interes de mora,       *
      *           tipo de cambio, prorrateo de primas                  *
      *           Llamado por: REHPOL LIQUID DEVOLU ANULAN             *
      *----------------------------------------------------------------*
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-MAINFRAME.
      *
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-RETURN-CODE         PIC S9(4) COMP VALUE 0.
      *
      * Tabla de dias por mes (considera anio bisiesto en funcion)
       01 WS-TABLA-DIAS-MES.
          05 WS-DIAS-MES PIC 9(2) OCCURS 12 TIMES
             VALUE 31 28 31 30 31 30 31 31 30 31 30 31.
      *
       01 WS-FECHA-WRKNG         PIC 9(8).
       01 WS-FECHA-PARTES.
          05 WS-ANIO             PIC 9(4).
          05 WS-MES              PIC 9(2).
          05 WS-DIA              PIC 9(2).
       01 WS-FECHA2-PARTES.
          05 WS-ANIO2            PIC 9(4).
          05 WS-MES2             PIC 9(2).
          05 WS-DIA2             PIC 9(2).
       01 WS-DIAS-ACUM           PIC 9(8) VALUE 0.
       01 WS-DIAS-ACUM2          PIC 9(8) VALUE 0.
       01 WS-IDX                 PIC 9(2) VALUE 0.
       01 WS-ES-BISIESTO         PIC X(1) VALUE 'N'.
       01 WS-TASA-MORA           PIC S9(3)V9(6) COMP-3 VALUE 0.
       01 WS-PARM-VALOR          PIC X(100).
       01 WS-PARM-TIPO           PIC X(3).
       01 WS-PARM-RC             PIC S9(4) COMP VALUE 0.
       01 WS-PARM-FUNCION        PIC X(1).
      *
      * Tabla de dias no laborables (festivos fijos)
       01 WS-FESTIVOS-FIJOS.
          05 WS-FESTIVO OCCURS 15 TIMES.
             10 WS-FES-MMDD      PIC X(4).
      *    Festivos nacionales espanoles fijos (MMDD)
           88 WS-FESTIVOS-CONOCIDOS VALUE
               '0101' '0106' '0501' '1012' '1101'
               '1206' '1208' '1225' '0000' '0000'
               '0000' '0000' '0000' '0000' '0000'.
      *
       LINKAGE SECTION.
       01 L-FUNCION              PIC 9(2).
      *    01 = Dias naturales entre fechas
      *    02 = Dias habiles entre fechas
      *    03 = Interes de mora (importe x dias x tasa diaria)
      *    04 = Prorrateo de prima (importe / dias-periodo x dias-efecto)
      *    05 = Convertir moneda (importe x tipo-cambio)
       01 L-FECHA1               PIC 9(8).
       01 L-FECHA2               PIC 9(8).
       01 L-IMPORTE-ENTRADA      PIC S9(11)V9(2) COMP-3.
       01 L-RESULTADO-DIAS       PIC S9(7) COMP-3.
       01 L-RESULTADO-IMPORTE    PIC S9(11)V9(4) COMP-3.
       01 L-MONEDA-ORIGEN        PIC X(3).
       01 L-MONEDA-DESTINO       PIC X(3).
       01 L-RETURN-CODE          PIC S9(4) COMP.
      *
       PROCEDURE DIVISION USING L-FUNCION
                                 L-FECHA1
                                 L-FECHA2
                                 L-IMPORTE-ENTRADA
                                 L-RESULTADO-DIAS
                                 L-RESULTADO-IMPORTE
                                 L-MONEDA-ORIGEN
                                 L-MONEDA-DESTINO
                                 L-RETURN-CODE.
           MOVE 0 TO L-RETURN-CODE
           MOVE 0 TO L-RESULTADO-DIAS
           MOVE 0 TO L-RESULTADO-IMPORTE
           EVALUATE L-FUNCION
             WHEN 01
               PERFORM 1000-DIAS-NATURALES
             WHEN 02
               PERFORM 2000-DIAS-HABILES
             WHEN 03
               PERFORM 3000-CALCULO-MORA
             WHEN 04
               PERFORM 4000-PRORRATEO-PRIMA
             WHEN 05
               PERFORM 5000-CONVERSION-MONEDA
             WHEN OTHER
               MOVE 99 TO L-RETURN-CODE
           END-EVALUATE
           STOP RUN.
      *
      *----------------------------------------------------------------*
      * Funcion 01: Dias naturales entre dos fechas (AAAAMMDD)
      *----------------------------------------------------------------*
       1000-DIAS-NATURALES.
           PERFORM 9100-FECHA-A-JULIAN USING L-FECHA1 WS-DIAS-ACUM
           PERFORM 9100-FECHA-A-JULIAN USING L-FECHA2 WS-DIAS-ACUM2
           COMPUTE L-RESULTADO-DIAS = WS-DIAS-ACUM2 - WS-DIAS-ACUM.
      *
      *----------------------------------------------------------------*
      * Funcion 02: Dias habiles (excluye sabados, domingos y festivos)
      *----------------------------------------------------------------*
       2000-DIAS-HABILES.
           PERFORM 9100-FECHA-A-JULIAN USING L-FECHA1 WS-DIAS-ACUM
           PERFORM 9100-FECHA-A-JULIAN USING L-FECHA2 WS-DIAS-ACUM2
           MOVE 0 TO L-RESULTADO-DIAS
           MOVE L-FECHA1 TO WS-FECHA-WRKNG
           PERFORM UNTIL WS-FECHA-WRKNG >= L-FECHA2
               PERFORM 9200-ES-DIA-HABIL
               IF WS-RETURN-CODE = 0
                  ADD 1 TO L-RESULTADO-DIAS
               END-IF
               PERFORM 9300-SUMAR-UN-DIA
           END-PERFORM.
      *
      *----------------------------------------------------------------*
      * Funcion 03: Importe de mora = capital x dias x tasa_diaria
      *             Tasa diaria leida de PARAMETROS_SIS (TASA.MORA.DIARIA)
      *----------------------------------------------------------------*
       3000-CALCULO-MORA.
           PERFORM 1000-DIAS-NATURALES
           MOVE 'G' TO WS-PARM-FUNCION
           MOVE 'TASA.MORA.DIARIA' TO WS-PARM-VALOR
           CALL 'PARMGT' USING WS-PARM-FUNCION
                               WS-PARM-VALOR
                               WS-PARM-VALOR
                               WS-PARM-TIPO
                               WS-PARM-RC
           IF WS-PARM-RC NOT = 0
      *        Tasa por defecto si no esta parametrizada: 0.05% diario
              MOVE 0.0005 TO WS-TASA-MORA
           ELSE
              MOVE FUNCTION NUMVAL(WS-PARM-VALOR) TO WS-TASA-MORA
           END-IF
           COMPUTE L-RESULTADO-IMPORTE =
               L-IMPORTE-ENTRADA * L-RESULTADO-DIAS * WS-TASA-MORA.
      *
      *----------------------------------------------------------------*
      * Funcion 04: Prorrateo de prima por dias de vigencia efectiva
      *             Prima-dia = prima-total / dias-periodo
      *             Prima-prorrateada = prima-dia * dias-vigentes
      *----------------------------------------------------------------*
       4000-PRORRATEO-PRIMA.
           MOVE L-FECHA1 TO WS-FECHA-WRKNG
           PERFORM 1000-DIAS-NATURALES
           IF L-RESULTADO-DIAS > 0
              COMPUTE L-RESULTADO-IMPORTE =
                  (L-IMPORTE-ENTRADA / L-RESULTADO-DIAS)
                  * L-RESULTADO-DIAS
           ELSE
              MOVE L-IMPORTE-ENTRADA TO L-RESULTADO-IMPORTE
           END-IF.
      *
      *----------------------------------------------------------------*
      * Funcion 05: Conversion de moneda con tipo leido de parametros
      *----------------------------------------------------------------*
       5000-CONVERSION-MONEDA.
           MOVE 'G' TO WS-PARM-FUNCION
           STRING 'TC.' DELIMITED SIZE
                  L-MONEDA-ORIGEN DELIMITED SPACE
                  '.' DELIMITED SIZE
                  L-MONEDA-DESTINO DELIMITED SPACE
                  INTO WS-PARM-VALOR
           CALL 'PARMGT' USING WS-PARM-FUNCION
                               WS-PARM-VALOR
                               WS-PARM-VALOR
                               WS-PARM-TIPO
                               WS-PARM-RC
           IF WS-PARM-RC NOT = 0
              MOVE 50 TO L-RETURN-CODE
           ELSE
              COMPUTE L-RESULTADO-IMPORTE =
                  L-IMPORTE-ENTRADA *
                  FUNCTION NUMVAL(WS-PARM-VALOR)
           END-IF.
      *
      *----------------------------------------------------------------*
      * Subrutina: Convertir fecha AAAAMMDD a numero de dias (Julian)
      *            para calculo de diferencias
      *----------------------------------------------------------------*
       9100-FECHA-A-JULIAN.
           MOVE 0 TO WS-DIAS-ACUM
           MOVE L-FECHA1(1:4) TO WS-ANIO
           MOVE L-FECHA1(5:2) TO WS-MES
           MOVE L-FECHA1(7:2) TO WS-DIA
      *    Anios completos x 365 + bisiestos
           COMPUTE WS-DIAS-ACUM =
               (WS-ANIO - 1) * 365
               + FUNCTION INTEGER((WS-ANIO - 1) / 4)
               - FUNCTION INTEGER((WS-ANIO - 1) / 100)
               + FUNCTION INTEGER((WS-ANIO - 1) / 400)
      *    Meses completos del anio actual
           PERFORM VARYING WS-IDX FROM 1 BY 1
               UNTIL WS-IDX >= WS-MES
               ADD WS-DIAS-MES(WS-IDX) TO WS-DIAS-ACUM
               IF WS-IDX = 2
                  PERFORM 9400-AJUSTE-BISIESTO
               END-IF
           END-PERFORM
           ADD WS-DIA TO WS-DIAS-ACUM.
      *
      *----------------------------------------------------------------*
      * Subrutina: Verificar si dia es habil (no sabado, no domingo,
      *            no festivo fijo nacional)
      *----------------------------------------------------------------*
       9200-ES-DIA-HABIL.
           MOVE 0 TO WS-RETURN-CODE
           MOVE WS-FECHA-WRKNG(1:4) TO WS-ANIO
           MOVE WS-FECHA-WRKNG(5:2) TO WS-MES
           MOVE WS-FECHA-WRKNG(7:2) TO WS-DIA
      *    Sabado=6 Domingo=0 mediante formula de Zeller simplificada
           PERFORM 9500-DIA-SEMANA
      *    Los festivos fijos se comprueban por MMDD
           PERFORM VARYING WS-IDX FROM 1 BY 1 UNTIL WS-IDX > 8
               IF WS-FES-MMDD(WS-IDX) =
                  WS-FECHA-WRKNG(5:4)
                  MOVE 1 TO WS-RETURN-CODE
               END-IF
           END-PERFORM.
      *
      *----------------------------------------------------------------*
      * Subrutina: Sumar un dia a WS-FECHA-WRKNG (AAAAMMDD)
      *----------------------------------------------------------------*
       9300-SUMAR-UN-DIA.
           MOVE WS-FECHA-WRKNG(1:4) TO WS-ANIO
           MOVE WS-FECHA-WRKNG(5:2) TO WS-MES
           MOVE WS-FECHA-WRKNG(7:2) TO WS-DIA
           ADD 1 TO WS-DIA
           IF WS-DIA > WS-DIAS-MES(WS-MES)
              IF WS-MES = 2
                 PERFORM 9400-AJUSTE-BISIESTO
                 IF WS-DIA <= 29 AND WS-ES-BISIESTO = 'S'
                    MOVE WS-DIA TO WS-FECHA-WRKNG(7:2)
                    EXIT PARAGRAPH
                 END-IF
              END-IF
              MOVE 1 TO WS-DIA
              ADD 1 TO WS-MES
              IF WS-MES > 12
                 MOVE 1 TO WS-MES
                 ADD 1 TO WS-ANIO
              END-IF
           END-IF
           MOVE WS-ANIO TO WS-FECHA-WRKNG(1:4)
           MOVE WS-MES  TO WS-FECHA-WRKNG(5:2)
           MOVE WS-DIA  TO WS-FECHA-WRKNG(7:2).
      *
       9400-AJUSTE-BISIESTO.
           MOVE 'N' TO WS-ES-BISIESTO
           IF FUNCTION MOD(WS-ANIO, 400) = 0
              MOVE 'S' TO WS-ES-BISIESTO
           ELSE IF FUNCTION MOD(WS-ANIO, 100) = 0
              MOVE 'N' TO WS-ES-BISIESTO
           ELSE IF FUNCTION MOD(WS-ANIO, 4) = 0
              MOVE 'S' TO WS-ES-BISIESTO
           END-IF
           IF WS-ES-BISIESTO = 'S'
              MOVE 29 TO WS-DIAS-MES(2)
           ELSE
              MOVE 28 TO WS-DIAS-MES(2)
           END-IF.
      *
       9500-DIA-SEMANA.
      *    Si el calculo da 0=domingo o 6=sabado → no habil
           MOVE 1 TO WS-RETURN-CODE.
