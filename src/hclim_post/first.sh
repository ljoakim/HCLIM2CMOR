#!/bin/bash

#
# Burkhardt Rockel / Helmholtz-Zentrum Geesthacht, modified by Matthias Göbel / ETH Zürich
# Initial Version: 2009/09/02
# Latest Version:  2017/09/15 
# HCLIM Version: Autumn 2019, Andreas Dobler / MET Norway
#


#function to process constant variables
function constVar {
  if [ ! -f ${OUTDIR1}/$1.nc ] ||  ${overwrite}
  then
    echon "Building file for constant variable $1"
    echon "TO BE DONE!!" #ncks -h -A -v $1,rotated_pole ${WORKDIR}/${EXPPATH}/cclm_const.nc ${OUTDIR1}/$1.nc
  else
    echov "File for constant variable $1 already exists. Skipping..."
  fi
  }

#... functions for building time series
function timeseries {  # building a time series for a given quantity
  cd ${INDIR1}/${CURRDIR}
  #Check whether necessary files exist
  if [[ ${1} != @(mrro|prhmax|clwvi|sfcWindmax|siconca|sund|tasmax|tasmin|tos|ts_water|wsgsmax) ]] && [ ! -f ${1}_${2}_${NAMETAG}_?hr_${CURRENT_DATE}010000-${NEXT_DATE}010000.nc ]
  then
    echov "No sub-daily files found for variable $1 for current month in  ${INDIR1}/${CURRDIR}. Skipping month..." 

  elif [[ ${1} == "mrro" && ! -f mrros_sfx_${NAMETAG}_6hr_${CURRENT_DATE}010000-${NEXT_DATE}010000.nc || ! -f mrrod_sfx_${NAMETAG}_6hr_${CURRENT_DATE}010000-${NEXT_DATE}010000.nc ]]
  then
    echov "Not all files found to create (6hr) mrro for current month in  ${INDIR1}/${CURRDIR}. Skipping month..." 

  elif [[ ${1} == "prhmax" && ! -f pr_fp_${NAMETAG}_1hr_${CURRENT_DATE}010000-${NEXT_DATE}010000.nc  ]]
  then
    echov "Not all files found to create (1hr) prhmax for current month in  ${INDIR1}/${CURRDIR}. Skipping month..." 

  elif [[ ${1} == "clwvi" && ! -f clivi_fp_${NAMETAG}_1hr_${CURRENT_DATE}010000-${NEXT_DATE}010000.nc || ! -f clqvi_fp_${NAMETAG}_1hr_${CURRENT_DATE}010000-${NEXT_DATE}010000.nc ]]
  then
    echov "Not all files found to create (1hr) clwvi for current month in  ${INDIR1}/${CURRDIR}. Skipping month..." 

  elif [[ ${1} == @(sfcWindmax|siconca|sund|tasmax|tasmin|tos|ts_water|wsgsmax) ]] && [ ! -f ${1}_${2}_${NAMETAG}_day_${CURRENT_DATE}010000-${NEXT_DATE}010000.nc ]
  then
    echov "No daily files found for variable $1 for current month in  ${INDIR1}/${CURRDIR}. Skipping month..." 

  #Link/calulate
  elif [ ! -f ${OUTDIR1}/${YYYY_MM}/$1_ts.nc ] ||  ${overwrite}
  then
    echon "Linking/calculating time series for variable $1"
    
    if [[ ${1} == "mrro" ]]
    then
     echon "Summing mrro parts"
     cdo -f nc4c chname,mrros,mrro mrros_sfx_${NAMETAG}_6hr_${CURRENT_DATE}010000-${NEXT_DATE}010000.nc ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp1
     cdo -f nc4c chname,mrrod,mrro mrrod_sfx_${NAMETAG}_6hr_${CURRENT_DATE}010000-${NEXT_DATE}010000.nc ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp2

     cdo add ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp1 ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp2 ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc

     [ -f ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp1 ] && rm ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp1
     [ -f ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp2 ] && rm ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp2

    elif [[ ${1} == prhmax ]]
    then 
     echon "Calculating daily prhmax from hourly pr"
     cdo -f nc4c daymax pr_fp_${NAMETAG}_1hr_${CURRENT_DATE}010000-${NEXT_DATE}010000.nc ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp1 
     cdo -f nc4c chname,pr,prhmax ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp1  ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc

     [ -f ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp1 ] && rm ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp1

    elif [[ ${1} == "clwvi" ]]
    then
     echon "Summing clwvi parts"
     cdo -f nc4c chname,clivi,clwvi clivi_fp_${NAMETAG}_1hr_${CURRENT_DATE}010000-${NEXT_DATE}010000.nc ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp1
     cdo -f nc4c chname,clqvi,clwvi clqvi_fp_${NAMETAG}_1hr_${CURRENT_DATE}010000-${NEXT_DATE}010000.nc ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp2

     cdo add ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp1 ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp2 ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc

     [ -f ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp1 ] && rm ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp1
     [ -f ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp2 ] && rm ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp2

    elif [[ ${1} ==  mrs[fo]l* || ${1} ==  tsl*  ]] #SKIP FOR THE MOMENT. TO do: sum/merge layers. First 3 layers: hourly, rest 6-hourly
    then
     echov "Merging of mult-layer soil variable $1 not implemented yet"
     #ln -s ${PWD}/${1}_${2}_${NAMETAG}_1hr_${CURRENT_DATE}010000-${NEXT_DATE}010000.nc ${OUTDIR1}/${YYYY_MM}/$1_ts.nc
     
    elif [[ ${1} == @(sfcWindmax|siconca|sund|tasmax|tasmin|tos|ts_water|wsgsmax) ]] #daily values
    then
     ln -s ${PWD}/${1}_${2}_${NAMETAG}_day_${CURRENT_DATE}010000-${NEXT_DATE}010000.nc ${OUTDIR1}/${YYYY_MM}/$1_ts.nc

    else
     ln -s ${PWD}/${1}_${2}_${NAMETAG}_?hr_${CURRENT_DATE}010000-${NEXT_DATE}010000.nc ${OUTDIR1}/${YYYY_MM}/$1_ts.nc
    fi

  else
    : #echov "Time series for variable $1 already exists. Skipping..."
  fi
}


