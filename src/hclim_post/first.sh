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
    ncks -h -A -v $1,rotated_pole ${WORKDIR}/${EXPPATH}/cclm_const.nc ${OUTDIR1}/$1.nc
  else
    echov "File for constant variable $1 already exists. Skipping..."
  fi
  }

#... functions for building time series
function timeseries {  # building a time series for a given quantity
  cd ${INDIR1}/${CURRDIR}
  if [[ ${1} != "pr" && ${1} != "hfls" && ${1} != "rsus" && ${1} != "rlus" && ${1} != "wsgsmax" && ${1} != "mrro" && ${1} != "evspsbl" && ! -f ${1}_${2}_${NAMETAG}_${CURRENT_DATE}0100.nc ]]
  then
    echo "No files found for variable $1 for current month in  ${INDIR1}/${CURRDIR}. Skipping month..." 
  elif [[ ${1} == "pr"  && ! -f prrain_fp_${NAMETAG}_${CURRENT_DATE}0100.nc || ! -f prgrpl_fp_${NAMETAG}_${CURRENT_DATE}0100.nc || ! -f prsnow_fp_${NAMETAG}_${CURRENT_DATE}0100.nc ]]
  then 
    echo "Not all files found to create pr for current month in  ${INDIR1}/${CURRDIR}. Skipping month..." 
  elif [[ ${1} == "hfls"  && ! -f hfls_eva_fp_${NAMETAG}_${CURRENT_DATE}0100.nc || ! -f hfls_sbl_fp_${NAMETAG}_${CURRENT_DATE}0100.nc ]]
  then
    echo "Not all files found to create hfls for current month in  ${INDIR1}/${CURRDIR}. Skipping month..." 
  elif [[ ${1} == "rsus"  && ! -f rsds_fp_${NAMETAG}_${CURRENT_DATE}0100.nc || ! -f rsns_fp_${NAMETAG}_${CURRENT_DATE}0100.nc ]]
  then
    echo "Not all files found to create rsus for current month in  ${INDIR1}/${CURRDIR}. Skipping month..." 
  elif [[ ${1} == "rlus"  && ! -f rlds_fp_${NAMETAG}_${CURRENT_DATE}0100.nc || ! -f rlns_fp_${NAMETAG}_${CURRENT_DATE}0100.nc ]]
  then 
    echo "Not all files found to create rlus for current month in  ${INDIR1}/${CURRDIR}. Skipping month..." 
  elif [[ ${1} == "mrro"  && ! -f mrros_sfx_${NAMETAG}_${CURRENT_DATE}0100.nc || ! -f mrrod_sfx_${NAMETAG}_${CURRENT_DATE}0100.nc ]]
  then
    echo "Not all files found to create mrro for current month in  ${INDIR1}/${CURRDIR}. Skipping month..." 
  elif [[ ${1} == "wsgsmax"  && ! -f ugsm_fp_${NAMETAG}_${CURRENT_DATE}0100.nc || ! -f vgsm_fp_${NAMETAG}_${CURRENT_DATE}0100.nc ]]
  then
    echo "Not all files found to create wsgsmax for current month in  ${INDIR1}/${CURRDIR}. Skipping month..." 
  elif [[ ${1} == "evspsbl"  && ! -f evspsbl_sfx_${NAMETAG}_${CURRENT_DATE}0100.nc || ! -f evspsbs_sfx_${NAMETAG}_${CURRENT_DATE}0100.nc || ! -f ${OUTDIR1}/${YYYY_MM}/mrro_ts.nc ]]
  then
    echo "Not all files found to create evspsbl for current month in  ${INDIR1}/${CURRDIR}. Skipping month..." 


  elif [ ! -f ${OUTDIR1}/${YYYY_MM}/$1_ts.nc ] ||  ${overwrite}
  then
    echon "Linking/calculating time series for variable $1"
    
    if [[ ${1} == "pr" ]]
    then
     echon "Summing precipitaion parts and deccumulating (setting negative values to zero)"
     file_prrain=prrain_fp_${NAMETAG}_${CURRENT_DATE}0100.nc
     file_prsnow=${file_prrain/'prrain_'/'prsnow_'}
     file_prgrpl=${file_prrain/'prrain_'/'prgrpl_'}

     cdo add $file_prgrpl $file_prsnow ${OUTDIR1}/${YYYY_MM}/pr_ts.nc.tmp0
     cdo add $file_prrain ${OUTDIR1}/${YYYY_MM}/pr_ts.nc.tmp0 ${OUTDIR1}/${YYYY_MM}/pr_ts.nc.tmp1
     ncap2 -h -s 'pr=prrain(1:$time.size-1, :, :)-prrain(0:$time.size-2, :, :);' ${OUTDIR1}/${YYYY_MM}/pr_ts.nc.tmp1 ${OUTDIR1}/${YYYY_MM}/pr_ts.nc.tmp2
     cdo -r selname,pr ${OUTDIR1}/${YYYY_MM}/pr_ts.nc.tmp2 ${OUTDIR1}/${YYYY_MM}/pr_ts.nc.tmp3
     cdo -r delete,timestep=1 ${OUTDIR1}/${YYYY_MM}/pr_ts.nc.tmp3 ${OUTDIR1}/${YYYY_MM}/pr_ts.nc.tmp4
     cdo -r setrtoc,-Inf,0,0 ${OUTDIR1}/${YYYY_MM}/pr_ts.nc.tmp4 ${OUTDIR1}/${YYYY_MM}/$1_ts.nc

     [ -f ${OUTDIR1}/${YYYY_MM}/pr_ts.nc.tmp0 ] && rm ${OUTDIR1}/${YYYY_MM}/pr_ts.nc.tmp0
     [ -f ${OUTDIR1}/${YYYY_MM}/pr_ts.nc.tmp1 ] && rm ${OUTDIR1}/${YYYY_MM}/pr_ts.nc.tmp1
     [ -f ${OUTDIR1}/${YYYY_MM}/pr_ts.nc.tmp2 ] && rm ${OUTDIR1}/${YYYY_MM}/pr_ts.nc.tmp2
     [ -f ${OUTDIR1}/${YYYY_MM}/pr_ts.nc.tmp3 ] && rm ${OUTDIR1}/${YYYY_MM}/pr_ts.nc.tmp3
     [ -f ${OUTDIR1}/${YYYY_MM}/pr_ts.nc.tmp4 ] && rm ${OUTDIR1}/${YYYY_MM}/pr_ts.nc.tmp4

    elif [[ ${1} == @(hfss|hfls_eva|hfls_sbl|mrrod|mrros|rids|rlds|rlns|rlnt|rsdsdir|rsds|rsdt|rsns|rsnt|snm|prrain) ]]
    then
     echon "Deccumulating " ${1} 
     cdo -r deltat ${1}_${2}_${NAMETAG}_${CURRENT_DATE}0100.nc ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc

    elif [[ ${1} == "hfls" ]]
    then
     echon "Deccummulating and summing hfls parts "
     cdo -f nc4c deltat hfls_eva_fp_${NAMETAG}_${CURRENT_DATE}0100.nc ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp1
     cdo chname,hfls_eva,hfls ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp1 ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp2 

     cdo -f nc4c deltat hfls_sbl_fp_${NAMETAG}_${CURRENT_DATE}0100.nc ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp3    
     cdo chname,hfls_sbl,hfls ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp3 ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp4

     cdo add ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp2 ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp4 ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc

     [ -f ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp1 ] && rm ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp1
     [ -f ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp2 ] && rm ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp2
     [ -f ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp3 ] && rm ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp3
     [ -f ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp4 ] && rm ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp4

    elif [[ ${1} == "rsus" ]]
    then
     echon "Deccummulating and subtracting rs parts"
     cdo -f nc4c deltat rsds_fp_${NAMETAG}_${CURRENT_DATE}0100.nc ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp1
     cdo chname,rsds,rsus ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp1 ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp2
     
     cdo -f nc4c deltat rsns_fp_${NAMETAG}_${CURRENT_DATE}0100.nc ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp3
     cdo chname,rsns,rsus ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp3 ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp4

     cdo sub ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp2 ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp4 ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc

     [ -f ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp1 ] && rm ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp1
     [ -f ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp2 ] && rm ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp2
     [ -f ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp3 ] && rm ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp3
     [ -f ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp4 ] && rm ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp4


    elif [[ ${1} == "rlus" ]]
    then
     echon "Deccummulating and subtracting rl parts"
     cdo -f nc4c deltat rlds_fp_${NAMETAG}_${CURRENT_DATE}0100.nc ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp1
     cdo chname,rlds,rlus ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp1 ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp2

     cdo -f nc4c deltat rlns_fp_${NAMETAG}_${CURRENT_DATE}0100.nc ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp3
     cdo chname,rlns,rlus ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp3 ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp4

     cdo sub ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp2 ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp4 ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc

     [ -f ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp1 ] && rm ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp1
     [ -f ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp2 ] && rm ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp2
     [ -f ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp3 ] && rm ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp3
     [ -f ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp4 ] && rm ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp4

    elif [[ ${1} == "mrro" ]]
    then
     echon "Deccummulating and adding mrro parts"
     cdo -f nc4c deltat mrros_sfx_${NAMETAG}_${CURRENT_DATE}0100.nc ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp1
     cdo chname,mrros,mrro ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp1 ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp2

     cdo -f nc4c deltat mrrod_sfx_${NAMETAG}_${CURRENT_DATE}0100.nc ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp3
     cdo chname,mrrod,mrro ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp3 ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp4

     cdo add ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp2 ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp4 ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc

     [ -f ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp1 ] && rm ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp1
     [ -f ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp2 ] && rm ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp2
     [ -f ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp3 ] && rm ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp3
     [ -f ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp4 ] && rm ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp4

    elif [[ ${1} == "wsgsmax" ]]
    then
     echon "Adding wind gust parts"
     cdo merge ugsm_fp_${NAMETAG}_${CURRENT_DATE}0100.nc vgsm_fp_${NAMETAG}_${CURRENT_DATE}0100.nc ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp1 
     cdo expr,"wsgsmax=sqrt(ugsm*ugsm+vgsm*vgsm);" ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp1 ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc

     [ -f ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp1 ] && rm ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp1

    elif [[ ${1} == "evspsbl" ]]
    then
     echon "Deccummulating and adding evspsbl parts, and add time_bnds (from mrro_ts)"
     cdo -f nc4c deltat evspsbl_sfx_${NAMETAG}_${CURRENT_DATE}0100.nc ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp1
     cdo -f nc4c deltat evspsbs_sfx_${NAMETAG}_${CURRENT_DATE}0100.nc ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp2
     cdo -ensmean ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp1 ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp2 ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc
    
     ncks -A -v time_bnds ${OUTDIR1}/${YYYY_MM}/mrro_ts.nc ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc

     [ -f ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp1 ] && rm ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp1
     [ -f ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp2 ] && rm ${OUTDIR1}/${YYYY_MM}/${1}_ts.nc.tmp2

    else
     ln -s ${PWD}/${1}_${2}_${NAMETAG}_${CURRENT_DATE}0100.nc ${OUTDIR1}/${YYYY_MM}/$1_ts.nc
    fi
  else
    echov "Time series for variable $1 already exists. Skipping..."
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
  if [ ! -d ${INDIR1}/${YYYY} ]
  then
    echo "Cannot find input directory for year ${YYYY}. Transfering from ${ARCHDIR} ..."
    if [ -d ${ARCHDIR}/${YYYY} ] 
    then
      ln -s ${ARCHDIR}/${YYYY} ${INDIR1}/${YYYY}
    elif [ -f ${ARCHDIR}/*${YYYY}.tar ]
    then
      tar -xf ${ARCHDIR}/*${YYYY}.tar -C ${INDIR1}
    else
      echo "Cannot find .tar file or extracted archive in archive directory! Exiting..."
      skip=true  
    fi
  fi
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
