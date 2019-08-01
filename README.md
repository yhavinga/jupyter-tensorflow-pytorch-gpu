# nvidia-pytorch-scipy-jupyter

Ubuntu image with Cuda, Pytorch with GPU support, docker-stacks-style
jupyter and and conda installation.

# For who

If you have a Linux computer with a Nvidia GPU and want to use PyTorch in a Jupyter Notebook
or Jupyter Lab environment.

# On the docker host

* Following instructions from the [Nvidia Docker Documentation](https://github.com/NVIDIA/nvidia-docker/wiki/Installation-(version-2.0))
  to install drivers and configure docker to support the gpu as device.
* Note that since Docker 19.03 has native gpu support, `nvidia-docker2` is deprecated.

I am using on the host

* Ubuntu 18.04
* Nvidia 410 driver (to match cuda10.0 in the container)
* Docker-ce 18.09 (from [docker.com](https://docs.docker.com/install/linux/docker-ce/ubuntu/), not the ubuntu docker.io package)
* The 'old' `nvidia-docker2` (see the usage with docker-compose below) instead of `nvidia-container-toolkit`

# Installed software in this image

* Nvidia-ubuntu -> Ubuntu image with Cuda device drivers
* Docker-stacks -> Base, minimal and scipy notebooks
* Pytorch -> python 3.6 pytorch package with GPU support
* Python PostgreSQL client
* and some useful lab and nb extensions such as ExecuteTime
* NOTE: nbstripout is configured to prevent accidental publishing of notebook output
  to git repositories - if you wonder why output is not visible in committed notebooks,
  nbstripout is the cause. 

# Usage

There are many ways to tell docker to start a container with gpu support,
see `https://devblogs.nvidia.com/gpu-containers-runtime/` and `https://github.com/NVIDIA/nvidia-docker`
for more information.

I prefer to start containers with parameters in a docker-compose file, instead of supplying a
long list of arguments to a docker run command.
To use the supplied docker-compose file, you need `nvidia-docker2` installed with a version that
matches your docker version. Note that the `runtime` directive in the docker-compose file is
only available in docker-compose file versions >=2.3 and <3.

    $ cat docker-compose.yml
    version: '2.3'
    
    services:
    
      jupyterlab-torch:
        image: yhavinga/nvidia-pytorch-scipy-jupyter:pytorch1.0.1-cuda10.0-py3.6-ubuntu18.04
        build:
          context: .
        runtime: nvidia
        restart: always
        environment:
          - NV_GPU=0
    #      - JUPYTER_ENABLE_LAB=1
        volumes:
          - ./workspace:/home/jovyan/work
          - ./dotjupyter:/home/jovyan/.jupyter
        ports:
          - 8888:8888

The following command starts the stack with the terminal attached.
Take a look at the token and login to Jupyter using this token.
You can also enter a password using this token. If you do this, and have `.jupyter`
configured as persisted volume, you can use this password the next time you
start the stack.

    docker-compose up

# Test

Start a new notebook and run

    import torch
    torch.cuda.is_available()
    
this should return

    True

# Background

Pytorch is tied to specific versions of the Cuda software. To have a Pytorch installation
with GPU support, it was required to use a specific Nvidia ubuntu image as starting point,
and add Pytorch and the complete base-notebook, minimal-notebook and scipy-notebook on top
of that image.
The alternative route, adding Cuda and Pytorch to the docker-stacks scipy image failed due to
unsurmountable dependency conflicts.

# References

 * [Nvidia Docker Image documentation](https://github.com/NVIDIA/nvidia-docker/wiki)
 * [Nvidia Cuda Image Tags](https://hub.docker.com/r/nvidia/cuda/tags)
 * [Jupyter Scipy Docker documentation](https://github.com/jupyter/docker-stacks/tree/master/scipy-notebook)
 * [Miniconda installation](https://docs.conda.io/en/latest/miniconda.html)
 * [PyTorch local installation](https://pytorch.org/get-started/locally/)
