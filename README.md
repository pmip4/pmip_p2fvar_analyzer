# Simple Jupyter Docker 

This repository contains a simple way to create a Jupyter-based Python installation using Docker. It basically installs a few packages (see file `environment.yml`, and modify at will). 

The docker file is created every time you pull to the repository, and takes forever to build (~15 minutes). Once this works, you can create a Github release, and it will build the image and push it into Docker Hub.
