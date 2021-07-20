# Data

This repository contains two kinds of data. There are files resulting from running the Climate Variability Diagnostics Package, which gives a single file per simulation stored in NetCDF format, and then some spreadsheets collating together individual numbers from across the ensemble (stored in data_frames as csv files).  

## Data Frames

These spreadsheets are in comma separated value format. They can be downloaded and read in using software such as Excel. To read into Python, you can use pandas

> import pandas as pd

> df = pd.read_csv('file.csv') 

The file called `ESGF_doi.csv` contains the digital object identifiers for every simulation on the Earth System Grid Federation. Ideally, these should be cited by every paper using the simulation data and hopefully collating them here  makes this easier. 

### climate_modes
These tables collate together indices used to track different modes of (interannual) climate variability. 

The modes defined by timeseries are summarised by the temporal standard deviation of the index
- [Atlantic Meridional Mode](amm_timeseries_mon.csv)
- [Altantic Multidecadal Oscillation](amo_timeseries_mon.csv)
- [Atlantic Zonal Mode or Atlantic Nino](atl3_timeseries_mon.csv)
- [Southern Annular Mode](sam_mon.csv)
- [Indian Ocean Dipole](iod_timeseries_mon.csv)
- [El Nino-Southern Oscillation via Nino34](nino34.csv)
- [Tropical Indian Ocean](tropical_indian_ocean.csv)
- [South Tropical Atlantic](south_tropical_atlantic.csv)
- [North Tropical Atlantic](north_tropical_atlantic.csv)
- [Southern Ocean](southern_ocean.csv)
The modes defined by principal compenents are summarised by the spatial standard deviation of the pattern
- [Northern Annular Mode](nam_pattern_mon.csv)
- [Pacific Decadal Oscillation](pdo_pattern_mon.csv)
- [Interdecadal Pacific Oscillation](ipo_pattern_mon.csv)
- [North Atlantic Oscillation](nao_pattern_djf.csv)

### monsoon_domains
Interannual time series of the areal extent and area-averaged rainfall of the global monsoon domain, as well as each of the 7 regional monsoon domains were computed for each simulation. The means and standard deviation of each time series are collated into various spreadsheets. The 7 regional monsoon domains are abbreviated as:

.. list-table:: Regional Monsoon Domains
   :widths: 50 50
   :header-rows: 1
   
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

### AR5_Regions
The means and standards of monthly resolution area-averaged time series for every region used in IPCC Assessment Report 5. See <http://www.ipcc-data.org/guidelines/pages/ar5_regions.html> for definitions of the regions and explanations of their abbreviations.

### common_measures
Some metrics that people often compute from the simulations are summarised: 
- [Global mean surface temparature](global_mean_temperature_changes.csv)  
- [Area averaged rainfall over the Northern Hemisphere land](NH_terrestrial_rainfall.csv) (mm/day using present-day land/sea mask)
- [Atlantic Meridional Overtuning Circulation](amoc_timeseries_ann.csv) (maximum at 30oN below 500m in Sv) 
- [Arctic sea ice minimum extent](sic_nh_extent_climo_min.csv)
- [Arctic sea ice minimum area](sic_nh_area_climo_min.csv)

### tempchange_latbands
The change in temperature in 30o latitude bands over land, ocean and both are collated in this directory. This files have been collected from individual publications and ported into the similar format. They make the same assumptions about changing land sea masks. These files were used as input to IPCC WG1 AR6 Fig 3.2b 

## NetCDF files

The repository comes bundled with a compressed file (tar.gz). These files contain a small subset of the available fields- just the spatial annual mean, JJA and DJF surface temperature and precipitation. It can be uncompressed with `tar -xf PMIP4_tas_pr_data.tar.gz`.  

## Source of CMIP6-PMIP4 model output

Nearly all the data associated with this repository originates from the [Earth System Grid Federation](https://esgf-index1.ceda.ac.uk/projects/esgf-ceda/). The full listing of the files that sit within the curated ESGF replica at UCL is available via the [pmip4 GitHub repositories](https://github.com/pmip4/UCL_curated_ESGF_replica). Additional data has been provided by:
* Deepak Chandan (University of Toronto, CCSM4-UofT)
* Charlie Williams (University of Bristol, HadGEM3-GC31-LR)
* Vittoria Guarino (British Antarctic Survey, HadGEM3-GC31-LR)
* <https://psl.noaa.gov/data/20thC_Rean/> for the 20th Century Reanalysis (Compo et al, 2011)