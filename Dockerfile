# Choose your desired base image
FROM jupyter/minimal-notebook:latest

# name your environment
ARG conda_env=pmip_p2fvar_analyzer

# alternatively, you can comment out the lines above and uncomment those below
# if you'd prefer to use a YAML file present in the docker build context

COPY environment.yml /home/$NB_USER/tmp/
RUN cd /home/$NB_USER/tmp/ && \
     conda env create -p $CONDA_DIR/envs/$conda_env -f environment.yml && \
     conda clean --all -f -y


# create Python 3.x environment and link it to jupyter
RUN $CONDA_DIR/envs/${conda_env}/bin/python -m ipykernel install --user --name=${conda_env} && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER

# any additional pip installs can be added by uncommenting the following line
# RUN $CONDA_DIR/envs/${conda_env}/bin/pip install

# prepend conda environment to path
ENV PATH $CONDA_DIR/envs/${conda_env}/bin:$PATH

# if you want this environment to be the default one, uncomment the following line:
ENV CONDA_DEFAULT_ENV ${conda_env}

RUN python -m pip install jupyterthemes
RUN python -m pip install --upgrade jupyterthemes
RUN python -m pip install jupyter_contrib_nbextensions
RUN jupyter contrib nbextension install --user
# enable the Nbextensions
RUN jupyter nbextension enable contrib_nbextensions_help_item/main
RUN jupyter nbextension enable autosavetime/main
RUN jupyter nbextension enable codefolding/main
RUN jupyter nbextension enable code_font_size/code_font_size
RUN jupyter nbextension enable code_prettify/code_prettify
RUN jupyter nbextension enable collapsible_headings/main
RUN jupyter nbextension enable comment-uncomment/main
RUN jupyter nbextension enable equation-numbering/main
RUN jupyter nbextension enable execute_time/ExecuteTime 
RUN jupyter nbextension enable gist_it/main 
RUN jupyter nbextension enable hide_input/main 
RUN jupyter nbextension enable spellchecker/main
RUN jupyter nbextension enable toc2/main
RUN jupyter nbextension enable toggle_all_line_numbers/main

ENV NODE_OPTIONS="--max-old-space-size=4096"
ENV JUPYTER_ENABLE_LAB=yes
RUN jupyter labextension install nbdime-jupyterlab --no-build && \
    jupyter labextension install @jupyter-widgets/jupyterlab-manager --no-build && \
    jupyter labextension install jupyter-matplotlib --no-build && \
    jupyter labextension install @jupyterlab/debugger --no-build && \
    jupyter labextension install jupyter-leaflet --no-build && \
    jupyter lab build && \
        jupyter lab clean && \
        jlpm cache clean && \
        npm cache clean --force && \
        rm -rf $HOME/.node-gyp && \
        rm -rf $HOME/.local && \
    fix-permissions $CONDA_DIR $HOME

# copy over the contents of the repository
RUN mkdir -p $HOME/notebooks $HOME/bin $HOME/data_frames $HOME/data_netcdf $HOME/ncl_scripts $HOME/ncl_output
COPY notebooks/* $HOME/notebooks/
COPY bin/* $HOME/bin/
COPY data_frames/ESGF_doi.csv $HOME/data_frames/
COPY data_netcdf/*tar.gz $HOME/data_netcdf/
COPY ncl_scripts/* $HOME/ncl_scripts/
RUN mkdir -p $HOME/data_frames/AR5_regions  $HOME/data_frames/climate_modes  $HOME/data_frames/common_measures  $HOME/data_frames/monsoon_domains  $HOME/data_frames/tempchange_latbands
COPY data_frames/AR5_regions/*.csv $HOME/data_frames/AR5_regions/
COPY data_frames/climate_modes/*.csv $HOME/data_frames/climate_modes/
COPY data_frames/common_measures/*.csv $HOME/data_frames/common_measures/
COPY data_frames/monsoon_domains/*.csv $HOME/data_frames/monsoon_domains/
COPY data_frames/tempchange_latbands/*.csv $HOME/data_frames/tempchange_latbands/

# setting juypter to run without needing to grab the token too
ENV JUPYTER_TOKEN='PMIP'

RUN jupyter trust notebooks/*ipynb 
