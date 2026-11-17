import uuid
from pathlib import Path

from netCDF4 import Dataset  # ty: ignore[unresolved-import]

DRY_RUN = True

# Path to the file that holds the correct coordinate data
REFERENCE_FILE = Path("coordinates_HCLIM_EUR12_Bi.nc")
#REFERENCE_FILE = Path("coordinates_HCLIM_EUR12_ATOS.nc")

INSTITUTE = "SMHI"
#INSTITUTE = "METNo"
# METNo: 202301, 202303, 202319 (ATOS)

VARS = ["z0", "od550aer", "sftlaf", "sfturf"]

# Root of the folder tree containing the files to update
TARGET_ROOT = Path("/nobackup/accmls1/proj/cordex_cmip6/202202/netcdf/tier2")

# Prefix for the tracking_id (a new UUID is generated per file)
TRACKING_PREFIX = "hdl:21.14103/"


# Read the lon data once from the reference file
with Dataset(REFERENCE_FILE, "r") as ref:
    lat_ref_data = ref.variables["lat"][:]
    lon_ref_data = ref.variables["lon"][:]

    crs_ref_var = ref.variables["crs"]
    crs_ref_data = crs_ref_var[:]
    crs_ref_attrs = {
        k: crs_ref_var.getncattr(k) for k in crs_ref_var.ncattrs() if k != "_FillValue"
    }

print(f"Reference lat shape: {lat_ref_data.shape}")
print(f"Reference lon shape: {lon_ref_data.shape}")
print(f"Reference crs data: {crs_ref_data}")
print(f"Reference crs attributes: {crs_ref_attrs}")

targets = []
for t in VARS:
    targets.extend(list(TARGET_ROOT.rglob(f"{t}_*_HCLIMcom-{INSTITUTE}_*.nc")))

# Recursive glob: every specified .nc file
for filepath in targets:
    if DRY_RUN:
        print(filepath)
    else:
        try:
            with Dataset(filepath, "r+") as ds:
                lat_var = ds.variables["lat"]
                lon_var = ds.variables["lon"]
                crs_var = ds.variables["crs"]

                lat_current = lat_var[:]
                lon_current = lon_var[:]
                crs_current = crs_var[:]

                lat_var[:] = lat_ref_data
                lon_var[:] = lon_ref_data
                crs_var[:] = crs_ref_data

                for name, template_value in crs_ref_attrs.items():
                    if name == "_FillValue":  # can't be modified after creation
                        continue
                    crs_var.setncattr(name, template_value)

                new_tracking_id = TRACKING_PREFIX + str(uuid.uuid4())
                ds.setncattr("tracking_id", new_tracking_id)

                print(f"OK: {filepath}  ({new_tracking_id})")

        except Exception as e:  # noqa: BLE001
            print(f"ERROR {filepath}: {e}")
