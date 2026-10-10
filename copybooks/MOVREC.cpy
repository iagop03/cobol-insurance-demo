      *----------------------------------------------------------------*
      * MOVREC  - Registro de movimiento de poliza                     *
      *           Usado por: MOVPOL REHPOL ANULAN SUPLMT               *
      *----------------------------------------------------------------*
       01 MOVREC.
          05 MOV-ID              PIC 9(10).
          05 MOV-POL-NUMERO      PIC 9(8).
          05 MOV-TIPO            PIC X(3).
             88 MOV-PAGO         VALUE 'PAG'.
             88 MOV-CANCELACION  VALUE 'CAN'.
             88 MOV-REHABILITAC  VALUE 'RHB'.
             88 MOV-EMISION      VALUE 'EMI'.
             88 MOV-SUPLEMENTO   VALUE 'SUP'.
             88 MOV-RENOVACION   VALUE 'REN'.
             88 MOV-ANULACION    VALUE 'ANU'.
          05 MOV-FECHA           PIC 9(8).
          05 MOV-FECHA-EFECTO    PIC 9(8).
          05 MOV-MONTO           PIC S9(9)V9(2) COMP-3.
          05 MOV-MESES-AFECTADOS PIC 9(3).
          05 MOV-USUARIO         PIC X(12).
          05 MOV-ESTADO          PIC X(1).
             88 MOV-ACTIVO       VALUE 'A'.
             88 MOV-REVERTIDO    VALUE 'R'.
          05 MOV-REFERENCIA      PIC X(20).
