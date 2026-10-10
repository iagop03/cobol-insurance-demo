       IDENTIFICATION DIVISION.
       PROGRAM-ID. MOVPOL.
      *----------------------------------------------------------------*
      * MOVPOL  - Registro de movimientos de poliza                    *
      * Llama a: VALDAT                                                *
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
       01 WS-FUNCION-VALDAT      PIC X(1) VALUE '1'.
       01 WS-FECHA-HOY           PIC 9(8).
       01 WS-FECHA-AUX           PIC 9(8).
       01 WS-MESES-AUX           PIC S9(5) COMP VALUE 0.
       01 WS-COD-RETORNO-VALDAT  PIC S9(4) COMP VALUE 0.
       01 WS-NUEVO-MOV-ID        PIC 9(10).
      *
       01 DCLGEN-POLIZAS-MOV.
          05 HV-POL-NUMERO       PIC 9(8).
          05 HV-POL-ESTADO       PIC X(2).
          05 SQLCODE             PIC S9(9) COMP.
      *
       01 DCLGEN-MOVIMIENTOS.
          05 HV-MOV-ID           PIC 9(10).
          05 HV-MOV-POL-NUMERO   PIC 9(8).
          05 HV-MOV-TIPO         PIC X(3).
          05 HV-MOV-FECHA        PIC 9(8).
          05 HV-MOV-MONTO        PIC S9(9)V9(2) COMP-3.
          05 SQLCODE-MOV         PIC S9(9) COMP.
      *
       LINKAGE SECTION.
       01 L-POL-NUMERO           PIC 9(8).
       01 L-MONTO                PIC S9(9)V9(2) COMP-3.
       01 L-RETURN-CODE          PIC S9(4) COMP.
      *
       PROCEDURE DIVISION USING L-POL-NUMERO
                                 L-MONTO
                                 L-RETURN-CODE.
           MOVE 0 TO L-RETURN-CODE
           PERFORM 1000-VERIFICAR-POLIZA
           IF L-RETURN-CODE = 0
              PERFORM 2000-INSERTAR-MOVIMIENTO
           END-IF
           STOP RUN.
      *
       1000-VERIFICAR-POLIZA.
           MOVE L-POL-NUMERO TO HV-POL-NUMERO
           EXEC SQL
               SELECT POL_ESTADO
               INTO :HV-POL-ESTADO
               FROM POLIZAS
               WHERE POL_NUMERO = :HV-POL-NUMERO
           END-EXEC
           IF SQLCODE NOT = 0
              MOVE 10 TO L-RETURN-CODE
           END-IF.
      *
       2000-INSERTAR-MOVIMIENTO.
           EXEC SQL
               SELECT MAX(MOV_ID) + 1
               INTO :HV-MOV-ID
               FROM MOVIMIENTOS
           END-EXEC
           MOVE HV-MOV-ID TO WS-NUEVO-MOV-ID
           MOVE L-POL-NUMERO TO HV-MOV-POL-NUMERO
           MOVE 'EMI'        TO HV-MOV-TIPO
           MOVE L-MONTO      TO HV-MOV-MONTO
           EXEC SQL
               INSERT INTO MOVIMIENTOS
                   (MOV_ID, MOV_POL_NUMERO, MOV_TIPO,
                    MOV_FECHA, MOV_MONTO, MOV_ESTADO)
               VALUES
                   (:HV-MOV-ID, :HV-MOV-POL-NUMERO, :HV-MOV-TIPO,
                    CURRENT DATE, :HV-MOV-MONTO, 'A')
           END-EXEC
           IF SQLCODE-MOV NOT = 0
              MOVE 20 TO L-RETURN-CODE
           END-IF.
