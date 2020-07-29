#!/bin/bash

#usage:
# scripts/find_ensemble_members.bash experiment_name variable_name data_dir

if [ -z "$3" ]
  then
    echo "usage: scripts/find_ensemble_members.bash experiment_name variable_name data_dir"
fi

for fil in $3/*$1.cvdp_data.*-*.nc
do
  foo=`ncdump -h $fil | grep float | grep $2\(`
  if [ $? == 0 ]; then
      echo $fil
  fi
done
