# cobol-insurance-demo

Corpus de demostración de un sistema de seguros escrito en COBOL/DB2, diseñado para mostrar las capacidades de análisis de incidentes de [AntCrew](https://antcrew.org).

> **Nota:** Este repositorio es un corpus representativo, no el código fuente de una aseguradora real. Los programas están escritos con la estructura, patrones y complejidad típicos de sistemas legados de seguros en mainframe IBM z/OS.

## Estructura del sistema

```
cobol-insurance-demo/
├── copybooks/          # Estructuras de datos compartidas (DCLGEN-like)
│   ├── POLREC.cpy      # Registro de póliza
│   ├── MOVREC.cpy      # Movimiento de póliza
│   ├── RECREC.cpy      # Recibo
│   ├── SINREC.cpy      # Siniestro
│   ├── PERREC.cpy      # Persona
│   └── PRODREC.cpy     # Producto/ramo
│
├── comun/              # Utilidades transversales
│   ├── VALDAT.cbl      # Validación y cálculo de fechas
│   ├── ERRMSG.cbl      # Gestión centralizada de errores
│   ├── PARMGT.cbl      # Parámetros de sistema (SFTP hosts, tasas, umbrales)
│   ├── FTPCTL.cbl      # Control de transferencias SFTP/FTP
│   └── CALRUT.cbl      # Rutinas de cálculo (mora, días hábiles, prorrateo)
│
├── contratacion/       # Ciclo de vida de la póliza
│   ├── EMIPOL.cbl      # Emisión de póliza
│   ├── TARIFA.cbl      # Tarificación (cálculo de prima)
│   ├── NEGDEF.cbl      # Definición de negocio/contrato
│   ├── INTMED.cbl      # Gestión de intermediarios
│   ├── SUPLMT.cbl      # Suplementos y modificaciones
│   ├── RENOVA.cbl      # Renovación de pólizas
│   ├── ANULAN.cbl      # Anulación con devolución pro-rata
│   ├── MOVPOL.cbl      # Registro de movimientos de póliza
│   └── REHPOL.cbl      # Rehabilitación de pólizas vencidas  ⚠️
│
├── producto/           # Taller de producto
│   ├── PRODDF.cbl      # Definición de producto
│   ├── COBDEF.cbl      # Coberturas del producto
│   ├── GARDEF.cbl      # Garantías y límites
│   ├── CODPRD.cbl      # Gestión de códigos técnico/comercial
│   └── CAMPDF.cbl      # Campos y validaciones del producto
│
├── personas/           # Gestión de personas
│   ├── PERSOM.cbl      # Master de personas (CRUD)
│   ├── FILIAC.cbl      # Filiación y validación de documentos de identidad
│   ├── ROLES.cbl       # Roles en póliza (tomador, asegurado, beneficiario)
│   ├── DOMCOD.cbl      # Domicilios
│   └── RELPER.cbl      # Relaciones entre personas
│
├── recibos/            # Facturación y cobros
│   ├── GENREC.cbl      # Generación de recibos
│   ├── COBRAN.cbl      # Proceso de cobro
│   ├── DEVOLU.cbl      # Devoluciones y NSF
│   ├── ESTARE.cbl      # Estado de recibos y póliza
│   └── LIQUID.cbl      # Liquidación de comisiones a intermediarios  ⚠️
│
├── siniestros/         # Gestión de siniestros
│   ├── SINREG.cbl      # Registro de siniestro                        ⚠️
│   ├── COBSIN.cbl      # Verificación de cobertura
│   ├── PERSIN.cbl      # Periodos de cobertura
│   ├── PAGSIN.cbl      # Pagos de siniestros
│   └── VALSIN.cbl      # Validación de siniestros
│
├── REQUIREMENTS.md     # SRS: nuevo requerimiento de recargo por mora
└── README.md
```

> ⚠️ Tres programas contienen defectos documentados (ver sección [Bugs conocidos](#bugs-conocidos)), diseñados específicamente para demostrar el análisis de incidentes con AntCrew.

## Áreas de negocio

### Contratación
Gestiona el ciclo de vida completo de una póliza: definición del negocio y contrato marco, validación del intermediario y su autorización por ramo, tarificación según tabla de productos, emisión, suplementos de modificación, renovaciones anuales, anulaciones con cálculo de devolución pro-rata y rehabilitaciones de pólizas vencidas.

### Taller de Producto
Define la estructura interna de un producto asegurador: coberturas activas, garantías con sus límites y periodos de carencia, códigos técnico y comercial, campos de riesgo y sus validaciones. Los programas de esta área son llamados por contratación y siniestros para consultar las reglas del producto.

### Personas
Mantiene el master de personas físicas y jurídicas: alta con validación de DNI/NIE/CIF (algoritmo MOD-23 para DNI, dígito de control para CIF), gestión de domicilios, asignación de roles en póliza (tomador, asegurado, beneficiario, pagador) y relaciones entre personas (beneficiario familiar, representante legal).

### Recibos
Implementa el ciclo de facturación: generación de recibos en la fecha de vencimiento según modalidad de pago (anual/semestral/mensual), proceso de cobro con actualización de estado, devoluciones NSF con cargo del 3% de gestión, control de estado de morosidad en la póliza y liquidación mensual de comisiones a intermediarios con remesa SFTP al banco.

### Siniestros
Registra y gestiona los siniestros: alta con validación de cobertura contratada, verificación de periodos de cobertura, tramitación, pagos parciales o totales a beneficiarios y cierre. La validación de que la fecha de ocurrencia está dentro del periodo de cobertura tiene un defecto conocido (ver bugs).

### Utilidades comunes
Cinco programas transversales llamados por todas las áreas:
- **VALDAT**: fechas en formato AAAAMMDD — validación, diferencia en meses, suma de meses, validación de periodo
- **ERRMSG**: acceso a tabla de mensajes de error con inserción en log de auditoría
- **PARMGT**: parámetros del sistema con cache en memoria (hosts SFTP, tasas de mora, umbrales de validación)
- **FTPCTL**: orquestación de transferencias SFTP con auditoría en DB2; llama al módulo ensamblador FTPEXEC para la transferencia real
- **CALRUT**: días naturales y hábiles, interés de mora, prorrateo de prima y conversión de moneda

## Bugs conocidos

Tres defectos están intencionalmente presentes en el corpus para ilustrar el tipo de problemas que aparecen en sistemas legados y que AntCrew puede diagnosticar:

### 1. REHPOL — Recargo incorrecto para moras > 12 meses
**Archivo:** `contratacion/REHPOL.cbl`

```cobol
COMPUTE WS-MESES-AJUSTE =
    FUNCTION MOD(HV-POL-MESES-VENC, 12)
```

`FUNCTION MOD(..., 12)` devuelve el resto de la división por 12. Para una póliza con 15 meses vencidos, el resultado es 3 (no 15). El recargo por mora se calcula sobre 3 meses en vez de 15.

**Requerimiento relacionado:** `REQUIREMENTS.md` — "Implementar recargo por mora para pólizas con más de 12 meses de impago".

### 2. SINREG — Siniestros fuera del periodo de cobertura aceptados
**Archivo:** `siniestros/SINREG.cbl`

El programa llama a `VALSIN` que a su vez llama a `PERSIN`. `PERSIN` obtiene las fechas del periodo de cobertura pero no compara `SIN-FECHA-OCURR` contra esas fechas; y `SINREG` tampoco lo hace. Un siniestro con fecha anterior a la vigencia de la póliza pasa sin error.

### 3. LIQUID — Liquidación de comisiones sobre prima original
**Archivo:** `recibos/LIQUID.cbl`

La liquidación de comisiones usa el importe del recibo original (`REC_COMISION_IMP`). Cuando se ha emitido un suplemento que modifica la prima, los recibos ya generados no se recalculan. Las comisiones liquidadas no reflejan los suplementos. Este comportamiento está documentado como discrepancia conocida.

## Uso con AntCrew

### Prerequisitos

```bash
pip install antcrew
```

### Analizar un incidente

El índice se construye automáticamente en el primer análisis:

```bash
antcrew cobol-incident \
  "Clientes con más de 12 meses de impago están siendo rehabilitados con recargo incorrecto" \
  --cobol-dir ./cobol-insurance-demo
```

AntCrew identificará `REHPOL.cbl` como programa primario, trazará la cadena de llamadas hacia `MOVPOL` → `VALDAT`, y señalará la línea con `FUNCTION MOD` como origen del cálculo erróneo.

### Demo con SRS

Para analizar el impacto de un nuevo requerimiento sobre el corpus:

```bash
antcrew cobol-incident \
  "$(cat REQUIREMENTS.md)" \
  --cobol-dir ./cobol-insurance-demo
```

## Tecnología representada

- **Plataforma:** IBM z/OS (mainframe)
- **COBOL:** IBM Enterprise COBOL for z/OS
- **Base de datos:** DB2 for z/OS con SQL embebido (EXEC SQL)
- **Transferencia:** SFTP vía módulo ensamblador FTPEXEC
- **Estructura de llamadas:** `CALL 'PROGRAMA' USING ...` (COBOL subprogram linkage)
- **Copybooks:** estructuras compartidas vía `COPY <nombre>`

## Licencia

MIT. Este repositorio es un corpus de demostración — el código no está destinado a ejecución en producción.
