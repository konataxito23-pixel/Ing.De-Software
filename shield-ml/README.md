# NEXORA Shield — Dataset y modelo baseline (TAR-04)

## Dataset sintético
Archivo: `nexora_transacciones_sinteticas.csv` — 5.000 transacciones, 150 usuarios.

Columnas: transaccion_id, usuario_id, tipo_transaccion, monto, hora_dia, dia_semana,
destino_nuevo, antiguedad_cuenta_dias, promedio_monto_ultimos_30_dias, es_anomalia_real.

`es_anomalia_real` es una etiqueta de referencia usada solo para evaluar el modelo
después de entrenarlo — el modelo NUNCA se entrena con esa columna, ya que
Isolation Forest es un algoritmo no supervisado (no requiere ejemplos etiquetados
de fraude, que en un entorno real casi nunca existen de antemano).

## Modelo
Se entrenó un Isolation Forest (`scikit-learn`) sobre las columnas numéricas
(monto, hora, destino nuevo, antigüedad de cuenta, promedio de 30 días, tipo
de transacción y día de la semana codificados). Código completo en
`Nexora_Shield_Test.ipynb`.

## Resultado de evaluación

| Clase | Precisión | Recall | F1-score | Soporte |
|---|---|---|---|---|
| 0 (normal) | 0.98 | 0.98 | 0.98 | 4850 |
| 1 (anomalía) | 0.39 | 0.39 | 0.39 | 150 |

Exactitud global: 0.96

**Interpretación:** el modelo distingue muy bien las transacciones normales (98%
de acierto), pero como baseline demostrativo aún detecta solo el 39% de las
anomalías reales inyectadas. Es un resultado esperado para una primera versión
sin ajuste de parámetros, y coherente con el carácter "demostrativo" que el
backlog le asigna a esta tarea.

## Limitaciones
- Modelo entrenado únicamente con datos sintéticos; no representa comportamiento
  transaccional real ni debe usarse como base para decisiones financieras reales.
- El dataset fue diseñado con anomalías de distintos tipos (monto extremo, hora
  de madrugada, destino nuevo con monto alto) para poder evaluar el algoritmo,
  no para simular fraude sofisticado.
- Recall de 39% en anomalías indica que el modelo, en su versión baseline,
  debería complementarse con