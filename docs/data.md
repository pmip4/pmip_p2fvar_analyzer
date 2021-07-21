# Data

This repository contains two kinds of data. There are files resulting from running the Climate Variability Diagnostics Package, which gives a single file per simulation stored in NetCDF format, and then some spreadsheets collating together individual numbers from across the ensemble (stored in data_frames as csv files).  

## Data Frames

These spreadsheets are in comma separated value format. They can be downloaded and read in using software such as Excel. To read into Python, you can use pandas

> import pandas as pd

> df = pd.read_csv('file.csv') 

The file called `ESGF_doi.csv` contains the digital object identifiers for every simulation on the Earth System Grid Federation. Ideally, these should be cited by every paper using the simulation data and hopefully collating them here makes this easier. 

If a simulation's value is listed as -999.00 then is should be treated as a missing number. Generally this is becuase the simulation has not been performed, although a small number result from the required output variable not being available

### Climate Modes
These tables collate together indices used to track different modes of (interannual) climate variability. 

The modes defined by timeseries are summarised by the temporal standard deviation of the index
- [Atlantic Meridional Mode](https://github.com/pmip4/pmip_p2fvar_analyzer/tree/master/data_frames/climate_modes/amm_timeseries_mon.csv)
- [Altantic Multidecadal Oscillation](https://github.com/pmip4/pmip_p2fvar_analyzer/tree/master/data_frames/climate_modes/amo_timeseries_mon.csv)
- [Atlantic Zonal Mode or Atlantic Nino](https://github.com/pmip4/pmip_p2fvar_analyzer/tree/master/data_frames/climate_modes/atl3_timeseries_mon.csv)
- [Southern Annular Mode](https://github.com/pmip4/pmip_p2fvar_analyzer/tree/master/data_frames/climate_modes/sam_mon.csv)
- [Indian Ocean Dipole](https://github.com/pmip4/pmip_p2fvar_analyzer/tree/master/data_frames/climate_modes/iod_timeseries_mon.csv)
- [El Nino-Southern Oscillation via Nino34](https://github.com/pmip4/pmip_p2fvar_analyzer/tree/master/data_frames/climate_modes/nino34.csv)
- [Tropical Indian Ocean](https://github.com/pmip4/pmip_p2fvar_analyzer/tree/master/data_frames/climate_modes/tropical_indian_ocean.csv)
- [South Tropical Atlantic](https://github.com/pmip4/pmip_p2fvar_analyzer/tree/master/data_frames/climate_modes/south_tropical_atlantic.csv)
- [North Tropical Atlantic](https://github.com/pmip4/pmip_p2fvar_analyzer/tree/master/data_frames/climate_modes/north_tropical_atlantic.csv)
- [Southern Ocean](https://github.com/pmip4/pmip_p2fvar_analyzer/tree/master/data_frames/climate_modes/southern_ocean.csv)

The modes defined by principal compenents are summarised by the spatial standard deviation of the pattern
- [Northern Annular Mode](https://github.com/pmip4/pmip_p2fvar_analyzer/tree/master/data_frames/climate_modes/nam_pattern_mon.csv)
- [Pacific Decadal Oscillation](https://github.com/pmip4/pmip_p2fvar_analyzer/tree/master/data_frames/climate_modes/pdo_pattern_mon.csv)
- [Interdecadal Pacific Oscillation](https://github.com/pmip4/pmip_p2fvar_analyzer/tree/master/data_frames/climate_modes/ipo_pattern_mon.csv)
- [North Atlantic Oscillation](https://github.com/pmip4/pmip_p2fvar_analyzer/tree/master/data_frames/climate_modes/nao_pattern_djf.csv)

### Monsoon Domains
Interannual time series of the areal extent and area-averaged rainfall of the global monsoon domain, as well as each of the 7 regional monsoon domains were computed for each simulation. The means and standard deviation of each time series are collated into various spreadsheets. The 7 regional monsoon domains are abbreviated as:

````{list-table}
---
header-rows: 1
---
* - Acronym 
  - Domain
* - AUSMC
  - Australian and the Maritime Continent
* - EAS
  - Eastern Asia
* - NAF
  - Northern Africa
* - NAMS
  - North America Monsoon System
* - SAF
  - Southern Africa
* - SAMS
  - South America Monsoon System
* - SAS
  - Southern Asia
````

### AR5 Regions
The means and standards of monthly resolution area-averaged time series for every region used in IPCC Assessment Report 5. See <http://www.ipcc-data.org/guidelines/pages/ar5_regions.html> for definitions of the regions and explanations of their abbreviations.

### Common Measures
Some metrics that people often compute from the simulations are summarised: 
- [Global mean surface temparature](https://github.com/pmip4/pmip_p2fvar_analyzer/tree/master/data_frames/common_measures/global_mean_temperature_changes.csv)  
- [Area averaged rainfall over the Northern Hemisphere land](https://github.com/pmip4/pmip_p2fvar_analyzer/tree/master/data_frames/common_measures/NH_terrestrial_rainfall.csv) (mm/day using present-day land/sea mask)
- [Atlantic Meridional Overtuning Circulation](https://github.com/pmip4/pmip_p2fvar_analyzer/tree/master/data_frames/common_measures/amoc_timeseries_ann.csv) (maximum at 30oN below 500m in Sv) 
- [Arctic sea ice minimum extent](https://github.com/pmip4/pmip_p2fvar_analyzer/tree/master/data_frames/common_measures/sic_nh_extent_climo_min.csv)
- [Arctic sea ice minimum area](https://github.com/pmip4/pmip_p2fvar_analyzer/tree/master/data_frames/common_measures/sic_nh_area_climo_min.csv)

### Temperature Changes in Latitude Bands
The change in temperature in 30o latitude bands over land, ocean and both are collated in this directory. This files have been collected from individual publications and ported into the similar format. They make the same assumptions about changing land sea masks. These files were used as input to IPCC WG1 AR6 Fig 3.2b 

## NetCDF files

The repository comes bundled with a compressed file (tar.gz). These files contain a small subset of the available fields- just the spatial annual mean, JJA and DJF surface temperature and precipitation. It can be uncompressed with `tar -xf PMIP4_tas_pr_data.tar.gz`.  

## Source of CMIP6-PMIP4 model output

Nearly all the data associated with this repository originates from the [Earth System Grid Federation](https://esgf-index1.ceda.ac.uk/projects/esgf-ceda/). The full listing of the files that sit within the curated ESGF replica at UCL is available via the [pmip4 GitHub repositories](https://github.com/pmip4/UCL_curated_ESGF_replica). Additional data has been provided by:
* Deepak Chandan (University of Toronto, CCSM4-UofT)
* Charlie Williams (University of Bristol, HadGEM3-GC31-LR)
* Vittoria Guarino (British Antarctic Survey, HadGEM3-GC31-LR)
* <https://psl.noaa.gov/data/20thC_Rean/> for the 20th Century Reanalysis (Compo et al, 2011)
