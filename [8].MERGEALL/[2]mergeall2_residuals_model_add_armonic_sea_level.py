# Reconstruct full water level time series by combining harmonic tide and modeled residuals.
#
# The script merges the modeled residual series with the harmonic components
# obtained from classical tidal analysis, aligns both datasets by timestamp,
# and computes the reconstructed water level as:
# ElevacionReconstruida = Armonicos + ResidualModelado
#
# Input:
# - Modeled residual CSV (ResidualModelado)
# - Harmonic analysis CSV (Armonicos, Elevacion)
#
# Output:
# - CSV file with original elevation, harmonic component, modeled residual,
#   and reconstructed water level

import pandas as pd
from pathlib import Path

archivo_creado = Path("CW_LA_RESIDUAL_MODEL.csv")
archivo_base = Path("../[4].MATLAB/DATACLASICHARMONIC/CW-LA-1950-2025.csv")

df_creado = pd.read_csv(archivo_creado)
df_base = pd.read_csv(archivo_base)

df_base["Armonicos"] = pd.to_numeric(df_base["Armonicos"], errors="coerce")
df_base["Elevacion"] = pd.to_numeric(df_base["Elevacion"], errors="coerce")
df_creado["ResidualModelado"] = pd.to_numeric(df_creado["ResidualModelado"], errors="coerce")

df_base_recorte = df_base[[
    "Anio", "Mes", "Dia", "Hora",
    "Armonicos", "Elevacion"
]].copy()

df_final = pd.merge(
    df_creado,
    df_base_recorte,
    on=["Anio", "Mes", "Dia", "Hora"],
    how="left"
)

df_final["ElevacionReconstruida"] = (
    df_final["Armonicos"] + df_final["ResidualModelado"]
)

df_final = df_final[[
    "Anio", "Mes", "Dia", "Hora",
    "Elevacion",
    "Armonicos",
    "ResidualModelado",
    "ElevacionReconstruida"
]]

salida = Path("CW_LA_COMPLETED.csv")
df_final.to_csv(salida, index=False, na_rep="NaN")

print("Archivo generado:", salida)