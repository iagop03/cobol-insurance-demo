      *----------------------------------------------------------------*
      * PRODREC - Registro de producto de seguro                       *
      *           Usado por: PRODDF CODPRD COBDEF TARIFA EMIPOL        *
      *----------------------------------------------------------------*
       01 PRODREC.
          05 PRD-CODIGO          PIC X(6).
          05 PRD-CODIGO-TECNICO  PIC X(10).
          05 PRD-CODIGO-COMERCIAL PIC X(10).
          05 PRD-NOMBRE          PIC X(80).
          05 PRD-NOMBRE-COMERCIAL PIC X(80).
          05 PRD-RAMO            PIC X(4).
          05 PRD-VERSION         PIC 9(3).
          05 PRD-FECHA-VIGENCIA  PIC 9(8).
          05 PRD-FECHA-FIN-VIG   PIC 9(8).
          05 PRD-ESTADO          PIC X(1).
             88 PRD-ACTIVO       VALUE 'A'.
             88 PRD-EN-DISENO    VALUE 'D'.
             88 PRD-RETIRADO     VALUE 'R'.
          05 PRD-PRIMA-MIN       PIC S9(7)V9(2) COMP-3.
          05 PRD-PRIMA-MAX       PIC S9(7)V9(2) COMP-3.
          05 PRD-COMISION-BASE   PIC S9(3)V9(4) COMP-3.
          05 PRD-MODALIDAD-DEF   PIC X(3).
          05 PRD-RENOVACION-AUTO PIC X(1).
             88 PRD-RENO-AUTO    VALUE 'S'.
             88 PRD-RENO-MANUAL  VALUE 'N'.
