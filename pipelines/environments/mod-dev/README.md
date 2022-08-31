# DEV-MOD

## Requirements

- [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)
- [gcloud-cli](https://cloud.google.com/sdk/docs/install)
- Linux.

## How to use

1. `cd` to [helper-scripts](../../../helper-scripts/local-setup). 
1. `cp local-setup my-local-setup`
1. Change my local setup as specified in the file.
1. `source my-local-setup`
1. Use `terraform` commands as necessary. These are: 
   1. `show`
   2. `output`
   3. `plan`
   4. `apply`

Please note that in the local-setup script, no Github PAT is required when running the code in `mod-dev`. It will be when using Jenkins integration. If you don't know what this is in the context of this repo, you can forego the detail and wait until you reach the docs in [tf-jenkins-k8s](../../../terraform-jenkins-gke).

## Description

This environment deploys:

1. a GCP Composer Instance
2. service account of the management of Virtual Machines
3. an instance template for VM configurations (to be customized)
4. a VM dedicated to be setup for scraping (contextual comes to mind.)

This configuration can be easily extended repeating some blocks already present in the `main.tf` file.

Here are some ideas for future additions which could be useful to the team. The following list aims at providing, for each component: 1) business applications; 2) difficulty of implementation; and 3) links to documentation.

- Adding specific requirements to VM template image (e.g. Selenium driver, and other dependencies (pip, etc.))
- Additional VM as HTTP endpoint
   1. Bidstream
   2. Easy
   3. see [legacy dev](../legacy-dev/main.tf) for a nearly complete implementation. IGRESS Firewall rules should also be applied as shown. For the latter, examples and docs can be found [here](https://github.com/terraform-google-modules/terraform-google-network/tree/master/modules/firewall-rules). Please keep in mind that this might consist of a security risk. To avoid this, a different subnetwork as well as other strategies can be used.
- Database [optional]
   1. Store data to be parsed from DAG's.
   2. Medium
   3. [database modules](https://github.com/terraform-google-modules/terraform-google-sql-db)
-  CI/CD integration
   1. Smoke Testing, Unit Testing and Integration Testing.
   2. Difficult
   3. The code for this application is contained in the [terraform-jenkins-gke](../../../terraform-jenkins-gke) directory. This already implements the code needed to 1. spin up our prod and dev environments in order to validate configuration, 2. sync with github to validate a change request; and 3. merge or prompt for review. \
   This code does not contain Unit testing yet. This can be easily implemented by adding the appropriate "test" (shell) command or script to the [Jenkinsfile](../Jenkinsfile). The clean way of doing this would be to add a stage for Unit Testing, to be triggered when a condition is met. More resources and suggestions on this are in the [relevant readme.md](../../../terraform-jenkins-gke/README.md).

