       IDENTIFICATION DIVISION.
       PROGRAM-ID. RELPER.
      *----------------------------------------------------------------*
      * RELPER  - Relaciones entre personas (parentesco, beneficiarios)*
      * Llama a: PERSOM                                                *
      *----------------------------------------------------------------*
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-MAINFRAME.
      *
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-RETURN-CODE         PIC S9(4) COMP VALUE 0.
      *
       01 DCLGEN-RELACIONES.
          05 HV-REL-PER-ID-ORIG  PIC 9(10).
          05 HV-REL-PER-ID-DEST  PIC 9(10).
          05 HV-REL-TIPO         PIC X(5).
          05 HV-REL-PARENTESCO   PIC X(20).
          05 HV-REL-FECHA        PIC 9(8).
          05 HV-REL-ESTADO       PIC X(1).
          05 SQLCODE             PIC S9(9) COMP.
      *
       LINKAGE SECTION.
       01 L-PER-ID-ORIGEN        PIC 9(10).
       01 L-PER-ID-DESTINO       PIC 9(10).
       01 L-TIPO-RELACION        PIC X(5).
       01 L-PARENTESCO           PIC X(20).
       01 L-RETURN-CODE          PIC S9(4) COMP.
      *
       PROCEDURE DIVISION USING L-PER-ID-ORIGEN
                                 L-PER-ID-DESTINO
                                 L-TIPO-RELACION
                                 L-PARENTESCO
                                 L-RETURN-CODE.
           MOVE 0 TO L-RETURN-CODE
           PERFORM 1000-VERIFICAR-PERSONAS
           IF L-RETURN-CODE = 0
              PERFORM 2000-REGISTRAR-RELACION
           END-IF
           STOP RUN.
      *
       1000-VERIFICAR-PERSONAS.
           CALL 'PERSOM' USING 'C' SPACES SPACES SPACES SPACES SPACES
                               ZEROES L-PER-ID-ORIGEN WS-RETURN-CODE
           IF WS-RETURN-CODE NOT = 0
              MOVE 10 TO L-RETURN-CODE
           END-IF.
      *
       2000-REGISTRAR-RELACION.
           EXEC SQL
               INSERT INTO RELACIONES_PERSONAS
                   (REL_PER_ID_ORIG, REL_PER_ID_DEST,
                    REL_TIPO, REL_PARENTESCO,
                    REL_FECHA, REL_ESTADO)
               VALUES
                   (:L-PER-ID-ORIGEN, :L-PER-ID-DESTINO,
                    :L-TIPO-RELACION, :L-PARENTESCO,
                    CURRENT DATE, 'A')
           END-EXEC
           IF SQLCODE NOT = 0 AND SQLCODE NOT = -803
              MOVE 20 TO L-RETURN-CODE
           END-IF.
