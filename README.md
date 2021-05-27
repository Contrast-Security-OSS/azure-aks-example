# Microsoft AKS - Contrast Security Example

The code in this github repository gives a step-by-step instruction on how to integrate a Contrast Security agent with an application being deployed to a Microsoft AKS cluster.

![Contrast AKS Integration Example](/images/aks-blog-pic1-2.png)

This github repository contains the following sections:
* Sample Application - Netflicks .Net Core
* Docker Build/Docker-Compose Deployment
* Pushing the Container Image to Microsoft ACR
* Kubernetes Deployment
* Simple Exploit (SQL Injection)
* Contrast Security Vulnerability Results
* End-to-End Tests

## Sample Application - Netflicks .Net Core

Based on https://github.com/LeviHassel/.net-flicks with vulnerabilities added.

![Netflicks Example Application](/images/netflicks-landing.png)

## Docker Build/Docker-Compose Deployment

You can run netflicks within a Docker container, tested on OSX. It uses a separate sql server as specified within docker-compose.yml (you should not need to edit this file). The agent is added automatically during the Docker build process.

1.) Build the container using:

`docker build -f Dockerfile . -t netflicks:1`

2.) Run the containers locally via Docker-Compose using: 

`docker-compose up`

*Note - For vanilla Docker implementations including docker-compose, the agent configurations are passed via environment variables within the Dockerfile.  Make sure to use 'Dockerfile' for vanilla Docker implementations for the docker build.  If you are deploying to Microsoft AKS, please use 'Dockerfile-new' for the docker build as the Contrast Agent configurations are removed from the Dockerfile.  For Microsoft AKS implementations, Contrast Agent configurations are passed using kubernetes secrets/configMaps.* 

## Pushing the Container Image to Microsoft ACR

Following your build, in order to run the application via Microsoft AKS, you first need to have an image avialable inside a Container Registry.  This demo uses Microsoft's ACR to store the built container images. 

1.) Make sure to tag the image prior to pushing to the registry using this command:

`docker tag SOURCE_IMAGE[:TAG] TARGET_IMAGE[:TAG]`

2.) Log into Microsoft's ACR using the following command - more information found [here](https://docs.microsoft.com/en-us/azure/container-registry/container-registry-get-started-docker-cli?tabs=azure-cli):

`docker login <myregistry>.azurecr.io`

3.) Push a local container image to Microsoft's ACR using the 'docker' command:

`docker push NAME[:TAG]`

## Kubernetes Deployment

You can run netflicks within a Kubernetes cluster, tested on local OSX via Kubernetes cluster running on Docker Desktop and Microsoft AKS. 

### Create a kubernetes secret to store Contrast Agent configurations

1.) Update the 'contrast_security.yaml' with your configuration details.

2.) Create a kubernetes secret that houses the Contrast Security agent configuration from the 'contrast_security' file:

`kubectl create secret generic contrast-security --from-file=./contrast_security.yaml`

_*You need to be in the same directory that contains the 'contrast_security.yaml' file, unless you explicitly pass the file location to kubectl as above.*_

### Deploy Netflicks to an AKS cluster

1.) Make sure your AKS cluster can pull images from your ACR - more information found [here](https://docs.microsoft.com/en-us/azure/aks/cluster-container-registry-integration)

2.) Find the manifests in 'kubernetes/manifests'

3.) Run the following code to deploy using kubectl:

`kubectl apply -f web-deployment.yaml,web-service.yaml,database-deployment.yaml,database-service.yaml,volume-claim.yaml`

_*You need to be in the same directory that contains the manifests, unless you explicitly pass the file location to kubectl.*_

## Simple exploit (SQL Injection)

To expose a sample SQL Injection vulnerability, login (inspect the loadbalancer service you have deployed to get the IP - the port, unless changed, should be 90) and go to the movies list, search for: 

`'); UPDATE Movies SET Name = 'Pwned' --`

Once the search functionality is exploited, the following results should come back from the database.

![Netflicks Database Injection](/images/neflicks-Pwned.png)

*Note - The database will reset each time you redeploy the application because the database is being hosted inside a container.*

## Contrast Security Vulnerability Results

Results from the Contrast Agent should resemble the following: 

![Netflicks Vulnerabilities](/images/netlicks-vulnerabilities.png)

More information on Contrast Security can be found [here](www.contrastsecurity.com)

## End-to-End tests

There is a test script which you can use to reveal all the vulnerabilities which requires node and puppeteer.

1.) From the app folder run `npm i puppeteer`.

2.) Run `BASEURL=https://<EXPOSED_IP>:90 node exercise.js` or `BASEURL=https://<EXPOSED_IP>:90 DEBUG=true node exercise.js` to see it in progress.
