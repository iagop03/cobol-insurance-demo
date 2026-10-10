       IDENTIFICATION DIVISION.
       PROGRAM-ID. NEGDEF.
      *----------------------------------------------------------------*
      * NEGDEF  - Consulta y validacion de negocio/ramo                *
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
       01 DCLGEN-NEGOCIOS.
          05 HV-NEG-CONTRATO     PIC 9(6).
          05 HV-NEG-RAMO         PIC X(4).
          05 HV-NEG-DESCRIPCION  PIC X(80).
          05 HV-NEG-ESTADO       PIC X(1).
          05 HV-NEG-COMISION-PCT PIC S9(3)V9(4) COMP-3.
          05 SQLCODE             PIC S9(9) COMP.
      *
       01 DCLGEN-CONTRATOS.
          05 HV-CON-NUMERO       PIC 9(6).
          05 HV-CON-VIGENTE      PIC X(1).
          05 HV-CON-PROD-DEFECTO PIC X(6).
          05 SQLCODE-CON         PIC S9(9) COMP.
      *
       LINKAGE SECTION.
       01 L-CONTRATO             PIC 9(6).
       01 L-RAMO-SALIDA          PIC X(4).
       01 L-RETURN-CODE          PIC S9(4) COMP.
      *
       PROCEDURE DIVISION USING L-CONTRATO
                                 L-RAMO-SALIDA
                                 L-RETURN-CODE.
           MOVE 0 TO L-RETURN-CODE
           PERFORM 1000-VERIFICAR-CONTRATO
           IF L-RETURN-CODE = 0
              PERFORM 2000-OBTENER-RAMO
           END-IF
           STOP RUN.
      *
       1000-VERIFICAR-CONTRATO.
           MOVE L-CONTRATO TO HV-CON-NUMERO
           EXEC SQL
               SELECT CON_VIGENTE, CON_PROD_DEFECTO
               INTO :HV-CON-VIGENTE, :HV-CON-PROD-DEFECTO
               FROM CONTRATOS
               WHERE CON_NUMERO = :HV-CON-NUMERO
           END-EXEC
           IF SQLCODE NOT = 0
              MOVE 10 TO L-RETURN-CODE
           ELSE IF HV-CON-VIGENTE NOT = 'S'
              MOVE 11 TO L-RETURN-CODE
           END-IF.
      *
       2000-OBTENER-RAMO.
           EXEC SQL
               SELECT NEG_RAMO, NEG_DESCRIPCION
               INTO :HV-NEG-RAMO, :HV-NEG-DESCRIPCION
               FROM NEGOCIOS
               WHERE NEG_CONTRATO = :L-CONTRATO
                 AND NEG_ESTADO = 'A'
           END-EXEC
           IF SQLCODE NOT = 0
              MOVE 20 TO L-RETURN-CODE
           ELSE
              MOVE HV-NEG-RAMO TO L-RAMO-SALIDA
           END-IF.
