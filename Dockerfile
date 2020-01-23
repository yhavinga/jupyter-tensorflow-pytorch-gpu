# The image below has
# Ubuntu 18.04
# Cuda 10.1
# CuDNN: libcudnn7/unknown,now 7.6.4.38-1+cuda10.1 amd64 [installed,upgradable to: 7.6.5.32-1+cuda10.2]
# Tensorflow 2.1.0
# system wide Python 3.6.9
# 

FROM tensorflow/tensorflow:2.1.0-gpu-py3

ARG NB_USER="jovyan"
ARG NB_UID="1000"
ARG NB_GID="100"

USER root

# Install some basic utilities
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    ca-certificates \
    sudo \
    git \
    libx11-6 \
    locales \
    fonts-liberation \
 && rm -rf /var/lib/apt/lists/*

RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen

#--------- Conda config from jupyter notebook base-notebook ---------------
# Configure environment
ENV CONDA_DIR=/opt/conda \
    SHELL=/bin/bash \
    NB_USER=$NB_USER \
    NB_UID=$NB_UID \
    NB_GID=$NB_GID \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8
ENV PATH=$CONDA_DIR/bin:$PATH \
    HOME=/home/$NB_USER

# Add a script that we will use to correct permissions after running certain commands
ADD fix-permissions /usr/local/bin/fix-permissions

# Enable prompt color in the skeleton .bashrc before creating the default NB_USER
RUN sed -i 's/^#force_color_prompt=yes/force_color_prompt=yes/' /etc/skel/.bashrc

# Create NB_USER wtih name jovyan user with UID=1000 and in the 'users' group
# and make sure these dirs are writable by the `users` group.
RUN echo "auth requisite pam_deny.so" >> /etc/pam.d/su && \
    sed -i.bak -e 's/^%admin/#%admin/' /etc/sudoers && \
    sed -i.bak -e 's/^%sudo/#%sudo/' /etc/sudoers && \
    useradd -m -s /bin/bash -N -u $NB_UID $NB_USER && \
    mkdir -p $CONDA_DIR && \
    chown $NB_USER:$NB_GID $CONDA_DIR && \
    chmod g+w /etc/passwd && \
    fix-permissions $HOME && \
    fix-permissions "$(dirname $CONDA_DIR)"

USER $NB_UID
WORKDIR $HOME

# Setup work directory for backward-compatibility
RUN mkdir /home/$NB_USER/work && \
    fix-permissions /home/$NB_USER

USER root

# Install conda as jovyan and check the md5 sum provided on the download site
ENV MINICONDA_VERSION=4.7.12.1 \
    CONDA_VERSION=4.8.1

RUN cd /tmp && \
    wget --quiet https://repo.continuum.io/miniconda/Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh && \
    echo "81c773ff87af5cfac79ab862942ab6b3 *Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh" | md5sum -c - && \
    /bin/bash Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh -f -b -p $CONDA_DIR && \
    rm Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh

RUN echo "conda ${CONDA_VERSION}" >> $CONDA_DIR/conda-meta/pinned && \
    $CONDA_DIR/bin/conda config --system --prepend channels conda-forge && \
    $CONDA_DIR/bin/conda config --system --set auto_update_conda false && \
    $CONDA_DIR/bin/conda config --system --set show_channel_urls true

RUN $CONDA_DIR/bin/conda install --quiet --yes conda && \
    $CONDA_DIR/bin/conda update --all --quiet --yes && \
    conda list python | grep '^python ' | tr -s ' ' | cut -d '.' -f 1,2 | sed 's/$/.*/' >> $CONDA_DIR/conda-meta/pinned && \
    conda clean --all -f -y && \
    rm -rf /home/$NB_USER/.cache/yarn && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER

# Pin numpy on 1.16.4 to prevent tensorflow triggering numpy 1.17 warnings
RUN conda install -y numpy=1.16.4 && \
    conda clean --all -f -y

#---------------- PyTorch stuff ----------------------
# Pin PyTorch on Python 3.7 and Cuda 10.1
#    cuda100=1.0 \
RUN conda install -y -c pytorch \
    magma-cuda101 \
    "pytorch=1.4.0=py3.7_cuda10.1.243_cudnn7.6.3_0" \
    torchvision=0.5.0 && \
    conda clean --all -f -y

