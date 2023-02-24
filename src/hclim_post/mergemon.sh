#!/bin/ksh
#-------------------------------------------------------------------------
# Concatenats monthly time series files
# to annual file for a given time period of years and creates additional 
# fields required by CORDEX
# 
# K. Keuler, Matthias Göbel 
# latest version: 15.09.2017
# HCLIM Version: Autumn 2019, Andreas Dobler / MET Norway
# HCLIM43 Version: Spring 2023, Andreas Dobler / MET Norway
#-------------------------------------------------------------------------

typeset -Z2 MM MA ME MP MMA MME DHH EHH
typeset -Z4 YY YYA YYE YP


#---------------------------------------------------------------------
PERM=755 #Permission settings for output files

export IGNORE_ATT_COORDINATES=0

#variables
# all HCLIM variables representing a time interval (min, max, average, accumulated)
accu_list="tasmax tasmin pr evspsbl clt rsds rlds prc prsn mrros mrrod snm tauu tauv sfcWindmax sund rsdsdir rsus rlus rlut rsdt rsut hfls hfss wsgsmax clh clm cll rsnscs rlnscs rsntcs rlntcs"
  
#all instantaneous variables
inst_list="tas huss hurs ps psl sfcWind uas vas ts mrfso mrso snw snc snd siconca zmla prw clivi clqvi ua1000 ua925 ua850 ua700 ua600 ua500 ua400 ua300 ua250 ua200 va1000 va925 va850 va700 va600 va500 va400 va300 va250 va200 ta1000 ta925 ta850 ta700 ta600 ta500 ta400 ta300 ta250 ta200 hus1000 hus925 hus850 hus700 hus600 hus500 hus400 hus300 hus250 hus200 zg1000 zg925 zg850 zg700 zg600 zg500 zg400 zg300 zg250 zg200 ua50m ua100m ua150m va50m va100m va150m ta50m hus50m z0 cape ua300m va300m" 

# constant variables
const_list="orog sftlf sfturf sftlaf" #Include the following? sftgif (constant 0) mrsofc rootd dtb areacella (constant 12.5 km x 12.5km)

#additional variables
add_list="clwvi mrro prhmax" #tsl mrfsos mrsfl mrsos mrsol: TO BE ADDED, not implemented yet (multi-layer vars)

#-----------------------------------------------------------------------

# create subdirectory for full time series
[[ -d ${OUTDIR} ]] || mkdir -p  ${OUTDIR}
#Create and change to WORKDIR
[[ -d ${WORKDIR} ]] || mkdir -p  ${WORKDIR} 
cd ${WORKDIR}
#################################################
YY=$YYA

#constant variables
if ${create_const}
then
 for constVar in ${const_list}
 do 
   if [[ ! -e ${OUTDIR}/${constVar}/${constVar}.nc ]] || ${overwrite} 
   then
     if [[ -e ${FXDIR}/${constVar}_clim_${NAMETAG}_fx.nc ]]
     then
       echon "Copy constant variable ${constVar}.nc to output folder"
       [[ -d ${OUTDIR}/${constVar} ]] || mkdir ${OUTDIR}/${constVar}
       cp ${FXDIR}/${constVar}_clim_${NAMETAG}_fx.nc ${OUTDIR}/${constVar}/${constVar}.nc
     elif [[ ${constVar} == "sftlf" ]]
      then
       echon "Creating constant variable ${constVar}.nc in output folder (sftlf = sftnf + sfturf)"
       [[ -d ${OUTDIR}/${constVar} ]] || mkdir ${OUTDIR}/${constVar}
       cdo add ${FXDIR}/sftnf_clim_${NAMETAG}_fx.nc ${FXDIR}/sfturf_clim_${NAMETAG}_fx.nc ${OUTDIR}/${constVar}/${constVar}.nc
       ncrename -h -v sftnf,${constVar} ${OUTDIR}/${constVar}/${constVar}.nc
       ncatted -h -a long_name,${constVar},o,c,"Percentage of the Grid Cell Occupied by Land" ${OUTDIR}/${constVar}/${constVar}.nc
       ncatted -h -a standard_name,${constVar},o,c,"land_area_fraction" ${OUTDIR}/${constVar}/${constVar}.nc
     else
       echo "Required constant variable file(s) not in input folder ${FXDIR}! Skipping this variable..."
     fi
   fi
 done
