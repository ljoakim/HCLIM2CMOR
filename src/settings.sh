#!/bin/bash

#-------------------------------------------------------------------------
# Settings for the first step of the CMOR process
# 
# Matthias Göbel 
#
#-------------------------------------------------------------------------

# Simulation details used for creating a directory structure 
GCM=CNRM-ESM2-1    # driving GCM
EXP=historical     # driving experiment name

#-------------------------------------------
# Time settings

# processing range:
START_DATE=1951 # Start year for processing (if not given in command line YYYY)
STOP_DATE=2014  # End year for processing (if not given in command line YYYY)

#-------------------------------------------
# Directory path settings

export BASEDIR=${HOME}/CMOR_HCLIM43/HCLIM2CMOR    # directory where the scripts are placed 
export DATADIR=${HOME}/CMOR_HCLIM43/HCLIM2CMOR/data       # directory where all the data will be placed (typically at /scratch/)

# scripts directory
SRCDIR=${BASEDIR}/src                # directory where the post processing scripts are stored
SRCDIR_POST=${BASEDIR}/src/hclim_post # directory where the subscripts are stored

WORKDIR=${DATADIR}/work/post/${GCM}_${EXP} # work directory, CAUTION: WITH OPTION "--clean" ALL FILES IN THIS FOLDER WILL BE DELETED AFTER PROCESSING!
LOGDIR=${DATADIR}/work/logs         # logging directory

# input/output directories and name of files
INDIR_BASE=/nobackup/rossby27/proj/rossby/joint_exp/cordex/202202/run/archive           # base where the input is located (in sub-directories YYYY/MM/01/00)
FXDIR=/nobackup/rossby27/proj/rossby/joint_exp/cordex/202202/run/archive/1950/08/01/00/ # location of constant files (orog etc.)
NAMETAG=EUR11_EUR11_ALADIN43_v1_CNRMESM21_r1i1p1f2_hist                                 # file nameing of the input files, i.e. var_NAMETAG_date.nc
OUTDIR=${DATADIR}/work/input_CMORlight/EUR11_ALADIN43_v1_CNRMESM21_r1i1p1f2_hist       # output directory for the annual files (to be used as input to CMOR python tool)

#-------------------------------------------
# Other settings
NBOUNDCUT=8          # number of boundary lines to be cut off in the time series data
proc_list="tas pr"   # which variables to process (set proc_all=false for this to take effect); separated by spaces. Can also be provided on the command line.
proc_all=false       # process all available variables (not only those in proc_list)
LFILE=1              # set LFILE=1 IF ONLY primary fields (given out by HCLIM) should be created and =2 for only secondary fields (additionally calculated for CORDEX); for any other number both types of fields are calculated
