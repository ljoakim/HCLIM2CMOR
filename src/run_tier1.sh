#!/bin/bash

case $2 in
    0)
        python master_wrapper.py -s $1 -v ua100m,va100m
        ;;
    1)
        # pr is core(!) but required for prhmax
        python master_wrapper.py -s $1 -v ts,prc,pr
        python master_wrapper.py -s $1 -v prsn,mrros,snm
        python master_wrapper.py -s $1 -v tauu,tauv,sfcWindmax,sund
        python master_wrapper.py -s $1 -v rsdsdir,rsus,rlus,rlut
        # Not requested, but required for other vars (mrro and clwvi)
        python master_wrapper.py -s $1 -v mrrod,clqvi
        ;;
    2)
        python master_wrapper.py -s $1 -v rsdt,rsut,hfls
        python master_wrapper.py -s $1 -v hfss,mrfso,mrso
        python master_wrapper.py -s $1 -v snw,snc,snd
        python master_wrapper.py -s $1 -v siconca,zmla,prw
        ;;
    3)
        python master_wrapper.py -s $1 -v clivi
        python master_wrapper.py -s $1 -v ua1000,ua925,ua850,ua700,ua600
        python master_wrapper.py -s $1 -v ua500,ua400,ua300,ua250,ua200
        python master_wrapper.py -s $1 -v va1000,va925,va850,va700,va600
        ;;
    4)
        python master_wrapper.py -s $1 -v va500,va400,va300,va250,va200
        python master_wrapper.py -s $1 -v ta1000,ta925,ta850,ta700,ta600
        python master_wrapper.py -s $1 -v ta500,ta400,ta300,ta250,ta200
        ;;
    5)
        python master_wrapper.py -s $1 -v hus1000,hus925,hus850,hus700,hus600
        python master_wrapper.py -s $1 -v hus500,hus400,hus300,hus250,hus200
        python master_wrapper.py -s $1 -v zg1000,zg925,zg850,zg700,zg600
        ;;
    6)
        python master_wrapper.py -s $1 -v zg500,zg400,zg300,zg250,zg200
        python master_wrapper.py -s $1 -v ua50m,ua150m,ta50m
        python master_wrapper.py -s $1 -v va50m,va150m,hus50m
        ;;
    7)
        # dependent on pr
        python master_wrapper.py -s $1 -v prhmax
        # 3d
        python master_wrapper.py -s $1 -v tsl
        # 3d
        python master_wrapper.py -s $1 -v mrfsos
        ;;
    8)
        # mrrod + mrros, clqvi + clivi
        python master_wrapper.py -s $1 -v mrro,clwvi
        # 3d
        python master_wrapper.py -s $1 -v mrsos
        # 3d
        python master_wrapper.py -s $1 -v mrsol
        ;;
    9)
        # 3d, after all others are finished
        # This run has issues, don't know why.
        # It often just stops near the end of processing.
        # May need more resources.
        python master_wrapper.py -s $1 -v mrsfl
        ;;
esac


# These vars we do not have:
# python master_wrapper.py -s $1 -v wa1000,wa925,wa850,wa700,wa600
# python master_wrapper.py -s $1 -v wa500,wa400,wa300,wa250,wa200