#---------------- Notebook stuff ----------------------
# Install Tini
RUN conda install --quiet --yes 'tini=0.18.0' && \
    conda list tini | grep tini | tr -s ' ' | cut -d ' ' -f 1,2 >> $CONDA_DIR/conda-meta/pinned && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER

# Install Jupyter Notebook, Lab, and Hub
# Generate a notebook server config
# Cleanup temporary files
# Correct permissions
# Do all this in a single RUN command to avoid duplicating all of the
# files across image layers when the permissions change
RUN conda install --quiet --yes \
    'notebook=5.7.8' \
    'jupyterhub=1.0.0' \
    'jupyterlab=1.0.1' && \
    conda clean --all -f -y && \
    npm cache clean --force && \
    jupyter notebook --generate-config && \
    rm -rf $CONDA_DIR/share/jupyter/lab/staging && \
    rm -rf /home/$NB_USER/.cache/yarn && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER

#---------------- minimal notebook ----------------
# Install all OS dependencies for fully functional notebook server
# ffmpeg for matplotlib anim
RUN apt-get update && apt-get install -yq --no-install-recommends \
    emacs \
    inkscape \
    jed \
    libsm6 \
    libxext-dev \
    libxrender1 \
    lmodern \
    netcat \
    pandoc \
    python-dev \
    texlive-fonts-extra \
    texlive-fonts-recommended \
    texlive-generic-recommended \
    texlive-latex-base \
    texlive-latex-extra \
    texlive-xetex \
    tzdata \
    nano \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

USER $NB_UID

# Install Python 3 packages
RUN conda install --quiet --yes \
    'conda-forge::blas=*=openblas' \
    'ipywidgets' \
    'pandas' \
    'numexpr' \
    'matplotlib' \
    'scipy' \
    'scikit-learn' \
    'scikit-image' \
    'seaborn' \
    'sympy' \
    'cython' \
    'patsy' \
    'statsmodels' \
    'cloudpickle' \
    'dill' \
    'dask' \
    'numba' \
    'bokeh' \
    'sqlalchemy' \
    'hdf5' \
    'h5py' \
    'vincent' \
    'beautifulsoup4' \
    'protobuf' \
    'xlrd'  && \
    conda clean --all -f -y && \
    # Activate ipywidgets extension in the environment that runs the notebook server
    jupyter nbextension enable --py widgetsnbextension --sys-prefix && \
    # Also activate ipywidgets extension for JupyterLab
    # Check this URL for most recent compatibilities
    # https://github.com/jupyter-widgets/ipywidgets/tree/master/packages/jupyterlab-manager
    jupyter labextension install @jupyter-widgets/jupyterlab-manager@^1.0.0 && \
    jupyter labextension install jupyterlab_bokeh@1.0.0 && \
    npm cache clean --force && \
    rm -rf $CONDA_DIR/share/jupyter/lab/staging && \
    rm -rf /home/$NB_USER/.cache/yarn && \
    rm -rf /home/$NB_USER/.node-gyp && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER

# Install facets which does not have a pip or conda package at the moment
RUN cd /tmp && \
    git clone https://github.com/PAIR-code/facets.git && \
    cd facets && \
    jupyter nbextension install facets-dist/ --sys-prefix && \
    cd && \
    rm -rf /tmp/facets && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER

# Import matplotlib the first time to build the font cache.
ENV XDG_CACHE_HOME /home/$NB_USER/.cache/
RUN MPLBACKEND=Agg python -c "import matplotlib.pyplot" && \
    fix-permissions /home/$NB_USER

# Jupyter Notebook
EXPOSE 8888

# Configure container startup
ENTRYPOINT ["tini", "-g", "--"]
CMD ["start-notebook.sh"]

# Add local files as late as possible to avoid cache busting
COPY start.sh /usr/local/bin/
COPY start-notebook.sh /usr/local/bin/
COPY start-singleuser.sh /usr/local/bin/
COPY jupyter_notebook_config.py /etc/jupyter/

# Fix permissions on /etc/jupyter as root
USER root
RUN fix-permissions /etc/jupyter/

# Switch back to jovyan to avoid accidental container runs as root
USER $NB_UID

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
# nvidia-utils-440 needs to match the Cuda version on which this
# image was build.
RUN apt-get update && apt-get install -yq --no-install-recommends \
    cmake \
    libncurses5-dev \
    libncursesw5-dev \
    nvidia-utils-440 \
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