###################################################

if [ ! -d ${WORKDIR}/${EXPPATH} ]
then
  mkdir -p ${WORKDIR}/${EXPPATH}
fi

if [ ! -d ${INDIR1} ]
then
  mkdir -p ${INDIR1}
fi

YYYY=$(echo ${CURRENT_DATE} | cut -c1-4)
MM=$(echo ${CURRENT_DATE} | cut -c5-6)
MMint=${MM}
if [ $(echo ${MM} | cut -c1) -eq 0 ]
then
  MMint=$(echo ${MMint} | cut -c2  )
fi



#################################################
# Post-processing loop
#################################################


while [ ${CURRENT_DATE} -le ${STOP_DATE} ]
do
  YYYY_MM=${YYYY}_${MM}
  CURRDIR=${YYYY}
  echon "################################"
  echon "# Processing time ${YYYY_MM}"
  echon "################################"

  skip=false
  # step ahead in time
  MMint=$(python -c "print(int("${MMint}")+1)")
  if [ ${MMint} -ge 13 ]
  then
    MMint=1
    YYYY_next=$(python -c "print(int("${YYYY}")+1)")
  else
    YYYY_next=${YYYY}
  fi

  if [ ${MMint} -le 9 ]
  then
    MM_next=0${MMint}
  else
    MM_next=${MMint}
  fi

  NEXT_DATE=${YYYY_next}${MM_next}
  NEXT_DATE2=${YYYY_next}_${MM_next}

  if ! ${skip}
  then
    if [ ! -d ${OUTDIR1}/${YYYY_MM} ]
    then
      mkdir -p ${OUTDIR1}/${YYYY_MM}
    fi

    DATE_START=$(date +%s)
    DATE1=${DATE_START}

    ##################################################################################################
    # build time series
    ##################################################################################################

    export IGNORE_ATT_COORDINATES=1  # setting for better rotated coordinate handling in CDO

    #... cut of the boundary lines from the constant data file and copy it
#    if [ ! -f ${WORKDIR}/${EXPPATH}/cclm_const.nc ]
#    then
#      echon "Copy constant file"
#      ncks -h -d rlon,${NBOUNDCUT},${IESPONGE} -d rlat,${NBOUNDCUT},${JESPONGE} ${INDIR1}/${YYYY}/output/out01/lffd*c.nc ${WORKDIR}/${EXPPATH}/cclm_const.nc
#    fi
  
    #start timing
    DATE_START=$(date +%s)

    #process constant variables
    #constVar FR_LAND
    #constVar HSURF
    #constDone=true

    #build time series for selected variables
    source ${SRCDIR_POST}/timeseries.sh

    #stop timing and print information
    DATE2=$(date +%s)
    SEC_TOTAL=$(python -c "print(${DATE2}-${DATE_START})")
    echon "Time for postprocessing: ${SEC_TOTAL} s"
  
  fi

  if [ ! "$(ls -A ${OUTDIR1}/${YYYY_MM})" ] 
  then
    rmdir ${OUTDIR1}/${YYYY_MM}
  fi

  CURRENT_DATE=${NEXT_DATE}
  YYYY=${YYYY_next}
  MM=${MM_next}
done
