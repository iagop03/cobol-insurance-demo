       IDENTIFICATION DIVISION.
       PROGRAM-ID. INTMED.
      *----------------------------------------------------------------*
      * INTMED  - Validacion y gestion de intermediarios/agentes       *
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
       01 DCLGEN-INTERMEDIARIOS.
          05 HV-INT-CODIGO       PIC 9(6).
          05 HV-INT-NOMBRE       PIC X(80).
          05 HV-INT-NIF          PIC X(15).
          05 HV-INT-ESTADO       PIC X(1).
          05 HV-INT-RAMO-AUTH    PIC X(4).
          05 HV-INT-COMISION-PCT PIC S9(3)V9(4) COMP-3.
          05 HV-INT-FECHA-ALTA   PIC 9(8).
          05 HV-INT-FECHA-BAJA   PIC 9(8).
          05 SQLCODE             PIC S9(9) COMP.
      *
       LINKAGE SECTION.
       01 L-CODIGO-AGENTE        PIC 9(6).
       01 L-RAMO-SOLICITUD       PIC X(4).
       01 L-RETURN-CODE          PIC S9(4) COMP.
      *
       PROCEDURE DIVISION USING L-CODIGO-AGENTE
                                 L-RAMO-SOLICITUD
                                 L-RETURN-CODE.
           MOVE 0 TO L-RETURN-CODE
           PERFORM 1000-VERIFICAR-AGENTE
           IF L-RETURN-CODE = 0
              PERFORM 2000-VERIFICAR-AUTORIZACION-RAMO
           END-IF
           STOP RUN.
      *
       1000-VERIFICAR-AGENTE.
           MOVE L-CODIGO-AGENTE TO HV-INT-CODIGO
           EXEC SQL
               SELECT INT_NOMBRE, INT_ESTADO,
                      INT_RAMO_AUTH, INT_COMISION_PCT
               INTO :HV-INT-NOMBRE, :HV-INT-ESTADO,
                    :HV-INT-RAMO-AUTH, :HV-INT-COMISION-PCT
               FROM INTERMEDIARIOS
               WHERE INT_CODIGO = :HV-INT-CODIGO
                 AND INT_ESTADO = 'A'
           END-EXEC
           IF SQLCODE NOT = 0
              MOVE 10 TO L-RETURN-CODE
           END-IF.
      *
       2000-VERIFICAR-AUTORIZACION-RAMO.
           IF HV-INT-RAMO-AUTH NOT = L-RAMO-SOLICITUD
              AND HV-INT-RAMO-AUTH NOT = 'TODOS'
              MOVE 20 TO L-RETURN-CODE
           END-IF.
