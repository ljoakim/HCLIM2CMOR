import uuid
from pathlib import Path

import numpy as np
from netCDF4 import Dataset

# Path to the file that holds the correct coordinate data
REFERENCE_FILE = Path("coordinates_HCLIM_EUR12.nc")

# Root of the folder tree containing the files to update
TARGET_ROOT = Path("/nobackup/accmls1/proj/cordex_cmip6/postprocess/HCLIM2CMOR/tmp/202314/core_new")

# Prefix for the tracking_id (a new UUID is generated per file)
TRACKING_PREFIX = "hdl:21.14103/"

# Read the lon data once from the reference file
with Dataset(REFERENCE_FILE, "r") as ref:
    lon_ref = ref.variables["lon"][:]

print(f"Reference lon shape: {lon_ref.shape}")

# Walk the folder structure and update every .nc file
for filepath in TARGET_ROOT.rglob("*.nc"):
    try:
        with Dataset(filepath, "r+") as ds:  # r+ = read/write, keeps everything else intact
            if "lon" not in ds.variables:
                print(f"SKIP (no lon): {filepath}")
                continue

            lon_var = ds.variables["lon"]

            # Safety check: shapes must match before comparing/overwriting
            if lon_var.shape != lon_ref.shape:
                print(f"SKIP (shape mismatch {lon_var.shape} vs {lon_ref.shape}): {filepath}")
                continue

            lon_current = lon_var[:]

            # Only touch the file if the lon data actually differs
            if np.array_equal(lon_current, lon_ref):
                print(f"UNCHANGED (lon identical): {filepath}")
                continue

            lon_var[:] = lon_ref                  # replace only the data values

            # Set a fresh, unique tracking_id
            new_tracking_id = TRACKING_PREFIX + str(uuid.uuid4())
            ds.setncattr("tracking_id", new_tracking_id)

        print(f"OK: {filepath}  ({new_tracking_id})")

    except Exception as e:  # noqa: BLE001
        print(f"ERROR {filepath}: {e}")
