# Jenkins Automation

This document describes the main steps taken to create the current codebase. It aims at reporting the objective, necessary components, encountered challenges as well as giving an outline of the possible future steps.

## Objective

The main goal of this repository is to create a CI/CD pipeline for the development and delivery of code for Massarius data team. If you don't understand why, see [](https://www.redhat.com/en/topics/devops/what-cicd-pipeline), [](https://semaphoreci.com/blog/cicd-pipeline), [](https://www.plutora.com/blog/understanding-ci-cd-pipeline).

This repository represents a CI/CD pipeline stripped down to the essential. A Jenkins k8s Cluster connected to the business' Github account is used to automate Builds and Tests, providing feedback on buils and allowing swift configuration via CasC best practices.

## Components

The minimal requirements for the outlined task are:

- A Jenkins cluster (e.g. k8s) to run builds, tests and validations. The container enables workers to spin up environments on request while the web server is available to the developer for reporting, monitoring and configuration purposes.
- A Prod cluster where the application runs. In this case, GCP composer is hosted in the prod container, as well as other services. Please see [](../pipelines/environments/mod-dev/README.md) for more info.
- A Dev cluster which mirrors the specifications of Prod. To our aims and purposes, here we'll assume that they are identical. Please see [](../pipelines/environments/README.md) for more info on how to obtain seamless shared configuration while allowing for differential specifications where necessary (e.g. non-overlapping CIDR ranges for different environments in the same network).
- Github integration (e.g. through Github Actions, Personal Access Token, or both). Previous documentation on this can be found in [](../README.md).
- Suite for Unit Testing (currently present in `dev-era-184513`)

## Encountered challenges 

The main challenge in the development of this pipeline consisted in Terraform idyosincracies. 
This means that, while learning, not all implementation requirements were clear. These had to be sorted out by trial and error, resulting in the repository you see now. 

At the moment, there is an environment having -briefly- a GCP composer and VM to be used for webscraping. 

## Possible plans

As this directory consists in the highest level of development this repository is meant for, I will assume the reader to have read:

1. [general envs docs](pipelines/environments/README.md), and
2. [working env docs](pipelines/environments/mod-dev/README.md)


<!-- continue from here -->
