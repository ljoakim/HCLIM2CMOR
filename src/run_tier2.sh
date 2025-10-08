#!/bin/bash

python master_wrapper.py -s $1 -v ua200m,ua250m,ua300m
python master_wrapper.py -s $1 -v va200m,va250m,va300m
python master_wrapper.py -s $1 -v wsgsmax,z0,cape
