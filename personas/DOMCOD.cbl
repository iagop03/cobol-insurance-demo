       IDENTIFICATION DIVISION.
       PROGRAM-ID. DOMCOD.
      *----------------------------------------------------------------*
      * DOMCOD  - Gestion de domicilios de personas                    *
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
       01 DCLGEN-DOMICILIOS.
          05 HV-DOM-PER-ID       PIC 9(10).
          05 HV-DOM-TIPO         PIC X(3).
          05 HV-DOM-CALLE        PIC X(100).
          05 HV-DOM-NUMERO       PIC X(10).
          05 HV-DOM-PISO         PIC X(5).
          05 HV-DOM-CP           PIC X(10).
          05 HV-DOM-MUNICIPIO    PIC X(80).
          05 HV-DOM-PROVINCIA    PIC X(50).
          05 HV-DOM-PAIS         PIC X(3).
          05 HV-DOM-PRINCIPAL    PIC X(1).
          05 SQLCODE             PIC S9(9) COMP.
      *
       LINKAGE SECTION.
       01 L-FUNCION              PIC X(1).
          88 L-ALTA-DOM          VALUE 'A'.
          88 L-CONSULTA-DOM      VALUE 'C'.
          88 L-MODIFICA-DOM      VALUE 'M'.
       01 L-PER-ID               PIC 9(10).
       01 L-TIPO-DOM             PIC X(3).
       01 L-CALLE                PIC X(100).
       01 L-CP                   PIC X(10).
       01 L-MUNICIPIO            PIC X(80).
       01 L-PAIS                 PIC X(3).
       01 L-RETURN-CODE          PIC S9(4) COMP.
      *
       PROCEDURE DIVISION USING L-FUNCION
                                 L-PER-ID
                                 L-TIPO-DOM
                                 L-CALLE
                                 L-CP
                                 L-MUNICIPIO
                                 L-PAIS
                                 L-RETURN-CODE.
           MOVE 0 TO L-RETURN-CODE
           EVALUATE TRUE
             WHEN L-ALTA-DOM
               PERFORM 1000-ALTA-DOMICILIO
             WHEN L-CONSULTA-DOM
               PERFORM 2000-CONSULTAR-DOMICILIO
             WHEN L-MODIFICA-DOM
               PERFORM 3000-MODIFICAR-DOMICILIO
             WHEN OTHER
               MOVE 99 TO L-RETURN-CODE
           END-EVALUATE
           STOP RUN.
      *
       1000-ALTA-DOMICILIO.
           EXEC SQL
               INSERT INTO DOMICILIOS
                   (DOM_PER_ID, DOM_TIPO, DOM_CALLE,
                    DOM_CP, DOM_MUNICIPIO, DOM_PAIS,
                    DOM_PRINCIPAL, DOM_FECHA_ALTA)
               VALUES
                   (:L-PER-ID, :L-TIPO-DOM, :L-CALLE,
                    :L-CP, :L-MUNICIPIO, :L-PAIS,
                    'S', CURRENT DATE)
           END-EXEC
           IF SQLCODE NOT = 0
              MOVE 10 TO L-RETURN-CODE
           END-IF.
      *
       2000-CONSULTAR-DOMICILIO.
           EXEC SQL
               SELECT DOM_CALLE, DOM_CP, DOM_MUNICIPIO, DOM_PAIS
               INTO :HV-DOM-CALLE, :HV-DOM-CP,
                    :HV-DOM-MUNICIPIO, :HV-DOM-PAIS
               FROM DOMICILIOS
               WHERE DOM_PER_ID   = :L-PER-ID
                 AND DOM_TIPO     = :L-TIPO-DOM
                 AND DOM_PRINCIPAL = 'S'
           END-EXEC
           IF SQLCODE NOT = 0
              MOVE 20 TO L-RETURN-CODE
           ELSE
              MOVE HV-DOM-CALLE    TO L-CALLE
              MOVE HV-DOM-CP       TO L-CP
              MOVE HV-DOM-MUNICIPIO TO L-MUNICIPIO
              MOVE HV-DOM-PAIS     TO L-PAIS
           END-IF.
      *
       3000-MODIFICAR-DOMICILIO.
           EXEC SQL
               UPDATE DOMICILIOS
               SET DOM_CALLE     = :L-CALLE,
                   DOM_CP        = :L-CP,
                   DOM_MUNICIPIO = :L-MUNICIPIO,
                   DOM_PAIS      = :L-PAIS
               WHERE DOM_PER_ID = :L-PER-ID
                 AND DOM_TIPO   = :L-TIPO-DOM
           END-EXEC
           IF SQLCODE NOT = 0
              MOVE 30 TO L-RETURN-CODE
           END-IF.
