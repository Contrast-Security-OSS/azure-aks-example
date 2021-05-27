# Microsoft AKS - Contrast Security Example 

### Netflicks .Net Core Demo App

Based on https://github.com/LeviHassel/.net-flicks with vulnerabilities added.

### Docker/Docker-Compose

You can run netflicks within a Docker container, tested on OSX. It uses a separate sql server as specified within docker-compose.yml (you should not need to edit this file). The agent is added automatically during the Docker build process.

1.) Build the container using `./image.sh`

2.) Run the containers using `docker-compose up`

### Kubernetes

You can run netflicks within a Kubernetes cluster, tested on local OSX via Kubernetes cluster running on Docker Desktop and Microsoft AKS. 

1.) Find the manifests in 'kubernetes/manifests'

2.) Run the following code to deploy using kubectl:

## Simple exploit

Login and go to the movies list, search for `'); UPDATE Movies SET Name = 'Pwned' --`

The database will reset each time you run the demo.

## End to End tests

There is a test script which you can use to reveal all the vulnerabilities which requires node and puppeteer.

1.) From the app folder run `npm i puppeteer`.

2.) Run `BASEURL=https://<EXPOSED_IP>:90 node exercise.js` or `BASEURL=https://<EXPOSED_IP>:90 DEBUG=true node exercise.js` to see it in progress.