fi


while [[ ${YY} -le ${YYE} ]]      # year loop
do
  echo ""
  echo "####################"
  echo ${YY}
  echo "####################"
  DATE1=$(date +%s)
	
  #check if directories for all months exist
  MMA=01 #first month of each yearly time-series
  MME=12 #last month of each yearly time-series
  MM=${MMA}
  start=true
  endmonth=${MME}
  while [[ ${MM} -le ${endmonth} ]] 
  do 
    if [[ ! -d ${INDIR_BASE}/${YY}/${MM}/01/00/ ]] 
    then
      echo "Directory ${INDIR_BASE}/${YY}/${MM}/01/00 does not exist!"
      if ${start}
      then
        (( MMA=MMA+1))
      else
        (( MME=MMA-1))
      fi
    else
      start=false
    fi
    (( MM=MM+1 ))
  done
  if ! ${proc_all} 
  then
    FILES=${proc_list} 
  else
    FILES=$(ls ${INDIR_BASE}/${YY}/${MMA}/01/00/*_${NAMETAG}.nc)
  fi
  

  if [[ ${LFILE} -ne 2 ]] 
  then
  # concatenate monthly files to annual file
    for FILE in ${FILES}        # var name loop
    do
      FILEIN=$(basename ${FILE})
      
      if  ${proc_all}  
      then
        FILEOUT=$(echo ${FILEIN} | sed s/_.*//) # cut off everything after var name
      else
        FILEOUT=${FILE} 
      fi
      
      varname=${FILEOUT}

      #process variable if in proc_list or if proc_all is set
      if [[ ${proc_list} =~ (^|[[:space:]])${varname}($|[[:space:]]) ]] || ${proc_all}
      then
        if ls ${OUTDIR}/${FILEOUT}/${FILEOUT}_${YY}* 1> /dev/null 2>&1 
        then
          if ${overwrite} 
          then    
            echon ""
            echon ${FILEOUT}
            echon "File for variable ${FILEOUT} and year ${YY} already exists. Overwriting..."
          else
            echov ""
            echov "File for variable ${FILEOUT} and year ${YY} already exists. Skipping..."
            continue
          fi
        else
          echon ""
          echon ${FILEOUT}
        fi

      else
        continue
      fi
      


      # determine if current variable is an accumulated or instantaneous quantity
      if [[ ${accu_list} =~ (^|[[:space:]])${varname}($|[[:space:]]) ]]
      then
        LACCU=1
        echon "${varname} is an accumulated variable"
      elif [[ ${inst_list} =~ (^|[[:space:]])${varname}($|[[:space:]]) ]]
      then
        LACCU=0
        echon "${varname} is an instantaneous variable"
      elif [[ ${add_list} =~ (^|[[:space:]])${varname}($|[[:space:]]) ]]
      then
        continue
      else
        echo "Error for ${varname}: neither contained in accu_list nor in inst_list! Skipping..."
        continue
      fi
      
      

      FILELIST=""
      MA=${MMA}
      ME=${MME}
      MM=${MA}
       
      while [[ ${MM} -le ${ME} ]] 
      do 
        if [ ! -f ${INDIR_BASE}/${YY}/${MM}/01/00/${FILEOUT}_*_${NAMETAG}*.nc ] 
        then
          echo "WARNING: File ${INDIR_BASE}/${YY}/${MM}/01/00/${FILEOUT}_*_${NAMETAG}*.nc does not exist! Continue anyway..."
          #continue 2
        fi
        FILELIST="$(echo ${FILELIST}) $(ls ${INDIR_BASE}/${YY}/${MM}/01/00/${FILEOUT}_*_${NAMETAG}*.nc | head -n 1)" #only first one, i.e. with highest temporal frequency
        (( MM=MM+1 ))
      done
      echon "Concatenate files"
      echov "${FILELIST}"
      # concatenate monthly files to yearly file
      FILEIN=${FILEOUT}_${YY}${MA}-${YY}${ME}.nc
      export SKIP_SAME_TIME=1
      cdo mergetime ${FILELIST} ${FILEIN}.tmp
      # cut boundaries
      let "STARTIDX = NBOUNDCUT + 1"
      XSIZE=`cdo griddes ${FILEIN}.tmp | head | grep xsize  | sed "s/.*= //g"`
      YSIZE=`cdo griddes ${FILEIN}.tmp | head | grep ysize  | sed "s/.*= //g"`
      let "ENDIDX = XSIZE - NBOUNDCUT"
      let "ENDIDY = YSIZE - NBOUNDCUT"
      echon "Cutting boundaries with $NBOUNDCUT lines."
      echov "Original grid size: ${XSIZE}x${YSIZE}. Cutting ${STARTIDX}:${ENDIDX},${STARTIDX}:${ENDIDY} (x,y)"
      cdo selindexbox,${STARTIDX},${ENDIDX},${STARTIDX},${ENDIDY} ${FILEIN}.tmp ${FILEIN}

      [ -f ${FILEIN}.tmp ] && rm ${FILEIN}.tmp
      [ -f ${FILEIN}.tmp2 ] && rm ${FILEIN}.tmp2

      # extract attribute units from variable time -> REFTIME in ... since XX-XX-XX ...
      RT=$(ncks -m -v time  ${FILEIN} | grep -E 'since' | sed s/".*since "//)

      REFTIME="days since "${RT}
      # extract number of timesteps and timestamps
      NT=$(cdo -s ntime ${FILEIN})
      VT=($(cdo -s showtimestamp ${FILEIN}))
      TYA=$(echo ${VT[0]} | cut -c1-4)
      TMA=$(echo ${VT[0]} | cut -c6-7)
      TDA=$(echo ${VT[0]} | cut -c9-10)
      THA=$(echo ${VT[0]} | cut -c12-13)
      TmA=$(echo ${VT[0]} | cut -c15-16)
      TDN=$(echo ${VT[1]} | cut -c9-10)
      THN=$(echo ${VT[1]} | cut -c12-13)
      TYE=$(echo ${VT[-1]} | cut -c1-4)
      TME=$(echo ${VT[-1]} | cut -c6-7)
      TDE=$(echo ${VT[-1]} | cut -c9-10)
      THE=$(echo ${VT[-1]} | cut -c12-13)
      TmE=$(echo ${VT[-1]} | cut -c15-16)

      (( DHH=(TDN-TDA)*24+THN-THA ))
      (( EHH=24-DHH ))

      echov "First date: ${VT[0]} "
      echov "Last date: ${VT[-1]} "
      echov "Number of timesteps: $NT"
      echov "Time step: $DHH h"
      echov "New reference time: ${REFTIME}"

      #create output directory
      [[ -d ${OUTDIR}/${FILEOUT} ]] || mkdir ${OUTDIR}/${FILEOUT}
      
      if [[ ${LACCU} -eq 1 ]] 
      then
        ENDFILE=${OUTDIR}/${FILEOUT}/${FILEOUT}_${TYA}${TMA}${TDA}${THA}${TmA}-${TYE}${TME}${TDE}${THE}${TmE}.nc
        if [[ ${FILEOUT} == @(pr|prsn|prc) ]]
        then
        # set negative precip values to zero  
          echon "Setting negative precipitation to zero"
          cdo setrtoc,-Inf,0,0 ${FILEIN} ${ENDFILE} 
          ncatted -O -h -a units,time,o,c,"${REFTIME}" -a units,time_bnds,o,c,"${REFTIME}" ${ENDFILE}
        else
        # set reference time       
          echov "Modifying reference time"
          ncatted -O -h -a units,time,o,c,"${REFTIME}" -a units,time_bnds,o,c,"${REFTIME}" ${FILEIN} ${ENDFILE}
        fi
      else
  #   Check dates in files for instantaneous variables
        if [[ ${TDA} -eq 01 && ${THA} -eq 00 ]]
        then
          echov "First date of instantaneous file is OK"
          cp ${FILEIN} ${FILEOUT}_tmp1_${YY}.nc          
        else
          echo "ERROR: Start date " ${TDA} ${THA}
          echo in "${FILEIN} "
          echo "is not correct.  Skip year for this variable..."
          continue       
        fi
        if [[ ${TDE} -ge 28  && ${THE} -eq ${EHH} ]]
        then
          echov "Last date of instantaneous file is OK"
          mv ${FILEOUT}_tmp1_${YY}.nc ${FILEOUT}_tmp3_${YY}.nc
        elif  [[ ${TDE} -eq 01 && ${THE} -eq 00 ]]
        then
          (( NTM=NT-2 )) 
          echov "Last date of instantaneous file is removed"
          ncks -O -h -d time,0,${NTM} ${FILEOUT}_tmp1_${YY}.nc ${FILEOUT}_tmp3_${YY}.nc
          #change TDE
          VT=($(cdo -s showtimestamp ${FILEOUT}_tmp3_${YY}.nc))
          TDE=$(echo ${VT[-1]} | cut -c9-10)
        else
          echo "ERROR: END date " ${TDE} ${THE}
          echo in "${FILEIN} "
          echo "is not correct.  Skip year for this variable..."
          echo ${EHH}
          continue       
        fi
        ENDFILE=${OUTDIR}/${FILEOUT}/${FILEOUT}_${TYA}${TMA}${TDA}0000-${YY}${ME}${TDE}${EHH}00.nc
  #    remove time_bnds from instantaneous fields and set reference time
        echov "Modifying reference time"
        ncks -O -C -h -x -v time_bnds ${FILEOUT}_tmp3_${YY}.nc ${ENDFILE}
        ncatted -O -h -a units,time,o,c,"${REFTIME}" -a bounds,time,d,, ${ENDFILE}    
      fi


      echov "Output to $ENDFILE"
  #   change permission of final file
      chmod ${PERM} ${ENDFILE}
  #
  #   clean temporary files
      rm -f ${FILEOUT}_tmp?_${YY}.nc
      #rm ${FILEIN}

    done                    # var name loopende
#
  fi                              #concatenate part



  #
  # create additional fields required by ESGF
  #
  function create_add_vars {
    name1=$1 #first input variable
    name2=$2 #second input variable
    name3=$3 #output variable
    formula=$4 #formula how to create output variable; cdo command
    standard_name=$5
        
    if [[ ${proc_list} =~ (^|[[:space:]])${name3}($|[[:space:]]) ]] || ${proc_all}
    then
      echon ""
      echon " Create additional fields for CORDEX"
      file1=$(ls ${OUTDIR}/${name1}/${name1}_${YY}${MMA}0100*.nc) 
      if [[ ${name2} == "" ]]
      then
        file2=""
      else
        file2=$(ls ${OUTDIR}/${name2}/${name2}_${YY}${MMA}0100*.nc)
      fi
      echov "Input files and formula:"
      echov "$file1"
      echov "$file2"
      echov "$formula"

      if [[ -e ${file1} ]]
      then
        ((c1 = ${#file1}-27 )) 
        ((c2 = ${#file1}-3 ))
        DATE=$(ls ${file1} |cut -c${c1}-${c2})
        file3=${OUTDIR}/${name3}/${name3}_${DATE}.nc
        if [[ ! -e ${file3} ]] ||  ${overwrite}
        then
          echon "Create ${file3}"
          [[ -d ${OUTDIR}/${name3} ]] || mkdir  ${OUTDIR}/${name3} 
          cdo ${formula} ${file1} ${file2} temp1_${YY}.nc
          cdo -f nc4c chname,${name1},${name3} temp1_${YY}.nc ${file3}
          ncatted -h -a long_name,${name3},d,, ${file3}
          ncatted -h -a FA_name,${name3},d,, ${file3}
          ncatted -h -a par,${name3},d,, ${file3}
          ncatted -h -a standard_name,${name3},m,c,${standard_name} ${file3}
          chmod ${PERM} ${file3}
          rm temp1_${YY}.nc
        else
          echov "$(basename ${file3})  already exists. Use option -O to overwrite. Skipping..."
        fi
      else
        echo "Input Files for generating ${name3} are not available"
      fi
    fi
  }

  if [[ ${LFILE} -ne 1 ]] 
  then
    
    #Additional fields for CORDEX not directly availabl directly available in the model output

    # Total runoff: mrro
    create_add_vars "mrros" "mrrod" "mrro" "add" "runoff_flux"
    
    # Cloud water: clwvi
    create_add_vars "clivi" "clqvi" "clwvi" "add" "atmosphere_mass_content_of_cloud_condensed_water"
    
    # Daily max of hourly precip: prhmax
    create_add_vars "pr" "" "prhmax" "daymax" "precipitation_flux" 
  fi
  
  (( YY=YY+1 ))
  DATE2=$(date +%s)
	SEC_TOTAL=$(python -c "print(${DATE2}-${DATE1})")
	echon "Time for postprocessing: ${SEC_TOTAL} s"
  done                                      # year loopend

