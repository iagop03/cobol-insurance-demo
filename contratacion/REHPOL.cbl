       IDENTIFICATION DIVISION.
       PROGRAM-ID. REHPOL.
      *----------------------------------------------------------------*
      * REHPOL  - Rehabilitacion de polizas vencidas                   *
      * Llama a: MOVPOL VALDAT                                         *
      *                                                                *
      * BUG CONOCIDO: WS-MESES-AJUSTE usa FUNCTION MOD con divisor 12  *
      * Esto wrappea incorrectamente para mora > 12 meses:             *
      *   13 meses vencidos → MOD(13,12) = 1 → recargo de 1 mes       *
      * El recargo debería acumular todos los meses, no hacer mod 12.  *
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
       01 WS-MESES-AJUSTE        PIC 9(3) VALUE 0.
       01 WS-PRIMA-MES           PIC S9(9)V9(2) COMP-3 VALUE 0.
       01 WS-RECARGO-MORA        PIC S9(9)V9(2) COMP-3 VALUE 0.
       01 WS-FUNCION-VALDAT      PIC X(1).
       01 WS-FECHA-HOY           PIC 9(8).
       01 WS-FECHA-AUX           PIC 9(8).
       01 WS-MESES-AUX           PIC S9(5) COMP VALUE 0.
       01 WS-COD-RETORNO-VALDAT  PIC S9(4) COMP VALUE 0.
      *
       01 DCLGEN-POLIZAS-REH.
          05 HV-POL-NUMERO       PIC 9(8).
          05 HV-POL-ESTADO       PIC X(2).
          05 HV-POL-MESES-VENC   PIC 9(3).
          05 HV-POL-PRIMA-TOTAL  PIC S9(9)V9(2) COMP-3.
          05 HV-POL-FECHA-EFECT  PIC 9(8).
          05 HV-POL-FECHA-VCTO   PIC 9(8).
          05 SQLCODE             PIC S9(9) COMP.
      *
       LINKAGE SECTION.
       01 L-POL-NUMERO           PIC 9(8).
       01 L-FECHA-REHAB          PIC 9(8).
       01 L-RECARGO-CALCULADO    PIC S9(9)V9(2) COMP-3.
       01 L-RETURN-CODE          PIC S9(4) COMP.
      *
       PROCEDURE DIVISION USING L-POL-NUMERO
                                 L-FECHA-REHAB
                                 L-RECARGO-CALCULADO
                                 L-RETURN-CODE.
           MOVE 0 TO L-RETURN-CODE
           PERFORM 1000-OBTENER-POLIZA
           IF L-RETURN-CODE = 0
              PERFORM 2000-CALCULAR-RECARGO-MORA
           END-IF
           IF L-RETURN-CODE = 0
              PERFORM 3000-ACTUALIZAR-POLIZA
           END-IF
           IF L-RETURN-CODE = 0
              PERFORM 4000-REGISTRAR-MOVIMIENTO
           END-IF
           STOP RUN.
      *
       1000-OBTENER-POLIZA.
           MOVE L-POL-NUMERO TO HV-POL-NUMERO
           EXEC SQL
               SELECT POL_ESTADO, POL_MESES_VENCIDA,
                      POL_PRIMA_TOTAL, POL_FECHA_EFECT, POL_FECHA_VCTO
               INTO :HV-POL-ESTADO, :HV-POL-MESES-VENC,
                    :HV-POL-PRIMA-TOTAL, :HV-POL-FECHA-EFECT,
                    :HV-POL-FECHA-VCTO
               FROM POLIZAS
               WHERE POL_NUMERO = :HV-POL-NUMERO
                 AND POL_ESTADO = 'VE'
           END-EXEC
           IF SQLCODE NOT = 0
              MOVE 10 TO L-RETURN-CODE
           END-IF.
      *
       2000-CALCULAR-RECARGO-MORA.
      *    BUG: MOD(meses, 12) wrappea en 0 cuando meses = multiplo de 12
      *    y produce recargo incorrecto para mora > 12 meses
           COMPUTE WS-MESES-AJUSTE =
               FUNCTION MOD(HV-POL-MESES-VENC, 12)
           COMPUTE WS-PRIMA-MES ROUNDED =
               HV-POL-PRIMA-TOTAL / 12
           COMPUTE WS-RECARGO-MORA ROUNDED =
               WS-PRIMA-MES * WS-MESES-AJUSTE * 0.02
           MOVE WS-RECARGO-MORA TO L-RECARGO-CALCULADO.
      *
       3000-ACTUALIZAR-POLIZA.
           EXEC SQL
               UPDATE POLIZAS
               SET POL_ESTADO        = 'RH',
                   POL_MESES_VENCIDA = 0,
                   POL_FECHA_REHAB   = :L-FECHA-REHAB,
                   POL_RECARGO_MORA  = :WS-RECARGO-MORA
               WHERE POL_NUMERO = :HV-POL-NUMERO
           END-EXEC
           IF SQLCODE NOT = 0
              MOVE 30 TO L-RETURN-CODE
           END-IF.
      *
       4000-REGISTRAR-MOVIMIENTO.
           CALL 'MOVPOL' USING L-POL-NUMERO
                               WS-RECARGO-MORA
                               WS-RETURN-CODE.
