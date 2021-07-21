# PMIP4 past2future analyzer 

This repository contains materials to lower the entry barriers to analyzing climate model simulations created for the [Palaeoclimate Model Intercomparison Project](https://pmip.lsce.ipsl.fr/). It is described in Zhao et al (2021) entitled "Workflow and tools to analyze the PMIP4-CMIP6 ensemble", which is under consideration for publication at Geoscientific Model Development at <https://doi.org/10.5194/gmd-2021-249>.

There is information about what this repository contains and what you can do with at [ReadTheDocs](https://pmip-p2fvar-analyzer.readthedocs.io/en/latest/). However you're welcome to just poke around.

It contains several elements of summary data for PMIP4-CMIP6 and PMIP3-CMIP5, which we hope will be useful. These are stored in two locations depending on their format. 2D fields of surface temperature and precipitation come bundled with the repository (for annual mean, summer and winter). These are stored in a zipped tape archive in `data_netcdfs/`, which is automatically unpacked. Common metric and indices that can be quanified by a single number are collected together in a series of spreadsheets. These spreadsheets are stored in the directory `data_frames/` as csv files. Additionally this directory contians the DOIs of all of the simulations, so to make it easier to incorporate these citations into any publications. 

## Using this repository
You are welcome to use this resource as a repository of summary data, and download individual files. The most convenient manner to do this is to clone the repository with git, or download a zip file of it, using the button above. It would be great if you would contribute your own analysis scripts to the effort, which you can do by forking the repository and then sending us a pull request. 

We have invested some effort into making this resource be more than just place to hold data and code, but to also become a research tool in itself. You can download a docker image of this whole repository. This image not includes the code and data, but also bundles in all the required software needed to interact visually with the data through Jupyter and create your own plots of the data.

The docker image is available from [Docker Hub](https://hub.docker.com/r/chrisbrierley/testing-pmip4_past2future).
