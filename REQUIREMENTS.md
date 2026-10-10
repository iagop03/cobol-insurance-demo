# SRS — Requerimiento: Recargo por mora en rehabilitaciones (> 12 meses)

**Referencia:** REQ-REHAB-042  
**Prioridad:** Alta  
**Área afectada:** Contratación — Rehabilitaciones  
**Fecha de solicitud:** 2024-09-15  
**Estado:** Pendiente de análisis técnico

---

## 1. Contexto y motivación

El sistema actual calcula el recargo por mora en el proceso de rehabilitación de pólizas vencidas. Este recargo se aplica cuando el tomador quiere reactivar una póliza que lleva tiempo sin pagar, para compensar el riesgo asumido durante el periodo de impago.

La operativa de negocio ha detectado que para pólizas con más de 12 meses de impago el recargo calculado no es correcto: en lugar de aplicar el recargo sobre todos los meses vencidos, el sistema parece "reiniciar" el contador cada 12 meses. Clientes con 13, 14 o 15 meses de impago pagan el mismo recargo que uno con 1, 2 o 3 meses respectivamente.

Este error ha sido reportado por el equipo de suscripción tras detectar rehabilitaciones en las que el recargo cobrado era significativamente inferior al esperado según la tabla de tarifas vigente.

---

## 2. Descripción funcional del requerimiento

### 2.1 Comportamiento actual (incorrecto)

Para una póliza con N meses de impago, el sistema calcula el recargo aplicando un ajuste de meses que produce resultados incorrectos cuando N supera los 12 meses:

- Póliza con 13 meses de impago → recargo calculado sobre **1 mes**
- Póliza con 14 meses de impago → recargo calculado sobre **2 meses**
- Póliza con 24 meses de impago → recargo calculado sobre **0 meses** (sin recargo)

### 2.2 Comportamiento esperado (correcto)

El recargo por mora debe calcularse siempre sobre el número **total** de meses vencidos sin excepción:

- Póliza con 13 meses de impago → recargo calculado sobre **13 meses**
- Póliza con 24 meses de impago → recargo calculado sobre **24 meses**

La fórmula de recargo según la tabla de tarifas es:

```
Recargo = Prima_mensual × Meses_vencidos × Tasa_mora_mensual
```

Donde `Tasa_mora_mensual` se obtiene del parámetro `TASA.MORA.MENSUAL` en la tabla `PARAMETROS_SIS`.

### 2.3 Casos límite

- **Exactamente 12 meses:** el comportamiento actual es correcto (MOD(12,12) = 0, pero el recargo mínimo es 1 mes). Verificar que no se rompa este caso.
- **Pólizas vencidas con 0 meses:** no deben llegar al cálculo de recargo; validar antes de llamar al programa.
- **Pólizas en estado ANU (anuladas):** no son elegibles para rehabilitación; el programa debe rechazarlas antes del cálculo.

---

## 3. Análisis de impacto preliminar (a completar)

Los siguientes programas pueden verse afectados por este cambio. El análisis detallado debe confirmar cuáles requieren modificación y cuáles son solo dependencias de consulta:

| Programa   | Área          | Tipo de relación              |
|------------|---------------|-------------------------------|
| REHPOL.cbl | Contratación  | **Modificación directa**      |
| MOVPOL.cbl | Contratación  | Llamado por REHPOL — revisar  |
| CALRUT.cbl | Comunes       | Rutinas de cálculo — revisar  |
| VALDAT.cbl | Comunes       | Cálculo de diferencias fecha  |
| PARMGT.cbl | Comunes       | Lee tasa de mora              |
| TARIFA.cbl | Contratación  | Puede compartir lógica prima  |

> Este análisis de impacto es el punto de partida. AntCrew debe confirmar qué otros programas del corpus referencian `HV-POL-MESES-VENC` o la lógica de recargo.

---

## 4. Criterios de aceptación

1. Para cualquier póliza con N meses vencidos (N > 0), el recargo calculado en la rehabilitación debe ser `Prima_mensual × N × Tasa_mora_mensual`.
2. El resultado debe ser idéntico al actual para N ≤ 12 (sin regresiones).
3. El movimiento de rehabilitación registrado en `MOVIMIENTOS` debe incluir el importe de recargo correcto en el campo `MOV_MONTO`.
4. El programa no debe producir `SQLCODE` negativos en los caminos de prueba con 1, 6, 12, 13, 18, 24 y 36 meses de impago.

---

## 5. Notas de prueba

Para validar el fix, usar la siguiente combinación de datos de prueba:

```
Póliza: estado VE (vencida), meses_vencida = 15
Prima mensual: 100,00 EUR
Tasa mora mensual: 1,5% (parámetro TASA.MORA.MENSUAL = 0.015)

Recargo esperado: 100,00 × 15 × 0,015 = 22,50 EUR
Recargo actual (con bug): 100,00 × 3 × 0,015 = 4,50 EUR
```
