# Merge ERA5 atmospheric data with tidal residuals based on timestamp.
#
# The script combines ERA5 variables (wind, pressure, temperature) with
# water level residuals (Error1) obtained from harmonic analysis, aligning
# both datasets by year, month, day, and hour.
#
# Input:
# - ERA5 CSV file with meteorological variables
# - Water level CSV file with residual (Error1)
#
# Output:
# - Merged CSV file containing both atmospheric variables and residuals

import pandas as pd

archivo_era5 = "CW-LA-1950-2025_h_oc.csv"
archivo_nivel = "../[4].MATLAB/DATAHARMONIC/CW-LA-1950-2025_h.csv"

archivo_salida = "era5_losangeles_merged.csv"
df_era = pd.read_csv(archivo_era5)
df_nivel = pd.read_csv(archivo_nivel)
df_nivel = df_nivel[["Anio", "Mes", "Dia", "Hora", "Error1"]]
df_nivel["Error1"] = pd.to_numeric(df_nivel["Error1"], errors="coerce")
df_merged = pd.merge(
    df_era,
    df_nivel,
    on=["Anio", "Mes", "Dia", "Hora"],
    how="left"
)

df_merged = df_merged[
    ["Anio", "Mes", "Dia", "Hora", "u10", "v10", "msl", "sst", "sp", "Error1"]
]

df_merged.to_csv(archivo_salida, index=False, na_rep="NaN")
print("Archivo generado:", archivo_salida)
