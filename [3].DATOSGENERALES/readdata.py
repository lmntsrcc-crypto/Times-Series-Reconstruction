# Compute missing data statistics for water level time series.
#
# The script reads CSV files containing water_level data, calculates the number
# and percentage of missing (NaN) and valid values, and prints basic statistics
# (min, max, total records) for each station.
#
# Input:
# - CSV files with a "water_level" column
#
# Output:
# - Console summary of missing data percentages and basic statistics per station

from datetime import datetime
import pandas as pd

def porcentaje_faltantes(archivo, inicio, fin, nombre):
    df = pd.read_csv(archivo, sep=r"\s+", header=0, na_values=["NaN"], engine="python")
    col = pd.to_numeric(df["water_level"], errors="coerce")
    nan = col.isna().sum()
    validos = col.notna().sum()
    total = len(col)

    print(f"\n{nombre}:")
    print(f"NaN: {nan}")
    print("%NaN:", nan, f"({nan/total*100:.2f}%)")
    print(f"Válidos: {validos}")
    print("%Válidos:", validos, f"({validos/total*100:.2f}%)")
    print(f"Total: {total}")
    print("Mínimo:", col.min())
    print("Máximo:", col.max())

def main():
    inicio = datetime(1950, 1, 1, 0, 0)
    fin    = datetime(2025, 6, 30, 23, 0)

    estaciones = [
        ("DATA-jun/CW-LJ-1950-2025.csv", "La Joya"),
        ("DATA-jun/CW-LA-1950-2025.csv", "Los Ángeles"),
        ("DATA-jun/CW-SD-1950-2025.csv", "San Diego"),
        ("DATA-jun/CW-SF-1950-2025.csv", "San Francisco")
    ]

    for archivo, nombre in estaciones:
        porcentaje_faltantes(archivo, inicio, fin, nombre)

if __name__ == "__main__":
    main()
