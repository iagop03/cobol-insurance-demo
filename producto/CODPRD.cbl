       IDENTIFICATION DIVISION.
       PROGRAM-ID. CODPRD.
      *----------------------------------------------------------------*
      * CODPRD  - Gestion de codigos de producto tecnico y comercial   *
      * Llama a: (ninguno — punto final)                               *
      *----------------------------------------------------------------*
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-MAINFRAME.
      *
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY PRODREC.
       01 WS-RETURN-CODE         PIC S9(4) COMP VALUE 0.
      *
       01 DCLGEN-PRODUCTOS-COD.
          05 HV-PRD-CODIGO-TEC   PIC X(10).
          05 HV-PRD-CODIGO-COM   PIC X(10).
          05 HV-PRD-CODIGO-INT   PIC X(6).
          05 SQLCODE             PIC S9(9) COMP.
      *
       LINKAGE SECTION.
       01 L-FUNCION              PIC X(1).
          88 L-BUSCAR-POR-TEC    VALUE '1'.
          88 L-BUSCAR-POR-COM    VALUE '2'.
          88 L-REGISTRAR         VALUE '3'.
       01 L-CODIGO-ENTRADA       PIC X(10).
       01 L-CODIGO-INTERNO       PIC X(6).
       01 L-CODIGO-TECNICO       PIC X(10).
       01 L-CODIGO-COMERCIAL     PIC X(10).
       01 L-RETURN-CODE          PIC S9(4) COMP.
      *
       PROCEDURE DIVISION USING L-FUNCION
                                 L-CODIGO-ENTRADA
                                 L-CODIGO-INTERNO
                                 L-CODIGO-TECNICO
                                 L-CODIGO-COMERCIAL
                                 L-RETURN-CODE.
           MOVE 0 TO L-RETURN-CODE
           EVALUATE TRUE
             WHEN L-BUSCAR-POR-TEC
               PERFORM 1000-BUSCAR-POR-TECNICO
             WHEN L-BUSCAR-POR-COM
               PERFORM 2000-BUSCAR-POR-COMERCIAL
             WHEN L-REGISTRAR
               PERFORM 3000-REGISTRAR-CODIGO
             WHEN OTHER
               MOVE 99 TO L-RETURN-CODE
           END-EVALUATE
           STOP RUN.
      *
       1000-BUSCAR-POR-TECNICO.
           MOVE L-CODIGO-ENTRADA TO HV-PRD-CODIGO-TEC
           EXEC SQL
               SELECT PRD_CODIGO, PRD_CODIGO_COM
               INTO :HV-PRD-CODIGO-INT, :HV-PRD-CODIGO-COM
               FROM PRODUCTOS
               WHERE PRD_CODIGO_TEC = :HV-PRD-CODIGO-TEC
                 AND PRD_ESTADO = 'A'
           END-EXEC
           IF SQLCODE NOT = 0
              MOVE 10 TO L-RETURN-CODE
           ELSE
              MOVE HV-PRD-CODIGO-INT TO L-CODIGO-INTERNO
              MOVE HV-PRD-CODIGO-COM TO L-CODIGO-COMERCIAL
           END-IF.
      *
       2000-BUSCAR-POR-COMERCIAL.
           MOVE L-CODIGO-ENTRADA TO HV-PRD-CODIGO-COM
           EXEC SQL
               SELECT PRD_CODIGO, PRD_CODIGO_TEC
               INTO :HV-PRD-CODIGO-INT, :HV-PRD-CODIGO-TEC
               FROM PRODUCTOS
               WHERE PRD_CODIGO_COM = :HV-PRD-CODIGO-COM
                 AND PRD_ESTADO = 'A'
           END-EXEC
           IF SQLCODE NOT = 0
              MOVE 10 TO L-RETURN-CODE
           ELSE
              MOVE HV-PRD-CODIGO-INT TO L-CODIGO-INTERNO
              MOVE HV-PRD-CODIGO-TEC TO L-CODIGO-TECNICO
           END-IF.
      *
       3000-REGISTRAR-CODIGO.
           EXEC SQL
               UPDATE PRODUCTOS
               SET PRD_CODIGO_TEC = :L-CODIGO-TECNICO,
                   PRD_CODIGO_COM = :L-CODIGO-COMERCIAL
               WHERE PRD_CODIGO = :L-CODIGO-INTERNO
           END-EXEC
           IF SQLCODE NOT = 0
              MOVE 30 TO L-RETURN-CODE
           END-IF.
