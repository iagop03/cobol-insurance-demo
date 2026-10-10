       IDENTIFICATION DIVISION.
       PROGRAM-ID. ROLES.
      *----------------------------------------------------------------*
      * ROLES   - Gestion de roles de personas en poliza               *
      *           (tomador, asegurado, beneficiario, pagador)          *
      * Llama a: PERSOM                                                *
      *----------------------------------------------------------------*
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-MAINFRAME.
      *
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY PERREC.
       01 WS-RETURN-CODE         PIC S9(4) COMP VALUE 0.
      *
       01 DCLGEN-ROLES-POLIZA.
          05 HV-ROL-POL-NUMERO   PIC 9(8).
          05 HV-ROL-PER-ID       PIC 9(10).
          05 HV-ROL-TIPO         PIC X(3).
          05 HV-ROL-PCT-BENEF    PIC S9(3)V9(2) COMP-3.
          05 HV-ROL-FECHA-ALTA   PIC 9(8).
          05 HV-ROL-FECHA-BAJA   PIC 9(8).
          05 HV-ROL-ESTADO       PIC X(1).
          05 SQLCODE             PIC S9(9) COMP.
      *
       LINKAGE SECTION.
       01 L-FUNCION              PIC X(1).
          88 L-ASIGNAR-ROL       VALUE 'A'.
          88 L-CONSULTAR-ROLES   VALUE 'C'.
          88 L-CAMBIAR-ROL       VALUE 'M'.
          88 L-QUITAR-ROL        VALUE 'Q'.
       01 L-POL-NUMERO           PIC 9(8).
       01 L-PER-ID               PIC 9(10).
       01 L-TIPO-ROL             PIC X(3).
          88 L-ROL-TOMADOR       VALUE 'TOM'.
          88 L-ROL-ASEGURADO     VALUE 'ASE'.
          88 L-ROL-BENEFICIARIO  VALUE 'BEN'.
          88 L-ROL-PAGADOR       VALUE 'PAG'.
       01 L-PCT-BENEFICIO        PIC S9(3)V9(2) COMP-3.
       01 L-RETURN-CODE          PIC S9(4) COMP.
      *
       PROCEDURE DIVISION USING L-FUNCION
                                 L-POL-NUMERO
                                 L-PER-ID
                                 L-TIPO-ROL
                                 L-PCT-BENEFICIO
                                 L-RETURN-CODE.
           MOVE 0 TO L-RETURN-CODE
           PERFORM 1000-VERIFICAR-PERSONA
           IF L-RETURN-CODE = 0
              EVALUATE TRUE
                WHEN L-ASIGNAR-ROL
                  PERFORM 2000-ASIGNAR-ROL
                WHEN L-CONSULTAR-ROLES
                  PERFORM 3000-CONSULTAR-ROLES
                WHEN L-CAMBIAR-ROL
                  PERFORM 4000-CAMBIAR-ROL
                WHEN L-QUITAR-ROL
                  PERFORM 5000-QUITAR-ROL
              END-EVALUATE
           END-IF
           STOP RUN.
      *
       1000-VERIFICAR-PERSONA.
           CALL 'PERSOM' USING 'C'
                               SPACES
                               SPACES
                               SPACES
                               SPACES
                               SPACES
                               ZEROES
                               L-PER-ID
                               WS-RETURN-CODE
           IF WS-RETURN-CODE NOT = 0
              MOVE 10 TO L-RETURN-CODE
           END-IF.
      *
       2000-ASIGNAR-ROL.
           EXEC SQL
               INSERT INTO ROLES_POLIZA
                   (ROL_POL_NUMERO, ROL_PER_ID, ROL_TIPO,
                    ROL_PCT_BENEF, ROL_FECHA_ALTA, ROL_ESTADO)
               VALUES
                   (:L-POL-NUMERO, :L-PER-ID, :L-TIPO-ROL,
                    :L-PCT-BENEFICIO, CURRENT DATE, 'A')
           END-EXEC
           IF SQLCODE NOT = 0
              MOVE 20 TO L-RETURN-CODE
           END-IF.
      *
       3000-CONSULTAR-ROLES.
           EXEC SQL
               SELECT COUNT(*)
               INTO :WS-RETURN-CODE
               FROM ROLES_POLIZA
               WHERE ROL_POL_NUMERO = :L-POL-NUMERO
                 AND ROL_ESTADO = 'A'
           END-EXEC.
      *
       4000-CAMBIAR-ROL.
           EXEC SQL
               UPDATE ROLES_POLIZA
               SET ROL_PER_ID    = :L-PER-ID,
                   ROL_PCT_BENEF = :L-PCT-BENEFICIO
               WHERE ROL_POL_NUMERO = :L-POL-NUMERO
                 AND ROL_TIPO       = :L-TIPO-ROL
                 AND ROL_ESTADO     = 'A'
           END-EXEC
           IF SQLCODE NOT = 0
              MOVE 40 TO L-RETURN-CODE
           END-IF.
      *
       5000-QUITAR-ROL.
           EXEC SQL
               UPDATE ROLES_POLIZA
               SET ROL_ESTADO    = 'B',
                   ROL_FECHA_BAJA = CURRENT DATE
               WHERE ROL_POL_NUMERO = :L-POL-NUMERO
                 AND ROL_PER_ID     = :L-PER-ID
                 AND ROL_TIPO       = :L-TIPO-ROL
           END-EXEC
           IF SQLCODE NOT = 0
              MOVE 50 TO L-RETURN-CODE
           END-IF.
