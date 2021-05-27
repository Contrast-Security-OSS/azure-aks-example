# Microsoft AKS - Contrast Security Example 

### Netflicks .Net Core Demo App

Based on https://github.com/LeviHassel/.net-flicks with vulnerabilities added.

### Azure App Service:

The terraform file will automatically add the Azure site extension so you will always get the latest version.

1.) Install the pre-reqs for terraform (if you have not already done so) as documented here: https://bitbucket.org/contrastsecurity/terraform-template/src/master/README.md

2.) Clone this repo locally using `git clone git@bitbucket.org:contrastsecurity/netficks-with-vulns-dotnet-core.git`.

3.) Drop a `contrast_security.yaml` file into your local repo (please note that the .Net Core version has a different URL).

4.) Edit the [variables.tf](variables.tf) file (or add a terraform.tfvars) to add your initials, preferred Azure location, app name, server name and environment.

5.) Run `terraform init` to download any plugins that you need.

6.) Run `terraform plan` to see if you get any errors.

7.) Run `terraform apply` to build the infrastructure that you need in Azure.

8.) If you get a 503 when visiting the app give it 30 seconds to init.

9.) Run `terraform destroy` when you are done with your demo!

### Docker

You can run netflicks within a Docker container, tested on OSX. It uses a separate sql server as specified within docker-compose.yml (you should not need to edit this file). The agent is added automatically during the Docker build process.

1.) Build the container using `./image.sh`

2.) Run the containers using `docker-compose up`


## End to End tests

There is a test script which you can use to reveal all the vulnerabilities which requires node and puppeteer.

1.) From the app folder run `npm i puppeteer`.

2.) Run `BASEURL=https://<EXPOSED_IP>:90 node exercise.js` or `BASEURL=https://<EXPOSED_IP>:90 DEBUG=true node exercise.js` to see it in progress.


## Simple exploit

Login and go to the movies list, search for `'); UPDATE Movies SET Name = 'Pwned' --`

The database will reset each time you run the demo.
