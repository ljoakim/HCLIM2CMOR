#!/usr/bin/env python3

import csv
import pathlib
import requests
import urllib.parse


INDEX_VAR_CM_ASU = 7
INDEX_VAR_CM_SUB = 8
INDEX_VAR_CM_DAY = 9
INDEX_VAR_CM_MON = 10
INDEX_UNIT = 13
INDEX_FRE_SUB = 15
INDEX_VAR_LONG_NAME = 24
INDEX_VAR_COMMENT = 25
INDEX_VAR_STD_NAME = 26
INDEX_UP_DOWN = 27


def update():
    cmor_table_files = {
        "1hr": "CORDEX-CMIP6_1hr.json",
        "6hr": "CORDEX-CMIP6_6hr.json",
        "day": "CORDEX-CMIP6_day.json",
        "mon": "CORDEX-CMIP6_mon.json",
        "fx": "CORDEX-CMIP6_fx.json",
    }

    csv_path = (
        pathlib.Path(__file__).parent.parent
        / "CMORlight"
        / "Config"
        / "CORDEX6_CMOR_HCLIM_variables_table.csv"
    )
    print(f"Updating variables table: '{csv_path}'...")

    # Get files from github
    #
    base_url = "https://github.com/WCRP-CORDEX/cordex-cmip6-cmor-tables/raw/main/Tables/"
    cmor_tables = {}
    for freq, file in cmor_table_files.items():
        table_url = urllib.parse.urljoin(base_url, file)
        print(f"  Fetching CMOR table: {table_url}")
        table_json = requests.get(table_url).json()
        cmor_tables[freq] = table_json["variable_entry"]

    # Load current csv
    #
    table = []
    with open(csv_path, newline="") as f:
        reader = csv.reader(f, delimiter=";")
        for row in reader:
            table.append(row)

    # Fetch and insert values from cmor tables
    #
    for row in table[1:]:
        var = row[0]

        # Subdaily frequency
        #
        if var in cmor_tables["1hr"]:
            row[INDEX_FRE_SUB] = "24"
        elif var in cmor_tables["6hr"]:
            row[INDEX_FRE_SUB] = "4"
        else:
            row[INDEX_FRE_SUB] = ""

        # Subdaily cell method
        #
        if var in cmor_tables["1hr"]:
            row[INDEX_VAR_CM_SUB] = cmor_tables["1hr"][var]["cell_methods"]
        elif var in cmor_tables["6hr"]:
            row[INDEX_VAR_CM_SUB] = cmor_tables["6hr"][var]["cell_methods"]
        else:
            row[INDEX_VAR_CM_SUB] = ""

        # Daily cell method
        #
        if var in cmor_tables["day"]:
            row[INDEX_VAR_CM_DAY] = cmor_tables["day"][var]["cell_methods"]
        else:
            row[INDEX_VAR_CM_DAY] = ""

        # Monthly cell_method
        #
        if var in cmor_tables["mon"]:
            row[INDEX_VAR_CM_MON] = cmor_tables["mon"][var]["cell_methods"]
        else:
            row[INDEX_VAR_CM_MON] = ""

        # For fx variables, we place cell_method in the additional subdaily
        # column (currently not used by any other type of var).
        #
        if var in cmor_tables["fx"]:
            row[INDEX_VAR_CM_ASU] = cmor_tables["fx"][var]["cell_methods"]
        else:
            row[INDEX_VAR_CM_ASU] = ""

        # units, long_name and standard_name
        #
        if var in cmor_tables["day"]:
            var_info = cmor_tables["day"][var]
        elif var in cmor_tables["mon"]:
            var_info = cmor_tables["mon"][var]
        elif var in cmor_tables["fx"]:
            var_info = cmor_tables["fx"][var]
        else:
            raise KeyError("Couldn't find information about variable")

        row[INDEX_UNIT] = var_info["units"]
        row[INDEX_VAR_LONG_NAME] = var_info["long_name"]
        row[INDEX_VAR_COMMENT] = var_info["comment"]
        row[INDEX_VAR_STD_NAME] = var_info["standard_name"]
        row[INDEX_UP_DOWN] = var_info["positive"]

    # Save generated table to csv
    #
    with open(csv_path, "w") as f:
        writer = csv.writer(f, delimiter=";", lineterminator="\n")
        writer.writerows(table)

    print("Update done.")


if __name__ == "__main__":
    update()
