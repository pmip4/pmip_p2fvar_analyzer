# data_netcdf

This directory contains data relating to fields and time series from the simulations.

## Structure
Information from each individual simulation is stored in within a single file. These are collated by the experiment name, resulting in the following sub-directories:
-  1pctCO2
-  abrupt4xCO2
-  historical
-  lgm
-  lgm-cal-adj
-  lig127k
-  lig127k-cal-adj
-  midHolocene
-  midHolocene-cal-adj
-  piControl

## Initial data subset
It is impractical to store all the possible data fields in the repository, so only a small subset is bundled along with the repository. This subset is stored in `PMIP4_tas_pr_data.tar.gz`, which is a zipped tape archive. It contains only the annual mean surface temperature and precipitation, as variables called `tas_spatialmean_ann` and `pr_spatialmean_ann` respectively. 

## Full data set
The full dataset is stored in single zipped tape archive. It is 6 GB large, as is therefore not contained on either the GitHub repository or within the Docker image. It can be downloaded from <http://www2.geog.ucl.ac.uk/~p2f-v/PMIP4-PMIP3_allfields.tar.gz>.
