#!/bin/bash

#-------------------------------------------------------------------------
# Settings for the first step of the CMOR process
# 
# Matthias Göbel 
#
#-------------------------------------------------------------------------

post_step=0 # to limit post processing to step 1 or 2, for all other values both steps are executed

# Simulation details used for creating a directory structure 
GCM=CNRM-ESM2-1    # driving GCM
EXP=historical     # driving experiment name

#-------------------------------------------
# Time settings

# processing range for step 1:
START_DATE=195101 # Start year and month for processing (if not given in command line YYYYMM)
STOP_DATE=201412  # End year and month for processing (if not given in command line YYYYMM)

# for step 2 (if different from step 1:
YYA= # Start year for processing YYYY
YYE= # End year for processing YYYY

#-------------------------------------------
# Directory path settings

export BASEDIR=${HOME}/CMOR_HCLIM43/HCLIM2CMOR    # directory where the scripts are placed 
export DATADIR=${HOME}/CMOR_HCLIM43/HCLIM2CMOR/data       # directory where all the data will be placed (typically at /scratch/)

# scripts directory
SRCDIR=${BASEDIR}/src                # directory where the post processing scripts are stored
SRCDIR_POST=${BASEDIR}/src/hclim_post # directory where the subscripts are stored

WORKDIR=${DATADIR}/work/post/${GCM}_${EXP} # work directory, CAUTION: WITH OPTION "--clean" ALL FILES IN THIS FOLDER WILL BE DELETED AFTER PROCESSING!
LOGDIR=${DATADIR}/work/logs         # logging directory

# input/output directory for first step
INDIR_BASE1=${DATADIR}/in                                 # base where the input is located 
EXPPATH=EUR11_ALADIN43_v1_CNRMESM21_r1i1p1f2_hist         # sub-directory of the experiment
NAMETAG=EUR11_EUR11_ALADIN43_v1_CNRMESM21_r1i1p1f2_hist   # file nameing of the input files, i.e. var_NAMETAG_date.nc
OUTDIR_BASE1=${DATADIR}/work/outputpost # output directory of the first step

# input/output directory for second step
INDIR_BASE2=${OUTDIR_BASE1}
OUTDIR_BASE2=${DATADIR}/work/input_CMORlight

#-------------------------------------------
# Special settings for second step
NBOUNDCUT=8          # number of boundary lines to be cut off in the time series data
proc_list="tas pr"   # which variables to process (set proc_all=false for this to take effect); separated by spaces
proc_all=false       # process all available variables (not only those in proc_list)
LFILE=1              # set LFILE=1 IF ONLY primary fields (given out by COSMO) should be created and =2 for only secondary fields (additionally calculated for CORDEX); for any other number both types of fields are calculated
