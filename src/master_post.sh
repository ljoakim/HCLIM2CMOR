#!/bin/ksh 
#SBATCH -J master_post
#SBATCH -n 1
#SBATCH --mem-per-cpu 20000
#SBATCH -A cordex
#SBATCH -t 03:00:00
#SBATCH -o ${HCLIMDIR}/postprocess/HCLIM2CMOR/logs/master_post_%j.out

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
v=false #verbose printing mode
create_const=false #create constant variables
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
      YYA=$2
      shift
      ;;
      -e|--end)
      YYE=$2
      args="${args} -e $2"
      shift
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
      -C|--create_const)
      create_const=true
      args="${args} -C"
      ;;
      -p|--proc_list)
      proc_all=false
      proc_list=$2
      args="${args} -p $2"
      shift
      ;;
      *)
      echo "unknown option!"
      ;;
  esac
  shift
done

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

echo ""
echo "######################################################"
echo "Merging monthly time-series to annual ones"
echo "######################################################"
echo "Start: " ${YYA}
echo "Stop: " ${YYE}
source ${SRCDIR_POST}/mergemon.sh

echo "######################################################"
TIME2=$(date +%s)
SEC_TOTAL=$(python -c "print(${TIME2}-${TIME1})")
echo "total time for postprocessing: ${SEC_TOTAL} s"

