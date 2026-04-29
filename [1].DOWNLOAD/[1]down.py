# Download historical hourly water level data from NOAA CO-OPS API for a given station.
# The script loops through a specified year range, retrieves data in CSV format,
# extracts date-time components, and writes a clean, structured output file.
#
# Parameters:
# - STATION_ID: NOAA station identifier
# - START, END: year range for data download
# - OUTFILE: output CSV file name

import os, requests

STATION_ID = '9410660'  # Los Angeles

OUTFILE = "CW-SF-1950-2025.csv"
START, END = 1950, 2025

fmt = lambda a,b,c,d,e,f: f"{a:<5} {b:<3} {c:<3} {d:<3} {e:<3} {f:<10}\n"

if os.path.exists(OUTFILE):
    os.remove(OUTFILE)

with open(OUTFILE, "w") as out:
    out.write(fmt("year", "month", "day", "hour", "minute", "water_level"))

    for y in range(START, END + 1):
        print("Procesando año", y)

        url = ("https://api.tidesandcurrents.noaa.gov/api/prod/datagetter?"
               f"begin_date={y}0101&end_date={y}1231&station={STATION_ID}"
               "&product=hourly_height&datum=STND&time_zone=gmt&units=metric&format=csv")

        r = requests.get(url)
        if r.status_code != 200:
            continue

        for line in r.text.splitlines()[1:]:
            p = line.split(",")
            if len(p) < 2:
                continue

            date, time = p[0].split()
            year, month, day = date.split("-")
            hour, minute = time.split(":")

            water_level = p[1] or "NaN"
            out.write(fmt(year, month, day, hour, minute, water_level))

print("Descarga completa.")