      *----------------------------------------------------------------*
      * SINREC  - Registro de siniestro                                *
      *           Usado por: SINREG COBSIN PAGSIN VALSIN               *
      *----------------------------------------------------------------*
       01 SINREC.
          05 SIN-ID              PIC 9(10).
          05 SIN-POL-NUMERO      PIC 9(8).
          05 SIN-FECHA-OCURR     PIC 9(8).
          05 SIN-FECHA-DECLAR    PIC 9(8).
          05 SIN-FECHA-CIERRE    PIC 9(8).
          05 SIN-COBERTURA       PIC X(6).
          05 SIN-GARANTIA        PIC X(6).
          05 SIN-IMPORTE-DECL    PIC S9(9)V9(2) COMP-3.
          05 SIN-IMPORTE-RESERVA PIC S9(9)V9(2) COMP-3.
          05 SIN-IMPORTE-PAGADO  PIC S9(9)V9(2) COMP-3.
          05 SIN-ESTADO          PIC X(2).
             88 SIN-ABIERTO      VALUE 'AB'.
             88 SIN-EN-TRAMITE   VALUE 'TR'.
             88 SIN-CERRADO      VALUE 'CE'.
             88 SIN-RECHAZADO    VALUE 'RE'.
             88 SIN-PAGADO       VALUE 'PA'.
          05 SIN-CODIGO-CAUSA    PIC X(4).
          05 SIN-DESCRIPCION     PIC X(100).
          05 SIN-PERITO          PIC 9(10).
          05 SIN-BENEFICIARIO    PIC 9(10).
