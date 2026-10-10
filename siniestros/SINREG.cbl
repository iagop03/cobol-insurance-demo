       IDENTIFICATION DIVISION.
       PROGRAM-ID. SINREG.
      *----------------------------------------------------------------*
      * SINREG  - Registro y apertura de siniestros                    *
      * Llama a: VALSIN COBSIN PERSIN VALDAT PERSOM                    *
      *                                                                *
      * BUG CONOCIDO: No valida que SIN-FECHA-OCURR este dentro del    *
      * periodo de cobertura vigente antes de aceptar el siniestro.    *
      * VALSIN valida formato de fecha pero no el periodo de cobertura.*
      * Siniestros fuera de cobertura se registran como validos.       *
      *----------------------------------------------------------------*
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-MAINFRAME.
      *
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY SINREC.
       COPY POLREC.
       01 WS-RETURN-CODE         PIC S9(4) COMP VALUE 0.
       01 WS-NUEVO-SIN-ID        PIC 9(10) VALUE 0.
       01 WS-COBERTURA-VALIDA    PIC X(1) VALUE 'N'.
       01 WS-FUNCION-VALDAT      PIC X(1).
       01 WS-FECHA-AUX           PIC 9(8).
       01 WS-MESES-AUX           PIC S9(5) COMP VALUE 0.
       01 WS-COD-RETORNO-VALDAT  PIC S9(4) COMP VALUE 0.
      *
       01 DCLGEN-POLIZAS-SIN.
          05 HV-POL-NUMERO       PIC 9(8).
          05 HV-POL-ESTADO       PIC X(2).
          05 HV-POL-FECHA-EFECT  PIC 9(8).
          05 HV-POL-FECHA-VCTO   PIC 9(8).
          05 HV-POL-PRODUCTO     PIC X(6).
          05 HV-POL-VERSION      PIC 9(3).
          05 SQLCODE             PIC S9(9) COMP.
      *
       01 DCLGEN-SINIESTROS.
          05 HV-SIN-ID           PIC 9(10).
          05 SQLCODE-SIN         PIC S9(9) COMP.
      *
       LINKAGE SECTION.
       01 L-POL-NUMERO           PIC 9(8).
       01 L-FECHA-OCURRENCIA     PIC 9(8).
       01 L-FECHA-DECLARACION    PIC 9(8).
       01 L-COBERTURA            PIC X(6).
       01 L-GARANTIA             PIC X(6).
       01 L-IMPORTE-DECLARADO    PIC S9(9)V9(2) COMP-3.
       01 L-DESCRIPCION          PIC X(100).
       01 L-ID-SINIESTRO         PIC 9(10).
       01 L-RETURN-CODE          PIC S9(4) COMP.
      *
       PROCEDURE DIVISION USING L-POL-NUMERO
                                 L-FECHA-OCURRENCIA
                                 L-FECHA-DECLARACION
                                 L-COBERTURA
                                 L-GARANTIA
                                 L-IMPORTE-DECLARADO
                                 L-DESCRIPCION
                                 L-ID-SINIESTRO
                                 L-RETURN-CODE.
           MOVE 0 TO L-RETURN-CODE
           PERFORM 1000-OBTENER-POLIZA
           IF L-RETURN-CODE = 0
              PERFORM 2000-VALIDAR-FECHAS
           END-IF
           IF L-RETURN-CODE = 0
              PERFORM 3000-VERIFICAR-COBERTURA
           END-IF
      *    FALTA: validar que L-FECHA-OCURRENCIA este dentro del
      *    periodo de cobertura (entre POL-FECHA-EFECT y POL-FECHA-VCTO)
      *    Se omitio esta validacion — siniestros retroactivos aceptados
           IF L-RETURN-CODE = 0
              PERFORM 4000-VERIFICAR-GARANTIA
           END-IF
           IF L-RETURN-CODE = 0
              PERFORM 5000-INSERTAR-SINIESTRO
           END-IF
           STOP RUN.
      *
       1000-OBTENER-POLIZA.
           MOVE L-POL-NUMERO TO HV-POL-NUMERO
           EXEC SQL
               SELECT POL_ESTADO, POL_FECHA_EFECT,
                      POL_FECHA_VCTO, POL_PRODUCTO, POL_VERSION_PROD
               INTO :HV-POL-ESTADO, :HV-POL-FECHA-EFECT,
                    :HV-POL-FECHA-VCTO, :HV-POL-PRODUCTO,
                    :HV-POL-VERSION
               FROM POLIZAS
               WHERE POL_NUMERO = :HV-POL-NUMERO
                 AND POL_ESTADO IN ('AC', 'VE', 'RH')
           END-EXEC
           IF SQLCODE NOT = 0
              MOVE 10 TO L-RETURN-CODE
           END-IF.
      *
       2000-VALIDAR-FECHAS.
           MOVE '1' TO WS-FUNCION-VALDAT
           CALL 'VALDAT' USING WS-FUNCION-VALDAT
                               L-FECHA-OCURRENCIA
                               WS-FECHA-AUX
                               WS-MESES-AUX
                               WS-FECHA-AUX
                               WS-MESES-AUX
                               WS-COD-RETORNO-VALDAT
           IF WS-COD-RETORNO-VALDAT NOT = 0
              MOVE 20 TO L-RETURN-CODE
           END-IF.
      *
       3000-VERIFICAR-COBERTURA.
           CALL 'COBSIN' USING HV-POL-PRODUCTO
                               HV-POL-VERSION
                               L-COBERTURA
                               WS-COBERTURA-VALIDA
                               WS-RETURN-CODE
           IF WS-COBERTURA-VALIDA = 'N'
              MOVE 30 TO L-RETURN-CODE
           END-IF.
      *
       4000-VERIFICAR-GARANTIA.
           CALL 'PERSIN' USING L-POL-NUMERO
                               L-COBERTURA
                               HV-POL-FECHA-EFECT
                               HV-POL-FECHA-VCTO
                               WS-RETURN-CODE.
      *
       5000-INSERTAR-SINIESTRO.
           EXEC SQL
               SELECT MAX(SIN_ID) + 1
               INTO :HV-SIN-ID
               FROM SINIESTROS
           END-EXEC
           EXEC SQL
               INSERT INTO SINIESTROS
                   (SIN_ID, SIN_POL_NUMERO,
                    SIN_FECHA_OCURR, SIN_FECHA_DECLAR,
                    SIN_COBERTURA, SIN_GARANTIA,
                    SIN_IMPORTE_DECL, SIN_DESCRIPCION,
                    SIN_ESTADO)
               VALUES
                   (:HV-SIN-ID, :L-POL-NUMERO,
                    :L-FECHA-OCURRENCIA, :L-FECHA-DECLARACION,
                    :L-COBERTURA, :L-GARANTIA,
                    :L-IMPORTE-DECLARADO, :L-DESCRIPCION,
                    'AB')
           END-EXEC
           IF SQLCODE-SIN NOT = 0
              MOVE 50 TO L-RETURN-CODE
           ELSE
              MOVE HV-SIN-ID TO L-ID-SINIESTRO
           END-IF.
