       IDENTIFICATION DIVISION.
       PROGRAM-ID. EMIPOL.
      *----------------------------------------------------------------*
      * EMIPOL  - Emision de nueva poliza                              *
      * Llama a: NEGDEF TARIFA INTMED PERSOM MOVPOL VALDAT ERRMSG      *
      *----------------------------------------------------------------*
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-MAINFRAME.
      *
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY POLREC.
       01 WS-RETURN-CODE         PIC S9(4) COMP VALUE 0.
       01 WS-NUEVA-POL-NUM       PIC 9(8)       VALUE 0.
       01 WS-FECHA-HOY           PIC 9(8)       VALUE 0.
       01 WS-FUNCION-VALDAT      PIC X(1).
       01 WS-FECHA-AUX           PIC 9(8).
       01 WS-MESES-AUX           PIC S9(5) COMP VALUE 0.
       01 WS-FECHA-VCTO-AUX      PIC 9(8).
       01 WS-COD-RETORNO-VALDAT  PIC S9(4) COMP VALUE 0.
      *
       01 DCLGEN-POLIZAS.
          05 HV-POL-NUMERO       PIC 9(8).
          05 HV-POL-ESTADO       PIC X(2).
          05 HV-POL-AGENTE       PIC 9(6).
          05 HV-POL-PRIMA-TOTAL  PIC S9(9)V9(2) COMP-3.
          05 SQLCODE             PIC S9(9) COMP.
      *
       01 DCLGEN-CONTRATOS.
          05 HV-CON-NUMERO       PIC 9(6).
          05 HV-CON-RAMO         PIC X(4).
          05 SQLCODE-CON         PIC S9(9) COMP.
      *
       LINKAGE SECTION.
       01 L-POL-PRODUCTO         PIC X(6).
       01 L-POL-TOMADOR          PIC 9(10).
       01 L-POL-AGENTE           PIC 9(6).
       01 L-POL-CONTRATO         PIC 9(6).
       01 L-POL-FECHA-EFECT      PIC 9(8).
       01 L-POL-MODALIDAD        PIC X(3).
       01 L-NUMERO-POLIZA        PIC 9(8).
       01 L-PRIMA-CALCULADA      PIC S9(9)V9(2) COMP-3.
       01 L-RETURN-CODE          PIC S9(4) COMP.
      *
       PROCEDURE DIVISION USING L-POL-PRODUCTO
                                 L-POL-TOMADOR
                                 L-POL-AGENTE
                                 L-POL-CONTRATO
                                 L-POL-FECHA-EFECT
                                 L-POL-MODALIDAD
                                 L-NUMERO-POLIZA
                                 L-PRIMA-CALCULADA
                                 L-RETURN-CODE.
           MOVE 0 TO L-RETURN-CODE
           PERFORM 1000-VALIDAR-DATOS
           IF L-RETURN-CODE = 0
              PERFORM 2000-CALCULAR-PRIMA
           END-IF
           IF L-RETURN-CODE = 0
              PERFORM 3000-VERIFICAR-NEGOCIO
           END-IF
           IF L-RETURN-CODE = 0
              PERFORM 4000-VERIFICAR-INTERMEDIARIO
           END-IF
           IF L-RETURN-CODE = 0
              PERFORM 5000-INSERTAR-POLIZA
           END-IF
           IF L-RETURN-CODE = 0
              PERFORM 6000-REGISTRAR-MOVIMIENTO
           END-IF
           STOP RUN.
      *
       1000-VALIDAR-DATOS.
           MOVE '1' TO WS-FUNCION-VALDAT
           CALL 'VALDAT' USING WS-FUNCION-VALDAT
                               L-POL-FECHA-EFECT
                               WS-FECHA-AUX
                               WS-MESES-AUX
                               WS-FECHA-VCTO-AUX
                               WS-MESES-AUX
                               WS-COD-RETORNO-VALDAT
           IF WS-COD-RETORNO-VALDAT NOT = 0
              MOVE 10 TO L-RETURN-CODE
           END-IF.
      *
       2000-CALCULAR-PRIMA.
           CALL 'TARIFA' USING L-POL-PRODUCTO
                               L-POL-TOMADOR
                               L-POL-FECHA-EFECT
                               L-POL-MODALIDAD
                               L-PRIMA-CALCULADA
                               WS-COD-RETORNO-VALDAT
           IF WS-COD-RETORNO-VALDAT NOT = 0
              MOVE 20 TO L-RETURN-CODE
           END-IF.
      *
       3000-VERIFICAR-NEGOCIO.
           CALL 'NEGDEF' USING L-POL-CONTRATO
                               HV-CON-RAMO
                               SQLCODE-CON
           IF SQLCODE-CON NOT = 0
              MOVE 30 TO L-RETURN-CODE
           END-IF.
      *
       4000-VERIFICAR-INTERMEDIARIO.
           CALL 'INTMED' USING L-POL-AGENTE
                               HV-CON-RAMO
                               WS-COD-RETORNO-VALDAT
           IF WS-COD-RETORNO-VALDAT NOT = 0
              MOVE 40 TO L-RETURN-CODE
           END-IF.
      *
       5000-INSERTAR-POLIZA.
           EXEC SQL
               SELECT MAX(POL_NUMERO) + 1
               INTO :HV-POL-NUMERO
               FROM POLIZAS
           END-EXEC
           MOVE HV-POL-NUMERO TO WS-NUEVA-POL-NUM
           MOVE 'AC' TO HV-POL-ESTADO
           MOVE L-POL-AGENTE TO HV-POL-AGENTE
           MOVE L-PRIMA-CALCULADA TO HV-POL-PRIMA-TOTAL
           EXEC SQL
               INSERT INTO POLIZAS
                   (POL_NUMERO, POL_PRODUCTO, POL_TOMADOR,
                    POL_AGENTE, POL_CONTRATO,
                    POL_FECHA_EFECT, POL_FECHA_VCTO,
                    POL_PRIMA_TOTAL, POL_ESTADO, POL_MODALIDAD)
               VALUES
                   (:HV-POL-NUMERO, :L-POL-PRODUCTO, :L-POL-TOMADOR,
                    :L-POL-AGENTE, :L-POL-CONTRATO,
                    :L-POL-FECHA-EFECT, :WS-FECHA-VCTO-AUX,
                    :HV-POL-PRIMA-TOTAL, :HV-POL-ESTADO, :L-POL-MODALIDAD)
           END-EXEC
           IF SQLCODE NOT = 0
              MOVE 50 TO L-RETURN-CODE
           ELSE
              MOVE HV-POL-NUMERO TO L-NUMERO-POLIZA
           END-IF.
      *
       6000-REGISTRAR-MOVIMIENTO.
           CALL 'MOVPOL' USING L-NUMERO-POLIZA
                               WS-NUEVA-POL-NUM
                               WS-RETURN-CODE.
