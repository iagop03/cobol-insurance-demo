       IDENTIFICATION DIVISION.
       PROGRAM-ID. COBDEF.
      *----------------------------------------------------------------*
      * COBDEF  - Definicion de coberturas de un producto              *
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
       01 DCLGEN-COBERTURAS.
          05 HV-COB-CODIGO       PIC X(6).
          05 HV-COB-PRODUCTO     PIC X(6).
          05 HV-COB-NOMBRE       PIC X(80).
          05 HV-COB-TIPO         PIC X(3).
          05 HV-COB-CAPITAL-MAX  PIC S9(11)V9(2) COMP-3.
          05 HV-COB-OBLIGATORIA  PIC X(1).
          05 HV-COB-FRANQUICIA   PIC S9(9)V9(2) COMP-3.
          05 SQLCODE             PIC S9(9) COMP.
      *
       01 WS-TABLA-COBERTURAS.
          05 WS-COB-ENTRY OCCURS 20 TIMES.
             10 WS-COB-CODIGO    PIC X(6).
             10 WS-COB-NOMBRE    PIC X(80).
             10 WS-COB-OBLIGAT   PIC X(1).
      *
       LINKAGE SECTION.
       01 L-CODIGO-PRODUCTO      PIC X(6).
       01 L-VERSION              PIC 9(3).
       01 L-NUM-COBERTURAS       PIC 9(3).
       01 L-RETURN-CODE          PIC S9(4) COMP.
      *
       PROCEDURE DIVISION USING L-CODIGO-PRODUCTO
                                 L-VERSION
                                 L-NUM-COBERTURAS
                                 L-RETURN-CODE.
           MOVE 0 TO L-RETURN-CODE
           MOVE 0 TO L-NUM-COBERTURAS
           PERFORM 1000-LISTAR-COBERTURAS
           STOP RUN.
      *
       1000-LISTAR-COBERTURAS.
           MOVE L-CODIGO-PRODUCTO TO HV-COB-PRODUCTO
           EXEC SQL
               DECLARE CUR_COBERTURAS CURSOR FOR
               SELECT COB_CODIGO, COB_NOMBRE,
                      COB_TIPO, COB_CAPITAL_MAX,
                      COB_OBLIGATORIA, COB_FRANQUICIA
               FROM COBERTURAS
               WHERE COB_PRODUCTO = :HV-COB-PRODUCTO
                 AND COB_VERSION  = :L-VERSION
                 AND COB_ACTIVA   = 'S'
               ORDER BY COB_ORDEN
           END-EXEC
           EXEC SQL OPEN CUR_COBERTURAS END-EXEC
           MOVE 1 TO WS-INDICE
           PERFORM UNTIL SQLCODE NOT = 0 OR WS-INDICE > 20
               EXEC SQL
                   FETCH CUR_COBERTURAS
                   INTO :HV-COB-CODIGO, :HV-COB-NOMBRE,
                        :HV-COB-TIPO, :HV-COB-CAPITAL-MAX,
                        :HV-COB-OBLIGATORIA, :HV-COB-FRANQUICIA
               END-EXEC
               IF SQLCODE = 0
                  MOVE HV-COB-CODIGO     TO WS-COB-CODIGO(WS-INDICE)
                  MOVE HV-COB-NOMBRE     TO WS-COB-NOMBRE(WS-INDICE)
                  MOVE HV-COB-OBLIGATORIA TO WS-COB-OBLIGAT(WS-INDICE)
                  ADD 1 TO WS-INDICE
               END-IF
           END-PERFORM
           EXEC SQL CLOSE CUR_COBERTURAS END-EXEC
           COMPUTE L-NUM-COBERTURAS = WS-INDICE - 1.
