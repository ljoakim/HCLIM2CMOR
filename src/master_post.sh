#!/bin/ksh 

#module add nco cdo

#Check if all functions are available
funcs="ncrcat ncks ncap2 ncatted cdo"
for f in $funcs
do
  typ=$(type -p $f)
  if [ -z ${typ} ]  
  then
    echo "Necessary function $f is not available! Load respective module. Exiting..."
    exit
  fi
done

TIME1=$(date +%s)

source ./settings.sh

#default values
overwrite=false #overwrite output if it exists
n=true #normal printing mode
v=true #verbose printing mode
batch=false #create batch jobs continously always for one year
stopex=false
overwrite_arch=false
args=""
while [[ $# -gt 0 ]]
do
  key="$1"
  case $key in
      -h|--help)
      source ./help 
      exit
      ;;    
      -g|--gcm)
      GCM=$2
      args="${args} -g $2"
      shift
      ;;
      -x|--exp)
      EXP=$2
      args="${args} -x $2"
      shift
      ;;
       -s|--start)
      START_DATE=$2
      shift
      ;;
      -e|--end)
      STOP_DATE=$2
      args="${args} -e $2"
      shift
      ;;
      -F|--first_year) #only needed internally
      FIRST=$2
      shift
      ;;
      --first)
      post_step=1
      args="${args} --first"
      ;;
      --second)
      post_step=2
      args="${args} --second"
      ;;
      -S|--silent)
      n=false
      args="${args} -S"
      ;;
      -V|--verbose)
      v=true
      args="${args} -V"
      ;;
      -O|--overwrite)
      overwrite=true
      args="${args} -O"
      ;;
      --no_batch)
      batch=false
      args="${args} --no_batch"
      ;;
      --stopex)
      stopex=true
      ;;
      --overwrite_arch)
      overwrite_arch=true
      args="${args} --overwrite_arch"
      ;;
      *)
      echo "unknown option!"
      ;;
  esac
  shift
done

#folders
ARCHDIR=${ARCH_BASE}

INDIR1=${INDIR_BASE1}/${EXPPATH}
OUTDIR1=${OUTDIR_BASE1}/${EXPPATH}

INDIR2=${INDIR_BASE2}/${EXPPATH}
OUTDIR2=${OUTDIR_BASE2}/${EXPPATH}

#create logging directory
if [ ! -d ${LOGDIR} ]
then
  mkdir -p ${LOGDIR}
fi

if [ ! -d ${BASEDIR}/logs/cmorlight ]
then
  mkdir -p ${BASEDIR}/logs/cmorlight
fi

#log base names
CMOR=${LOGDIR}/${GCM}_${EXP}_CMOR_sh
xfer=${LOGDIR}/${GCM}_${EXP}_xfer
delete=${LOGDIR}/${GCM}_${EXP}_delete

#printing modes
function echov {
  if ${v}
  then
    echo $1
  fi
}

function echon {
  if ${n}
  then
   echo $1
  fi
}

#range for second script
YYA=$(echo ${START_DATE} | cut -c1-4) 
YYE=$(echo ${STOP_DATE} | cut -c1-4)

#initialize first year
if [ -z ${FIRST} ]  
then
  FIRST=${YYA}
fi

#if only years given: process from January of the year START_DATE to January of the year following STOP_DATE
if [ ${#START_DATE} -eq 4 ]
then
  START_DATE="${START_DATE}01"
else
  START_DATE=$(echo ${START_DATE} | cut -c1-6)
fi

if [ ${#STOP_DATE} -eq 4 ]
then
  (( STOP_DATE=STOP_DATE+1 ))
  STOP_DATE="${STOP_DATE}01"
else
  STOP_DATE=$(echo ${STOP_DATE} | cut -c1-6)
fi

if  [ ${post_step} -ne 2 ]
then
  CURRENT_DATE=${START_DATE}
  echo "######################################################"
  echo "First processing step"
  echo "######################################################"  
  echo "Start: " ${START_DATE}
  echo "Stop: " ${STOP_DATE}
  source ${SRCDIR_POST}/first.sh
fi


if [ ${post_step} -ne 1 ]
then
  echo ""
  echo "######################################################"
  echo "Second processing step"
  echo "######################################################"
  echo "Start: " ${YYA}
  echo "Stop: " ${YYE}
  source ${SRCDIR_POST}/second.sh
fi

echo "######################################################"
TIME2=$(date +%s)
SEC_TOTAL=$(python -c "print(${TIME2}-${TIME1})")
echo "total time for postprocessing: ${SEC_TOTAL} s"

