      *----------------------------------------------------------------*
      * POLREC  - Registro de cabecera de poliza                       *
      *           Usado por: EMIPOL SUPLMT RENOVA ANULAN REHPOL        *
      *----------------------------------------------------------------*
       01 POLREC.
          05 POL-NUMERO          PIC 9(8).
          05 POL-CONTRATO        PIC 9(6).
          05 POL-PRODUCTO        PIC X(6).
          05 POL-VERSION-PROD    PIC 9(3).
          05 POL-FECHA-EFECT     PIC 9(8).
          05 POL-FECHA-VCTO      PIC 9(8).
          05 POL-FECHA-EMISION   PIC 9(8).
          05 POL-MESES-VENCIDA   PIC 9(3).
          05 POL-ESTADO          PIC X(2).
             88 POL-ACTIVA       VALUE 'AC'.
             88 POL-VENCIDA      VALUE 'VE'.
             88 POL-ANULADA      VALUE 'AN'.
             88 POL-REHABILITADA VALUE 'RH'.
             88 POL-SUSPENDIDA   VALUE 'SU'.
          05 POL-AGENTE          PIC 9(6).
          05 POL-TOMADOR         PIC 9(10).
          05 POL-PRIMA-NETA      PIC S9(9)V9(2) COMP-3.
          05 POL-PRIMA-TOTAL     PIC S9(9)V9(2) COMP-3.
          05 POL-RAMO            PIC X(4).
          05 POL-MODALIDAD       PIC X(3).
             88 POL-ANUAL        VALUE 'ANU'.
             88 POL-SEMESTRAL    VALUE 'SEM'.
             88 POL-MENSUAL      VALUE 'MEN'.
