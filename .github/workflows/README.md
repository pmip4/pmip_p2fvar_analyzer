### The github actions to create the Docker image are not working. This arises from the fact that the repository is a fork from an original repository under the account of @chrisbrierley. For security reasons, this means that it is not allowed to use the required secrets to access DockerHub. I've no idea how to fix this, and it took ages to discover that this was the reason for it not working automatically. Instead we are now creating the Docker images manually using the following command:

 docker build -t chrisbrierley/pmip-p2fvar-analyzer:latest .
