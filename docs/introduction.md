# Introduction

The aim of this repository is to provide a capability to build Docker images with a selected set of Python packages installed, and accessible via Jupyter notebooks. This provides a clean and reproducible way to distribute software to students to run on their computers.

This documentation details how you can tailor this repository to the needs of your particular course. The basic changes you may want to carry out are things like select the packages that will be installed, build the Docker image and test that it builds, and push it to e.g. DockerHub so that it can be easily accessed by people.

This repository uses a number of already existing things developed by other people:

1. The [Jupyter stacks](https://github.com/jupyter/docker-stacks) project provides a set of Docker images for the Jupyter ecosystem. We start with one of their base images and build up from there.
2. [Github Actions](https://github.com/features/actions) allow us to automatically build images and potentially test them directly from Github.

## Python-centric

The discussion here is very Python centric, mostly because this is the language we use for a lot of teaching, but also because that's what I'm familiar with. It should be stratigtforward to extend this to R or Julia, as both ecosystems are supported by [Jupyter stacks](https://github.com/jupyter/docker-stacks). However, I will not cover this here.

## Cloud deployment

A docker container can also be deployed on cloud architectures. While this is a possibility, and allows users to quickly gain access to computational facilities, I will not cover this in this document.

## Organisation

We envisage that you'll want to

1. Select a number of Python packages.
2. Add some teaching materials (e.g. notebooks).
3. Possibly some extra Python codes.
4. Create a docker image.
5. Push it to some container repository and publish it.

The rest of the document deals with these tasks.
