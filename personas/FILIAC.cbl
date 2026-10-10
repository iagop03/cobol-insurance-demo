       IDENTIFICATION DIVISION.
       PROGRAM-ID. FILIAC.
      *----------------------------------------------------------------*
      * FILIAC  - Gestion de codigos de filiacion (DNI/NIE/CIF/NIF)   *
      * Llama a: (ninguno — punto final)                               *
      *----------------------------------------------------------------*
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-MAINFRAME.
      *
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-RETURN-CODE         PIC S9(4) COMP VALUE 0.
       01 WS-LETRA-DNI           PIC X(1).
       01 WS-NUMERO-DNI          PIC 9(8).
       01 WS-TABLA-LETRAS        PIC X(23)
                                 VALUE 'TRWAGMYFPDXBNJZSQVHLCKE'.
       01 WS-RESTO               PIC 9(2).
      *
       01 DCLGEN-FILIACION.
          05 HV-FIL-PER-ID       PIC 9(10).
          05 HV-FIL-TIPO         PIC X(3).
          05 HV-FIL-NUMERO       PIC X(15).
          05 HV-FIL-VALIDADO     PIC X(1).
          05 SQLCODE             PIC S9(9) COMP.
      *
       LINKAGE SECTION.
       01 L-ID-PERSONA           PIC 9(10).
       01 L-TIPO-DOC             PIC X(3).
       01 L-NUM-DOC              PIC X(15).
       01 L-RETURN-CODE          PIC S9(4) COMP.
      *
       PROCEDURE DIVISION USING L-ID-PERSONA
                                 L-TIPO-DOC
                                 L-NUM-DOC
                                 L-RETURN-CODE.
           MOVE 0 TO L-RETURN-CODE
           EVALUATE L-TIPO-DOC
             WHEN 'DNI'
               PERFORM 1000-VALIDAR-DNI
             WHEN 'NIE'
               PERFORM 2000-VALIDAR-NIE
             WHEN 'CIF'
               PERFORM 3000-VALIDAR-CIF
             WHEN OTHER
               MOVE 0 TO L-RETURN-CODE
           END-EVALUATE
           IF L-RETURN-CODE = 0
              PERFORM 9000-REGISTRAR-FILIACION
           END-IF
           STOP RUN.
      *
       1000-VALIDAR-DNI.
           IF L-NUM-DOC(9:1) IS ALPHABETIC
              MOVE L-NUM-DOC(1:8) TO WS-NUMERO-DNI
              COMPUTE WS-RESTO = FUNCTION MOD(WS-NUMERO-DNI, 23) + 1
              MOVE WS-TABLA-LETRAS(WS-RESTO:1) TO WS-LETRA-DNI
              IF WS-LETRA-DNI NOT = L-NUM-DOC(9:1)
                 MOVE 10 TO L-RETURN-CODE
              END-IF
           ELSE
              MOVE 11 TO L-RETURN-CODE
           END-IF.
      *
       2000-VALIDAR-NIE.
           IF L-NUM-DOC(1:1) NOT = 'X' AND NOT = 'Y' AND NOT = 'Z'
              MOVE 20 TO L-RETURN-CODE
           END-IF.
      *
       3000-VALIDAR-CIF.
           IF L-NUM-DOC(1:1) IS ALPHABETIC
              MOVE 0 TO L-RETURN-CODE
           ELSE
              MOVE 30 TO L-RETURN-CODE
           END-IF.
      *
       9000-REGISTRAR-FILIACION.
           MOVE L-ID-PERSONA TO HV-FIL-PER-ID
           MOVE L-TIPO-DOC   TO HV-FIL-TIPO
           MOVE L-NUM-DOC    TO HV-FIL-NUMERO
           EXEC SQL
               INSERT INTO FILIACION
                   (FIL_PER_ID, FIL_TIPO, FIL_NUMERO, FIL_VALIDADO)
               VALUES
                   (:HV-FIL-PER-ID, :HV-FIL-TIPO,
                    :HV-FIL-NUMERO, 'S')
           END-EXEC
           IF SQLCODE NOT = 0 AND SQLCODE NOT = -803
              MOVE 90 TO L-RETURN-CODE
           END-IF.
