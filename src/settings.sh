#!/bin/bash

#-------------------------------------------------------------------------
# Settings for the first step of the CMOR process
# 
# Matthias Göbel 
#
#-------------------------------------------------------------------------

# Simulation details used for creating a directory structure 
SIMULATION=202201
GCM=ECMWF-ERA5    # driving GCM
EXP=evaluation     # driving experiment name
NAMETAG=EUR11_EUR11_ALADIN43_v1_ERA5_r1i1p1f1_eval # file nameing of the input files, i.e. var_NAMETAG_date.nc
CONSTANT_FOLDER=1950/08/01/00

# Overwritten in case the wrapper is used
SIMULATION=${OVERRIDE_SIMULATION:-${SIMULATION}}
GCM=${OVERRIDE_GCM:-${GCM}}
EXP=${OVERRIDE_EXP:-${EXP}}
NAMETAG=${OVERRIDE_NAMETAG:-${NAMETAG}}
CONSTANT_FOLDER=${OVERRIDE_CONSTANT_FOLDER:-${CONSTANT_FOLDER}}

#-------------------------------------------
# Directory path settings
export BASEDIR=${HCLIM2CMORDIR}                              # directory where the HCLIM2CMOR source root is placed
export DATADIR=${HCLIMDIR}/postprocess/HCLIM2CMOR/data_jl    # directory where all the data will be placed
WORKDIR=${SNIC_TMP}/work/post/${SIMULATION}_${GCM}_${EXP}    # work directory (typically at /scratch/)

# scripts directory
SRCDIR=${BASEDIR}/src                 # directory where the post processing scripts are stored
SRCDIR_POST=${BASEDIR}/src/hclim_post # directory where the subscripts are stored

LOGDIR=${DATADIR}/work/logs/post/${SIMULATION}                # logging directory

# input/output directories
INDIR_BASE=${CORDEX}/${SIMULATION}/run/archive                         # base where the input is located (in sub-directories YYYY/MM/01/00)
FXDIR=${CORDEX}/${SIMULATION}/run/archive/${CONSTANT_FOLDER}           # location of constant files (orog etc.)
OUTDIR=${DATADIR}/work/input_CMORlight/${NAMETAG}                        # output directory for the annual files (to be used as input to CMOR python tool)

#-------------------------------------------
# Other settings
NBOUNDCUT=8          # number of boundary lines to be cut off in the time series data
proc_list="tas tasmin tasmax pr"   # which variables to process (set proc_all=false for this to take effect); separated by spaces. Can also be provided on the command line.
proc_all=false       # process all available variables (not only those in proc_list)
LFILE=0              # set LFILE=1 IF ONLY primary fields (given out by HCLIM) should be created and =2 for only secondary fields (additionally calculated for CORDEX); for any other number both types of fields are calculated
