       IDENTIFICATION DIVISION.
       PROGRAM-ID. PERSOM.
      *----------------------------------------------------------------*
      * PERSOM  - Maestro de personas fisicas y juridicas              *
      * Llama a: FILIAC DOMCOD VALDAT                                  *
      *----------------------------------------------------------------*
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-MAINFRAME.
      *
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY PERREC.
       01 WS-RETURN-CODE         PIC S9(4) COMP VALUE 0.
       01 WS-NUEVO-PER-ID        PIC 9(10) VALUE 0.
       01 WS-FUNCION-VALDAT      PIC X(1).
       01 WS-FECHA-AUX           PIC 9(8).
       01 WS-MESES-AUX           PIC S9(5) COMP VALUE 0.
       01 WS-COD-RETORNO-VALDAT  PIC S9(4) COMP VALUE 0.
      *
       01 DCLGEN-PERSONAS.
          05 HV-PER-ID           PIC 9(10).
          05 HV-PER-TIPO-DOC     PIC X(3).
          05 HV-PER-NUM-DOC      PIC X(15).
          05 HV-PER-NOMBRE       PIC X(50).
          05 HV-PER-APELLIDO1    PIC X(50).
          05 HV-PER-FECHA-NACIM  PIC 9(8).
          05 HV-PER-ESTADO       PIC X(1).
          05 SQLCODE             PIC S9(9) COMP.
      *
       LINKAGE SECTION.
       01 L-FUNCION              PIC X(1).
          88 L-ALTA              VALUE 'A'.
          88 L-CONSULTA          VALUE 'C'.
          88 L-MODIFICACION      VALUE 'M'.
          88 L-BAJA              VALUE 'B'.
       01 L-TIPO-DOC             PIC X(3).
       01 L-NUM-DOC              PIC X(15).
       01 L-NOMBRE               PIC X(50).
       01 L-APELLIDO1            PIC X(50).
       01 L-APELLIDO2            PIC X(50).
       01 L-FECHA-NACIM          PIC 9(8).
       01 L-ID-PERSONA           PIC 9(10).
       01 L-RETURN-CODE          PIC S9(4) COMP.
      *
       PROCEDURE DIVISION USING L-FUNCION
                                 L-TIPO-DOC
                                 L-NUM-DOC
                                 L-NOMBRE
                                 L-APELLIDO1
                                 L-APELLIDO2
                                 L-FECHA-NACIM
                                 L-ID-PERSONA
                                 L-RETURN-CODE.
           MOVE 0 TO L-RETURN-CODE
           EVALUATE TRUE
             WHEN L-ALTA
               PERFORM 1000-ALTA-PERSONA
             WHEN L-CONSULTA
               PERFORM 2000-CONSULTAR-PERSONA
             WHEN L-MODIFICACION
               PERFORM 3000-MODIFICAR-PERSONA
             WHEN L-BAJA
               PERFORM 4000-BAJA-PERSONA
             WHEN OTHER
               MOVE 99 TO L-RETURN-CODE
           END-EVALUATE
           STOP RUN.
      *
       1000-ALTA-PERSONA.
           PERFORM 1100-VERIFICAR-DUPLICADO
           IF L-RETURN-CODE = 0
              PERFORM 1200-INSERTAR-PERSONA
           END-IF
           IF L-RETURN-CODE = 0
              CALL 'FILIAC' USING L-ID-PERSONA
                                  L-TIPO-DOC
                                  L-NUM-DOC
                                  WS-RETURN-CODE
           END-IF.
      *
       1100-VERIFICAR-DUPLICADO.
           EXEC SQL
               SELECT PER_ID
               INTO :HV-PER-ID
               FROM PERSONAS
               WHERE PER_TIPO_DOC = :L-TIPO-DOC
                 AND PER_NUM_DOC  = :L-NUM-DOC
                 AND PER_ESTADO   = 'A'
           END-EXEC
           IF SQLCODE = 0
              MOVE HV-PER-ID TO L-ID-PERSONA
              MOVE 11 TO L-RETURN-CODE
           END-IF.
      *
       1200-INSERTAR-PERSONA.
           EXEC SQL
               SELECT MAX(PER_ID) + 1
               INTO :HV-PER-ID
               FROM PERSONAS
           END-EXEC
           EXEC SQL
               INSERT INTO PERSONAS
                   (PER_ID, PER_TIPO_DOC, PER_NUM_DOC,
                    PER_NOMBRE, PER_APELLIDO1, PER_APELLIDO2,
                    PER_FECHA_NACIM, PER_ESTADO)
               VALUES
                   (:HV-PER-ID, :L-TIPO-DOC, :L-NUM-DOC,
                    :L-NOMBRE, :L-APELLIDO1, :L-APELLIDO2,
                    :L-FECHA-NACIM, 'A')
           END-EXEC
           IF SQLCODE NOT = 0
              MOVE 20 TO L-RETURN-CODE
           ELSE
              MOVE HV-PER-ID TO L-ID-PERSONA
           END-IF.
      *
       2000-CONSULTAR-PERSONA.
           EXEC SQL
               SELECT PER_TIPO_DOC, PER_NUM_DOC,
                      PER_NOMBRE, PER_APELLIDO1,
                      PER_FECHA_NACIM, PER_ESTADO
               INTO :HV-PER-TIPO-DOC, :HV-PER-NUM-DOC,
                    :HV-PER-NOMBRE, :HV-PER-APELLIDO1,
                    :HV-PER-FECHA-NACIM, :HV-PER-ESTADO
               FROM PERSONAS
               WHERE PER_ID = :L-ID-PERSONA
           END-EXEC
           IF SQLCODE NOT = 0
              MOVE 10 TO L-RETURN-CODE
           END-IF.
      *
       3000-MODIFICAR-PERSONA.
           EXEC SQL
               UPDATE PERSONAS
               SET PER_NOMBRE    = :L-NOMBRE,
                   PER_APELLIDO1 = :L-APELLIDO1,
                   PER_APELLIDO2 = :L-APELLIDO2
               WHERE PER_ID = :L-ID-PERSONA
           END-EXEC
           IF SQLCODE NOT = 0
              MOVE 30 TO L-RETURN-CODE
           END-IF.
      *
       4000-BAJA-PERSONA.
           EXEC SQL
               UPDATE PERSONAS
               SET PER_ESTADO = 'I'
               WHERE PER_ID = :L-ID-PERSONA
           END-EXEC
           IF SQLCODE NOT = 0
              MOVE 40 TO L-RETURN-CODE
           END-IF.
