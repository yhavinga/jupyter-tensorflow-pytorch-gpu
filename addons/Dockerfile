FROM yhavinga/nvidia-pytorch-scipy-jupyter:pytorch1.0.1-cuda10.0-py3.7-ubuntu18.04

USER $NB_USER

#---------------- Final add-ons -------------
# PostgreSQL client
# Tensorboard
# Python-markdown in notebooks
# Quantopian libraries
# nbstripout to prevent cell output in git commits
# and some other add ons
# Unfortunately Quantopians zipline does not work with 3.7 yet.
#--------------------------------------------
RUN conda install --quiet --yes \
        'biobuilds::postgresql-client' \
        nodejs \
        Cython \
        psycopg2 && \
    conda install -c Quantopian \
	pyfolio \
	alphalens \
	qgrid && \
    conda install -c anaconda \
	mpi4py && \
    conda install -c conda-forge \
	pandas-datareader \
        ipython-sql \
        tensorboardx \
        nbstripout \
        jupyter_contrib_nbextensions \
        jupyter_nbextensions_configurator \
        jupyterlab-plotly-extension \
        hide_code && \
    conda clean --all -f -y

#------------- Pip installed final addons ----------
# (New RUN command, to prevent waiting for the lenghty conda resolution)
# Pixiedust debugger
# Python-markdown in notebooks
# Visualization libraries
# Financial data libraries
# OpenAI Gym
# and some other add ons
RUN jupyter nbextension enable python-markdown/main --sys-prefix && \
    jupyter nbextension enable hide_code/hide_code --sys-prefix && \
    jupyter labextension install @jupyterlab/git && \
    jupyter labextension install jupyterlab_tensorboard && \
    pip install jupyter_tensorboard \
	jupyterlab-git \
	pixiedust \
        tensorflow-gpu \
	tensorflow-hub \
        torchvision \
        scikit-image  \
        h5py-cache \
        torchnet \
	pixiedust \
	newspaper3k \
	quandl \
	mpl_finance \
	yfinance \
	folium \
	geojson \
	pyshp \
	google-cloud \
	google-cloud-datastore \
	google-api-python-client \
	google-auth-oauthlib \
	google-auth-httplib2 \
	google-cloud-bigquery \
	gym \
	baselines \
        graphviz && \
    jupyter serverextension enable --py jupyterlab_git && \
    jupyter labextension install @jupyterlab/toc && \
    jupyter labextension install jupyterlab-drawio && \
    npm cache clean --force && \
    rm -rf $CONDA_DIR/share/jupyter/lab/staging && \
    rm -rf /home/$NB_USER/.cache/yarn && \
    rm -rf /home/$NB_USER/.node-gyp && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER

USER root

#---------------- additional ubuntu packages ----------------
# Install handy cli tools. Cmake, libncurses are to make nvtop,
# that is included in 19.04 but not yet 18.04
# nvidia-utils-410 needs to match the Cuda version on which this
# image was build.
RUN apt-get update && apt-get install -yq --no-install-recommends \
    cmake \
    libncurses5-dev \
    libncursesw5-dev \
    nvidia-utils-410 \
    joe \
    less \
    htop \
    imagemagick \
    && \
    rm -rf /var/lib/apt/lists/*

#---- Built nvtop -----
RUN git clone https://github.com/Syllo/nvtop.git && \
    mkdir -p nvtop/build && \
    cd nvtop/build && \
    cmake .. -DNVML_RETRIEVE_HEADER_ONLINE=True && \
    make install

#--- git configuration to stripout cell output (for privacy reasons) ---
USER $NB_UID

RUN git config --global core.excludesfile ~/.gitignore_global && \
    echo "**/*.ipynb_checkpoints/" >> ~/.gitignore_global && \
    git config --global core.attributesfile ~/.gitattributes_global && \
    git config --global filter.nbstripout.clean '$(which nbstripout)' && \
    git config --global filter.nbstripout.smudge cat && \
    git config --global filter.nbstripout.required true && \
    echo "*.ipynb filter=nbstripout" >> ~/.gitattributes_global && \
    echo "*.ipynb diff=ipynb" >> ~/.gitattributes_global && \
    git config --global diff.ipynb.textconv '$(which nbstripout) -t' && \
    git config --global user.email "you@example.com" && \
    git config --global user.name "Your Name"

# Fix permissions on /etc/jupyter as root
RUN fix-permissions /etc/jupyter/

# Switch back to jovyan to avoid accidental container runs as root
USER $NB_UID
