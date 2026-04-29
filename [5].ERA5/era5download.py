# Download ERA5 reanalysis data (single levels) from the Copernicus Climate Data Store (CDS).
#
# The script retrieves monthly NetCDF files for a defined geographic area,
# looping over a specified year range. It downloads variables such as wind,
# pressure, and sea surface temperature, and skips files that already exist.
#
# Output:
# - Monthly .nc files named as: era5_<location>_<year>_<month>.nc
#
# Requirements:
# - cdsapi configured with a valid CDS API key (~/.cdsapirc)

import os
import cdsapi

c = cdsapi.Client()

dataset = "reanalysis-era5-single-levels"
variables = [
    "10m_u_component_of_wind",
    "10m_v_component_of_wind",
    "mean_sea_level_pressure",
    "sea_surface_temperature",
    "surface_pressure"
]

area = [33.7015, -118.2805, 33.6950, -118.2658] # Los Ángeles

anio_inicio = 2010
anio_fin = 2020

for year in range(anio_inicio, anio_fin + 1):
    for m in range(1, 13):
        month = f"{m:02d}"
        filename = f"era5_losangeles_{year}_{month}.nc"

        if os.path.exists(filename) and os.path.getsize(filename) > 0:
            print(f"Archivo existente, se omite: {filename}")
            continue

        print(f"Descargando {filename} ...")

        c.retrieve(
            dataset,
            {
                "product_type": "reanalysis",
                "variable": variables,
                "year": str(year),
                "month": month,
                "day": [f"{d:02d}" for d in range(1, 32)],
                "time": [f"{h:02d}" for h in range(24)],
                "data_format": "netcdf",
                "area": area
            },
            filename
        )

        print(f"Archivo guardado: {filename}\n")

print(f"Descarga completa de {anio_inicio} a {anio_fin}")