       IDENTIFICATION DIVISION.
       PROGRAM-ID. GARDEF.
      *----------------------------------------------------------------*
      * GARDEF  - Definicion y consulta de garantias de producto       *
      * Llama a: (ninguno — punto final)                               *
      *----------------------------------------------------------------*
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-MAINFRAME.
      *
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-RETURN-CODE         PIC S9(4) COMP VALUE 0.
      *
       01 DCLGEN-GARANTIAS.
          05 HV-GAR-CODIGO       PIC X(6).
          05 HV-GAR-PRODUCTO     PIC X(6).
          05 HV-GAR-COBERTURA    PIC X(6).
          05 HV-GAR-NOMBRE       PIC X(80).
          05 HV-GAR-LIMITE       PIC S9(11)V9(2) COMP-3.
          05 HV-GAR-CARENCIA     PIC 9(3).
          05 HV-GAR-EXCLUSIONES  PIC X(200).
          05 SQLCODE             PIC S9(9) COMP.
      *
       LINKAGE SECTION.
       01 L-CODIGO-PRODUCTO      PIC X(6).
       01 L-CODIGO-COBERTURA     PIC X(6).
       01 L-CODIGO-GARANTIA      PIC X(6).
       01 L-LIMITE-GARANTIA      PIC S9(11)V9(2) COMP-3.
       01 L-CARENCIA-MESES       PIC 9(3).
       01 L-RETURN-CODE          PIC S9(4) COMP.
      *
       PROCEDURE DIVISION USING L-CODIGO-PRODUCTO
                                 L-CODIGO-COBERTURA
                                 L-CODIGO-GARANTIA
                                 L-LIMITE-GARANTIA
                                 L-CARENCIA-MESES
                                 L-RETURN-CODE.
           MOVE 0 TO L-RETURN-CODE
           PERFORM 1000-BUSCAR-GARANTIA
           STOP RUN.
      *
       1000-BUSCAR-GARANTIA.
           EXEC SQL
               SELECT GAR_CODIGO, GAR_NOMBRE,
                      GAR_LIMITE, GAR_CARENCIA
               INTO :HV-GAR-CODIGO, :HV-GAR-NOMBRE,
                    :HV-GAR-LIMITE, :HV-GAR-CARENCIA
               FROM GARANTIAS
               WHERE GAR_PRODUCTO  = :L-CODIGO-PRODUCTO
                 AND GAR_COBERTURA = :L-CODIGO-COBERTURA
                 AND GAR_CODIGO    = :L-CODIGO-GARANTIA
                 AND GAR_ACTIVA    = 'S'
           END-EXEC
           IF SQLCODE NOT = 0
              MOVE 10 TO L-RETURN-CODE
           ELSE
              MOVE HV-GAR-LIMITE   TO L-LIMITE-GARANTIA
              MOVE HV-GAR-CARENCIA TO L-CARENCIA-MESES
           END-IF.
