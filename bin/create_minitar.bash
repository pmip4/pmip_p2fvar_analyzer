#!/bin/bash

# Intent - to create a smaller version of the tar file provided in the GitHub repository
# usage:
# bin/create_minitar.bash 

full_data_netcdf="/mnt/d/Dropbox/Chris/research/curated_ESGF_replica/cvdp_data/"
mini_data_netcdf="/mnt/d/GitHub/pmip_p2fvar_analyzer/data_netcdf/"

pmip4_globstr="{AWI-ESM-1-1-LR,CNRM-CM6-1,CESM2,EC-Earth3-LR,FGOALS-f3-L,FGOALS-g3,GISS-E2-1-G,HadGEM3-GC31-LL,INM-CM4-8,IPSL-CM6A-LR,MIROC-ES2L,MPI-ESM1-2-LR,MRI-ESM2-0,NESM3,NorESM1-F,NorESM2,UofT-CCSM-4}"

# for piControl
pi_varlist="monsoon_intensity monsoon_summer_rainrate sic_nh_area_climo monsoon_rain_NAF monsoon_area_NAF amoc_mean_ann"
pi_files=`ls $full_data_netcdf/piControl/{AWI-ESM-1-1-LR,CNRM-CM6-1,CESM2,EC-Earth3-LR,FGOALS-f3-L,FGOALS-g3,GISS-E2-1-G,HadGEM3-GC31-LL,INM-CM4-8,IPSL-CM6A-LR,MIROC-ES2L,MPI-ESM1-2-LR,MRI-ESM2-0,NESM3,NorESM1-F,NorESM2,UofT-CCSM-4}*`
for fil in $pi_files
do
  echo $fil
  for var in $pi_varlist
  do
    # not all files will have the variables, so we'll add them indvidually
    ncks -A -v $var $fil $mini_data_netcdf/piControl/${fil##*/} 
  done
done

# for midHolocene
varlist="monsoon_intensity monsoon_summer_rainrate monsoon_rain_NAF monsoon_area_NAF amoc_mean_ann"
files=`ls $full_data_netcdf/midHolocene/{AWI-ESM-1-1-LR,CNRM-CM6-1,CESM2,EC-Earth3-LR,FGOALS-f3-L,FGOALS-g3,GISS-E2-1-G,HadGEM3-GC31-LL,INM-CM4-8,IPSL-CM6A-LR,MIROC-ES2L,MPI-ESM1-2-LR,MRI-ESM2-0,NESM3,NorESM1-F,NorESM2,UofT-CCSM-4}*`
for fil in $files
do
  echo $fil
  for var in $varlist
  do
    # not all files will have the variables, so we'll add them indvidually
    ncks -A -v $var $fil $mini_data_netcdf/midHolocene/${fil##*/} 
  done
done

# for midHolocene-cal-adj
varlist="sic_nh_area_climo"
files=`ls $full_data_netcdf/midHolocene-cal-adj/{AWI-ESM-1-1-LR,CNRM-CM6-1,CESM2,EC-Earth3-LR,FGOALS-f3-L,FGOALS-g3,GISS-E2-1-G,HadGEM3-GC31-LL,INM-CM4-8,IPSL-CM6A-LR,MIROC-ES2L,MPI-ESM1-2-LR,MRI-ESM2-0,NESM3,NorESM1-F,NorESM2,UofT-CCSM-4}*`
for fil in $files
do
  echo $fil
  for var in $varlist
  do
    # not all files will have the variables, so we'll add them indvidually
    ncks -A -v $var $fil $mini_data_netcdf/midHolocene-cal-adj/${fil##*/} 
  done
done

# for lig127k
varlist="monsoon_summer_rainrate"
files=`ls $full_data_netcdf/lig127k/{AWI-ESM-1-1-LR,CNRM-CM6-1,CESM2,EC-Earth3-LR,FGOALS-f3-L,FGOALS-g3,GISS-E2-1-G,HadGEM3-GC31-LL,INM-CM4-8,IPSL-CM6A-LR,MIROC-ES2L,MPI-ESM1-2-LR,MRI-ESM2-0,NESM3,NorESM1-F,NorESM2,UofT-CCSM-4}*`
for fil in $files
do
  echo $fil
  for var in $varlist
  do
    # not all files will have the variables, so we'll add them indvidually
    ncks -A -v $var $fil $mini_data_netcdf/lig127k/${fil##*/} 
  done
done
