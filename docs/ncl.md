# Selecting packages to install 

To add flexibility in terms of adding packages that have complex binary dependencies, we have chosen to use the [`conda`](https://docs.conda.io/en/latest/) packaging system. What's good about it is that it's not Python centric, but will work with other things (even C and Fortran, for those of a certain age). There are plenty of packages available for this that are often updated, see the [conda-forge](https://conda-forge.org/) effort, a community project to provide conda packages for tons of different softwares.

## How does it work?

The main way to select packages is to do so by adding them to a so-called *conda environment*. This is defined in a file that sits in the main repository folder called `environment.yml`. It's written using the [YAML](https://yaml.org/) markup language, which basically means it's a text file. The first few lines look like this:


```yaml
name: uclgeog
channels:
  - conda-forge
  - defaults
dependencies:
  - python>=3.7
  - conda-build
  - libgdal
  - geopandas
  - rasterio
```

This is a very simple file:

* The `name` line gives the environment a name. In this case, I have chosen `uclgeog`, and you may want to stay with this.
* `channels` are the channels where packages will be looked for. We want to use `conda-forge`
* Then we have a list of packages to install, one per line. In this case, we have `Python`, `conda-build`, `libgdal`, `geopandas`.

It's worth noting that you can be very strict with versions of the packages, but unless you have a very good reason to be so, it is best to just pin the Python version (in this case, anything better than 3.6 will do), and let conda decide. If you have some particular requirements, it is probably best to define them as minimum requirements (e.g. `gdal>3.0.1` is better than `gdal=3.0.4`). This is particularly so for packages that have many dependencies, as you risk not being able to fulfill all of the requirements.

## Installing `pip` packages

For some pure Python packages, pip packages are sometimes to be found. These can be installed within the `environment.yml` file, provided you install `pip` there, and add the following subsection at the end

```yaml
name: uclgeog
channels:
  - conda-forge
  - defaults
dependencies:
  - python>=3.7
  - netCDF4
  - pip
  - pip:
    - pcse
    - git+https://github.com/jgomezdans/GomezEngine
```

Here, we are installing the `pcse` package, and a package that can be directly intalled from Github via a URL.
