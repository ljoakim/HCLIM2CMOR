#!/bin/bash

python master_wrapper.py -s $1 -C -v orog,sftlf
python master_wrapper.py -s $1 -v tas,tasmax,tasmin,pr
python master_wrapper.py -s $1 -v evspsbl,huss,hurs,ps
python master_wrapper.py -s $1 -v psl,sfcWind,uas,vas
python master_wrapper.py -s $1 -v clt,rsds,rlds
