#!/bin/bash
# This script will create a .tar.gz file containing the data and put it on a sensible web-location for downloading.
# Written by Chris Brierley and only to be used by Chris (relies on stuff on UCL server).

#first define a little function to say whether a netcdf file has required variables
function hasvars {
  hasvars_DIR=$1
  hasvars_filename=$2
  hasvars_varnames=`ncdump -h $hasvars_DIR/$hasvars_filename | grep float | cut -d\( -f1 | cut -d\  -f2`
  if [[ $hasvars_varnames == *"pr_spatialmean_ann"* ]] && [[ $hasvars_varnames == *"tas_spatialmean_ann"* ]] 
  then
    return 1
  else
    return 0
  fi
}  

#set up some paths and aliases
CVDP_DATA_DIR="/home/p2f-v/public_html/PMIPVarData/cvdp_data_PMIP4"
REPO_DATA_DIR=`pwd`"/../data" #relative to here
anmn_vars="pr_spatialmean_ann,tas_spatialmean_ann"
seas_vars="pr_spatialmean_djf,pr_spatialmean_jja,tas_spatialmean_djf,tas_spatialmean_jja"

#Collect all the relevant data from the files
cd $CVDP_DATA_DIR
ncfiles=`ls *_*.cvdp_data.*-*.nc`
echo $ncfiles
cd $REPO_DATA_DIR
for ncfile in $ncfiles 
do
  echo working on $ncfile
  sub_dir=`echo $ncfile | cut -d. -f1 | cut -d_ -f2`
  mkdir -p $sub_dir
  hasvars $CVDP_DATA_DIR $ncfile
  if [ $? == 1 ]; then
    if [[ $sub_dir == *"midHolocene"* ]]  || [[ $sub_dir == *"lgm"* ]] || [[ $sub_dir == *"lig127k"* ]]
    then
      if [[ $sub_dir == *"cal-adj"* ]]
      then
        ncks -O -v $seas_vars $CVDP_DATA_DIR/$ncfile $sub_dir/$ncfile
      else
        ncks -O -v $anmn_vars $CVDP_DATA_DIR/$ncfile $sub_dir/$ncfile
      fi
    else
      ncks -O -v $anmn_vars $CVDP_DATA_DIR/$ncfile $sub_dir/$ncfile
      ncks -A -v $seas_vars $CVDP_DATA_DIR/$ncfile $sub_dir/$ncfile
    fi
  fi
done

#make a .tar.gz archive
rm PMIP4_tas_pr_data.tar.gz
tar -czf PMIP4_tas_pr_data.tar.gz */*.cvdp_data.*-*.nc
cp PMIP4_tas_pr_data.tar.gz ~/public_html/PMIPVarData/data/PMIP4_tas_pr_data.tar.gz