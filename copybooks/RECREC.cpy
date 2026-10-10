      *----------------------------------------------------------------*
      * RECREC  - Registro de recibo de prima                          *
      *           Usado por: GENREC COBRAN DEVOLU ESTARE LIQUID        *
      *----------------------------------------------------------------*
       01 RECREC.
          05 REC-ID              PIC 9(10).
          05 REC-POL-NUMERO      PIC 9(8).
          05 REC-NUMERO-ORDEN    PIC 9(4).
          05 REC-FECHA-EMISION   PIC 9(8).
          05 REC-FECHA-VENC      PIC 9(8).
          05 REC-FECHA-COBRO     PIC 9(8).
          05 REC-IMPORTE-NETO    PIC S9(9)V9(2) COMP-3.
          05 REC-IMPORTE-RECARGO PIC S9(9)V9(2) COMP-3.
          05 REC-IMPORTE-TOTAL   PIC S9(9)V9(2) COMP-3.
          05 REC-ESTADO          PIC X(2).
             88 REC-PENDIENTE    VALUE 'PE'.
             88 REC-COBRADO      VALUE 'CO'.
             88 REC-DEVUELTO     VALUE 'DE'.
             88 REC-ANULADO      VALUE 'AN'.
             88 REC-FRACCIONADO  VALUE 'FR'.
          05 REC-AGENTE          PIC 9(6).
          05 REC-COMISION-PCT    PIC S9(3)V9(4) COMP-3.
          05 REC-COMISION-IMP    PIC S9(9)V9(2) COMP-3.
          05 REC-CONCEPTO        PIC X(50).
          05 REC-BANCO           PIC X(20).
          05 REC-CUENTA          PIC X(24).
