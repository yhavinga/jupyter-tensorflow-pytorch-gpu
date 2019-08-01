# nvidia-pytorch-scipy-jupyter

Ubuntu image with Cuda, Pytorch with GPU support, docker-stacks-style
jupyter and and conda installation.

Components:

* Nvidia-ubuntu -> Ubuntu image with Cuda device drivers
* Docker-stacks -> Base, minimal and scipy notebooks
* Pytorch -> python 3.6 pytorch package with GPU support
* Python PostgreSQL client
* and some useful lab and nb extensions such as ExecuteTime.

# Usage

IMPORTANT!! The image must be started with the nvidia-docker runtime. With
docker-compose this can be specified with the `runtime` directive, that is
available in docker-compose versions >=2.3 and <3.

    docker-compose up

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
