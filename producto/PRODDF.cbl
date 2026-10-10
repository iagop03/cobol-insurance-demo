       IDENTIFICATION DIVISION.
       PROGRAM-ID. PRODDF.
      *----------------------------------------------------------------*
      * PRODDF  - Definicion y consulta de producto de seguro          *
      * Llama a: COBDEF GARDEF                                         *
      *----------------------------------------------------------------*
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-MAINFRAME.
      *
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY PRODREC.
       01 WS-RETURN-CODE         PIC S9(4) COMP VALUE 0.
       01 WS-NUM-COBERTURAS      PIC 9(3) VALUE 0.
       01 WS-NUM-GARANTIAS       PIC 9(3) VALUE 0.
      *
       01 DCLGEN-PRODUCTOS.
          05 HV-PRD-CODIGO       PIC X(6).
          05 HV-PRD-NOMBRE       PIC X(80).
          05 HV-PRD-RAMO         PIC X(4).
          05 HV-PRD-ESTADO       PIC X(1).
          05 HV-PRD-VERSION      PIC 9(3).
          05 HV-PRD-PRIMA-MIN    PIC S9(7)V9(2) COMP-3.
          05 HV-PRD-PRIMA-MAX    PIC S9(7)V9(2) COMP-3.
          05 HV-PRD-COMISION     PIC S9(3)V9(4) COMP-3.
          05 SQLCODE             PIC S9(9) COMP.
      *
       LINKAGE SECTION.
       01 L-CODIGO-PRODUCTO      PIC X(6).
       01 L-VERSION              PIC 9(3).
       01 L-NOMBRE-PRODUCTO      PIC X(80).
       01 L-RAMO                 PIC X(4).
       01 L-PRIMA-MIN            PIC S9(7)V9(2) COMP-3.
       01 L-PRIMA-MAX            PIC S9(7)V9(2) COMP-3.
       01 L-RETURN-CODE          PIC S9(4) COMP.
      *
       PROCEDURE DIVISION USING L-CODIGO-PRODUCTO
                                 L-VERSION
                                 L-NOMBRE-PRODUCTO
                                 L-RAMO
                                 L-PRIMA-MIN
                                 L-PRIMA-MAX
                                 L-RETURN-CODE.
           MOVE 0 TO L-RETURN-CODE
           PERFORM 1000-BUSCAR-PRODUCTO
           IF L-RETURN-CODE = 0
              PERFORM 2000-OBTENER-COBERTURAS
           END-IF
           STOP RUN.
      *
       1000-BUSCAR-PRODUCTO.
           MOVE L-CODIGO-PRODUCTO TO HV-PRD-CODIGO
           EVALUATE TRUE
             WHEN L-VERSION = 0
               EXEC SQL
                   SELECT PRD_CODIGO, PRD_NOMBRE, PRD_RAMO,
                          PRD_ESTADO, PRD_VERSION,
                          PRD_PRIMA_MIN, PRD_PRIMA_MAX, PRD_COMISION
                   INTO :HV-PRD-CODIGO, :HV-PRD-NOMBRE, :HV-PRD-RAMO,
                        :HV-PRD-ESTADO, :HV-PRD-VERSION,
                        :HV-PRD-PRIMA-MIN, :HV-PRD-PRIMA-MAX,
                        :HV-PRD-COMISION
                   FROM PRODUCTOS
                   WHERE PRD_CODIGO = :HV-PRD-CODIGO
                     AND PRD_ESTADO = 'A'
                   ORDER BY PRD_VERSION DESC
                   FETCH FIRST 1 ROW ONLY
               END-EXEC
             WHEN OTHER
               EXEC SQL
                   SELECT PRD_CODIGO, PRD_NOMBRE, PRD_RAMO,
                          PRD_ESTADO, PRD_VERSION,
                          PRD_PRIMA_MIN, PRD_PRIMA_MAX, PRD_COMISION
                   INTO :HV-PRD-CODIGO, :HV-PRD-NOMBRE, :HV-PRD-RAMO,
                        :HV-PRD-ESTADO, :HV-PRD-VERSION,
                        :HV-PRD-PRIMA-MIN, :HV-PRD-PRIMA-MAX,
                        :HV-PRD-COMISION
                   FROM PRODUCTOS
                   WHERE PRD_CODIGO = :HV-PRD-CODIGO
                     AND PRD_VERSION = :L-VERSION
               END-EXEC
           END-EVALUATE
           IF SQLCODE NOT = 0
              MOVE 10 TO L-RETURN-CODE
           ELSE
              MOVE HV-PRD-NOMBRE    TO L-NOMBRE-PRODUCTO
              MOVE HV-PRD-RAMO      TO L-RAMO
              MOVE HV-PRD-PRIMA-MIN TO L-PRIMA-MIN
              MOVE HV-PRD-PRIMA-MAX TO L-PRIMA-MAX
           END-IF.
      *
       2000-OBTENER-COBERTURAS.
           CALL 'COBDEF' USING L-CODIGO-PRODUCTO
                               L-VERSION
                               WS-NUM-COBERTURAS
                               WS-RETURN-CODE.
