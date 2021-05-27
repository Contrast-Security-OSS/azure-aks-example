# Microsoft AKS - Contrast Security Example 

## Netflicks .Net Core Demo App

Based on https://github.com/LeviHassel/.net-flicks with vulnerabilities added.

## Docker Build/Docker-Compose Deployment

You can run netflicks within a Docker container, tested on OSX. It uses a separate sql server as specified within docker-compose.yml (you should not need to edit this file). The agent is added automatically during the Docker build process.

1.) Build the container using `./image.sh`

2.) Run the containers locally via Docker-Compose using `docker-compose up`

## Pushing the Container Image to Microsoft ACR

Following your build, in order to run the application via Microsoft AKS, you first need to have an image avialable inside a Container Registry.  This demo uses Microsoft's ACR to store the built container images. 

1.) Push a local container image to Microsoft's ACR using the 'docker' command:

## Kubernetes Deployment

You can run netflicks within a Kubernetes cluster, tested on local OSX via Kubernetes cluster running on Docker Desktop and Microsoft AKS. 

1.) Find the manifests in 'kubernetes/manifests'

2.) Run the following code to deploy using kubectl:

## Simple exploit (SQL Injection)

Login and go to the movies list, search for `'); UPDATE Movies SET Name = 'Pwned' --`

The database will reset each time you run the demo.

## End to End tests

There is a test script which you can use to reveal all the vulnerabilities which requires node and puppeteer.

1.) From the app folder run `npm i puppeteer`.

2.) Run `BASEURL=https://<EXPOSED_IP>:90 node exercise.js` or `BASEURL=https://<EXPOSED_IP>:90 DEBUG=true node exercise.js` to see it in progress.
