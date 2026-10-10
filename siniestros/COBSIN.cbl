       IDENTIFICATION DIVISION.
       PROGRAM-ID. COBSIN.
      *----------------------------------------------------------------*
      * COBSIN  - Verificacion de cobertura para siniestros            *
      * Llama a: COBDEF GARDEF PRODDF                                  *
      *----------------------------------------------------------------*
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-MAINFRAME.
      *
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-RETURN-CODE         PIC S9(4) COMP VALUE 0.
       01 WS-LIMITE-COB          PIC S9(11)V9(2) COMP-3 VALUE 0.
       01 WS-CARENCIA-MESES      PIC 9(3) VALUE 0.
      *
       01 DCLGEN-COBERTURAS-SIN.
          05 HV-COB-CODIGO       PIC X(6).
          05 HV-COB-ACTIVA       PIC X(1).
          05 HV-COB-CAPITAL-MAX  PIC S9(11)V9(2) COMP-3.
          05 HV-COB-FRANQUICIA   PIC S9(9)V9(2) COMP-3.
          05 SQLCODE             PIC S9(9) COMP.
      *
       LINKAGE SECTION.
       01 L-PRODUCTO             PIC X(6).
       01 L-VERSION              PIC 9(3).
       01 L-COBERTURA            PIC X(6).
       01 L-ES-VALIDA            PIC X(1).
       01 L-RETURN-CODE          PIC S9(4) COMP.
      *
       PROCEDURE DIVISION USING L-PRODUCTO
                                 L-VERSION
                                 L-COBERTURA
                                 L-ES-VALIDA
                                 L-RETURN-CODE.
           MOVE 0 TO L-RETURN-CODE
           MOVE 'N' TO L-ES-VALIDA
           PERFORM 1000-VERIFICAR-COBERTURA-PRODUCTO
           IF L-RETURN-CODE = 0 AND L-ES-VALIDA = 'S'
              PERFORM 2000-OBTENER-GARANTIAS
           END-IF
           STOP RUN.
      *
       1000-VERIFICAR-COBERTURA-PRODUCTO.
           CALL 'COBDEF' USING L-PRODUCTO
                               L-VERSION
                               WS-RETURN-CODE
                               WS-RETURN-CODE
           MOVE L-COBERTURA TO HV-COB-CODIGO
           EXEC SQL
               SELECT COB_ACTIVA, COB_CAPITAL_MAX, COB_FRANQUICIA
               INTO :HV-COB-ACTIVA, :HV-COB-CAPITAL-MAX,
                    :HV-COB-FRANQUICIA
               FROM COBERTURAS
               WHERE COB_PRODUCTO = :L-PRODUCTO
                 AND COB_VERSION  = :L-VERSION
                 AND COB_CODIGO   = :HV-COB-CODIGO
           END-EXEC
           IF SQLCODE NOT = 0
              MOVE 10 TO L-RETURN-CODE
           ELSE IF HV-COB-ACTIVA = 'S'
              MOVE 'S' TO L-ES-VALIDA
              MOVE HV-COB-CAPITAL-MAX TO WS-LIMITE-COB
           END-IF.
      *
       2000-OBTENER-GARANTIAS.
           CALL 'GARDEF' USING L-PRODUCTO
                               L-COBERTURA
                               L-COBERTURA
                               WS-LIMITE-COB
                               WS-CARENCIA-MESES
                               WS-RETURN-CODE.
