       IDENTIFICATION DIVISION.
       PROGRAM-ID. CAMPDF.
      *----------------------------------------------------------------*
      * CAMPDF  - Definicion de campos de producto (taller de producto)*
      * Llama a: (ninguno — punto final)                               *
      *----------------------------------------------------------------*
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-MAINFRAME.
      *
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-RETURN-CODE         PIC S9(4) COMP VALUE 0.
       01 WS-INDICE              PIC 9(3) VALUE 0.
      *
       01 DCLGEN-CAMPOS.
          05 HV-CAM-CODIGO       PIC X(10).
          05 HV-CAM-PRODUCTO     PIC X(6).
          05 HV-CAM-NOMBRE       PIC X(80).
          05 HV-CAM-TIPO         PIC X(3).
          05 HV-CAM-LONGITUD     PIC 9(4).
          05 HV-CAM-DECIMALES    PIC 9(2).
          05 HV-CAM-OBLIGATORIO  PIC X(1).
          05 HV-CAM-VALOR-DEFECT PIC X(50).
          05 SQLCODE             PIC S9(9) COMP.
      *
       LINKAGE SECTION.
       01 L-FUNCION              PIC X(1).
          88 L-OBTENER-CAMPOS    VALUE '1'.
          88 L-VALIDAR-CAMPO     VALUE '2'.
       01 L-CODIGO-PRODUCTO      PIC X(6).
       01 L-CODIGO-CAMPO         PIC X(10).
       01 L-VALOR-CAMPO          PIC X(100).
       01 L-ES-VALIDO            PIC X(1).
       01 L-RETURN-CODE          PIC S9(4) COMP.
      *
       PROCEDURE DIVISION USING L-FUNCION
                                 L-CODIGO-PRODUCTO
                                 L-CODIGO-CAMPO
                                 L-VALOR-CAMPO
                                 L-ES-VALIDO
                                 L-RETURN-CODE.
           MOVE 0 TO L-RETURN-CODE
           EVALUATE TRUE
             WHEN L-OBTENER-CAMPOS
               PERFORM 1000-OBTENER-CAMPOS-PRODUCTO
             WHEN L-VALIDAR-CAMPO
               PERFORM 2000-VALIDAR-VALOR-CAMPO
             WHEN OTHER
               MOVE 99 TO L-RETURN-CODE
           END-EVALUATE
           STOP RUN.
      *
       1000-OBTENER-CAMPOS-PRODUCTO.
           EXEC SQL
               SELECT COUNT(*)
               INTO :WS-INDICE
               FROM DEF_CAMPOS
               WHERE CAM_PRODUCTO  = :L-CODIGO-PRODUCTO
                 AND CAM_ACTIVO    = 'S'
           END-EXEC
           IF SQLCODE NOT = 0
              MOVE 10 TO L-RETURN-CODE
           END-IF.
      *
       2000-VALIDAR-VALOR-CAMPO.
           MOVE L-CODIGO-CAMPO TO HV-CAM-CODIGO
           EXEC SQL
               SELECT CAM_TIPO, CAM_LONGITUD,
                      CAM_OBLIGATORIO, CAM_VALOR_DEFECT
               INTO :HV-CAM-TIPO, :HV-CAM-LONGITUD,
                    :HV-CAM-OBLIGATORIO, :HV-CAM-VALOR-DEFECT
               FROM DEF_CAMPOS
               WHERE CAM_PRODUCTO = :L-CODIGO-PRODUCTO
                 AND CAM_CODIGO   = :HV-CAM-CODIGO
           END-EXEC
           IF SQLCODE NOT = 0
              MOVE 20 TO L-RETURN-CODE
           ELSE IF HV-CAM-OBLIGATORIO = 'S' AND L-VALOR-CAMPO = SPACES
              MOVE 'N' TO L-ES-VALIDO
           ELSE
              MOVE 'S' TO L-ES-VALIDO
           END-IF.
