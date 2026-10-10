      *----------------------------------------------------------------*
      * PERREC  - Registro de persona fisica o juridica                *
      *           Usado por: PERSOM FILIAC ROLES DOMCOD RELPER         *
      *----------------------------------------------------------------*
       01 PERREC.
          05 PER-ID              PIC 9(10).
          05 PER-TIPO-DOC        PIC X(3).
             88 PER-DNI          VALUE 'DNI'.
             88 PER-NIE          VALUE 'NIE'.
             88 PER-CIF          VALUE 'CIF'.
             88 PER-PAS          VALUE 'PAS'.
             88 PER-NIF          VALUE 'NIF'.
          05 PER-NUM-DOC         PIC X(15).
          05 PER-NOMBRE          PIC X(50).
          05 PER-APELLIDO1       PIC X(50).
          05 PER-APELLIDO2       PIC X(50).
          05 PER-FECHA-NACIM     PIC 9(8).
          05 PER-NACIONALIDAD    PIC X(3).
          05 PER-SEXO            PIC X(1).
             88 PER-MASCULINO    VALUE 'M'.
             88 PER-FEMENINO     VALUE 'F'.
             88 PER-JURIDICA     VALUE 'J'.
          05 PER-TELEFONO        PIC X(15).
          05 PER-MOVIL           PIC X(15).
          05 PER-EMAIL           PIC X(80).
          05 PER-ESTADO          PIC X(1).
             88 PER-ACTIVO       VALUE 'A'.
             88 PER-INACTIVO     VALUE 'I'.
             88 PER-FALLECIDO    VALUE 'F'.
