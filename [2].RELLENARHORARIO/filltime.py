# Complete missing hourly timestamps in a water level time series.
#
# The script reads a NOAA-derived CSV file, builds a continuous hourly datetime index,
# inserts missing hours as rows with NaN water_level values, and saves the completed
# dataset as a new CSV file.
#
# Input format:
# - year, month, day, hour, minute, water_level
#
# Output:
# - A completed hourly time series saved as *_NaN.csv

import pandas as pd
import os

def completar_horas(archivo: str):
    df = pd.read_csv(
        archivo,
        sep=r"\s+",
        usecols=[0, 1, 2, 3, 4, 5],
        engine="python"
    )

    df = df.dropna(subset=["year", "month", "day", "hour", "minute"])
    df[["year", "month", "day", "hour", "minute"]] = df[["year", "month", "day", "hour", "minute"]].astype(int)

    df["datetime"] = pd.to_datetime(df[["year", "month", "day", "hour", "minute"]], errors="coerce")
    df = df.dropna(subset=["datetime"]).set_index("datetime")

    full = pd.date_range(df.index.min(), df.index.max(), freq="h")
    out = df.reindex(full).reset_index().rename(columns={"index": "datetime"})

    out["year"]   = out["datetime"].dt.year.astype(str)
    out["month"]  = out["datetime"].dt.month.astype(str).str.zfill(2)
    out["day"]    = out["datetime"].dt.day.astype(str).str.zfill(2)
    out["hour"]   = out["datetime"].dt.hour.astype(str).str.zfill(2)
    out["minute"] = out["datetime"].dt.minute.astype(str).str.zfill(2)

    return out[["year", "month", "day", "hour", "minute", "water_level"]]

def main():
    #archivo = "DATA/CW-LA-1950-2025.csv"
    #archivo = "DATA/CW-LJ-1950-2025.csv"
    #archivo = "DATA/CW-SD-1950-2025.csv"
    archivo = "DATA/CW-SF-1950-2025.csv"
    salida = os.path.splitext(os.path.basename(archivo))[0] + "_NaN.csv"

    df = completar_horas(archivo)
    df.to_csv(salida, index=False, header=True, sep=" ", na_rep="NaN", float_format="%.3f")

    print(df.head())
    print("Total:", len(df))
    print("Guardado en:", salida)

if __name__ == "__main__":
    main()
