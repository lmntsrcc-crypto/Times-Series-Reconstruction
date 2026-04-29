# Convert ERA5 CSV data into a structured format with separated time components.
#
# The script reads a CSV file containing ERA5 variables, extracts year, month,
# day, and hour from the timestamp, renames variables to shorter labels, and
# saves a simplified dataset for further analysis.
#
# Input:
# - CSV file with a "valid_time" column and ERA5 variable names
#
# Output:
# - CSV file with time components and renamed variables

import pandas as pd

entrada = "../[5].ERA5/DATAERA5NC/CONVERTNCTOCSV/era5_losangeles_1950_2025.csv"
salida = "CW-LA-1950-2025_h_oc.csv"

df = pd.read_csv(entrada)

df["valid_time"] = pd.to_datetime(df["valid_time"])

df["Anio"] = df["valid_time"].dt.year
df["Mes"] = df["valid_time"].dt.month
df["Dia"] = df["valid_time"].dt.day
df["Hora"] = df["valid_time"].dt.hour

df = df.rename(columns={
    "10m_u_component_of_wind": "u10",
    "10m_v_component_of_wind": "v10",
    "mean_sea_level_pressure": "msl",
    "sea_surface_temperature": "sst",
    "surface_pressure": "sp"
})

df_final = df[["Anio","Mes","Dia","Hora","u10","v10","msl","sst","sp"]]

df_final.to_csv(salida, index=False)

print("Archivo listo:", salida)

