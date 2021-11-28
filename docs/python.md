# Python Notebooks

Python scripts ahave been written as notebooks. Jupyter Notebook is a web-based tool that can show the documentation, develop and run codes, and display the input and output of computation. The choice of notebooks allows documentation and outputs to be stored with the scripts. Most of the analysing and plotting processes in python have been written into functions, and they are stored in different scripts according to their purposes respectively. Each notebook is named according to its purpose and usage. These scripts all start with a set of six functions to collect the names of available models that have the variable in the experiment and their corresponding directory and filenames respectively and return a dictionary storing these information as "’model_name’:’directory/filename’", in which function `identify_ensemble_members` requires running [`find_experiment_ensemble_members.bash`](https://github.com/pmip4/pmip_p2fvar_analyzer/tree/master/bin/find_experiment_ensemble_members.bash) in [`bin`](https://github.com/pmip4/pmip_p2fvar_analyzer/tree/master/bin) directory to identify available ensemble members (i.e. model names) whose simulations have the target variable in the experiment. 

Currently, we provide five notebooks, with detailed documentations available in the script:
- [EnsembleMean_AnnualMean_SurfTempChange.ipynb](https://github.com/pmip4/pmip_p2fvar_analyzer/blob/master/notebooks/EnsembleMean_AnnualMean_SurfTempChange.ipynb)
   includes the functions to do ensemble analysis, and plot the resutls as spatial maps.
- [ensemble(mean)_TempPrecip(change)_more_options.ipynb](https://github.com/pmip4/pmip_p2fvar_analyzer/blob/master/notebooks/ensemble(mean)_TempPrecip(change)_more_options.ipynb)
   is similar to `EnsembleMean_AnnualMean_SurfTempChange.ipynb`, but having more options.
- [ensemblemean_monsoon_domian.ipynb](https://github.com/pmip4/pmip_p2fvar_analyzer/blob/master/notebooks/ensemblemean_monsoon_domian.ipynb)
   contains the process of producing Figure 5 of [Brierley et al. (2020)](https://cp.copernicus.org/articles/16/1847/2020/)
- [ensemble_line_scatter_plot_regionalmonsoon_seaice.ipynb](https://github.com/pmip4/pmip_p2fvar_analyzer/blob/master/notebooks/ensemble_line_scatter_plot_regionalmonsoon_seaice.ipynb)
   contains the process of producing Figures 6, 7 and 8 in Zhao et al. (2021).
- [Ensemble_mean_changes_in_AMOC.ipynb](https://github.com/pmip4/pmip_p2fvar_analyzer/blob/master/notebooks/Ensemble_mean_changes_in_AMOC.ipynb)
   gives an example of plotting AMOC (as Figure 5 in Zhao et al. 2021).
