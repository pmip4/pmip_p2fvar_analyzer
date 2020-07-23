# How to build the docker image

The docker image gets built using GitHub actions. There are two types of build:

1. Test builds, and
2. Test & push to repository builds.

The former basically run the build and ensure, well, that it builds! whereas the second push the build up to a repository.

Test builds are run every time you push to the repository. Bear in mind that these things take a while to run (15-20 minutes), so it makes sense to ensure that things are likely to work before you push.

*Test & Push` runs occur when you make a release in the GitHub repository. This means that you mark (label) the current status of the repository, create an image and upload it for others to use. You'd do this once you've tested the images yourself and are happy with them.

