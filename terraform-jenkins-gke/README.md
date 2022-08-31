# Jenkins Automation

This document describes the main steps taken to create the current codebase. It aims at reporting the objective, necessary components, encountered challenges as well as giving an outline of the possible future steps.

### Usage

In this case, the classic terraform commands should be accompanied by variables exported by the [`my-local-setup`](../helper-scripts/my-local-setup). Follow [mod-dev readme](../pipelines/environments/mod-dev/README.md) to configure it. 

The usage is virtually the same as mod-dev, but each terraform command should be accompanied by --var arguments as follow:

```
terraform <command> --var $GITHUB_USER --var $GITHUB_TOKEN
```

where `<command>` is a valid terraform command.


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

## Current situation

As of now, one can execute [`mod-dev`](../pipelines/environments/mod-dev) and [`terraform-jenkins-gke`](.) as standalone configurations. 
This implies that each directory should be `cd`'d into to run terraform commands (`show`, `plan`, `output`, `apply`) independently, as specified in each README.md. 

This will allow one to:
1. Spin up the Jenkins K8S cluster.
2. Spin up a GCP Composer + VM environments 

In a separate fashion. Even when integrating Github with Jenkins, the automated creation of prod and dev will likely fail. This is due to the jenkins configuration not matching the naming of the directories in the [environments](../pipelines/environments/) directory. 
Before attempting to trigger the creation of either development or production environment, please see the following section.

## Next steps

As this directory consists in the highest level of development this repository is meant for, the reader should be familiar with the following documents:

- [general envs docs](pipelines/environments/README.md), and
- [working env docs](pipelines/environments/mod-dev/README.md)

The first thing to do when continuing this project, is to ensure the configuration in `mod-dev` corresponds to the desired setup for the Data Team Production Environment. In doing this, it can be useful learning from your predecessor; keeping in mind that the smallest setup is the easiest setup to debug.

After `mod-dev` corresponds to the desired setup, the *terraform-jenkins-k8s* environment should be reviewed in its configuration and implementation.

In reviewing the configuration, one must: 

- ensure that the naming of directories and environments in the [Jenkinsfile](../pipelines/environments/Jenkinsfile) is the same as in [environments](../pipelines/environments/).
- Ensure that the naming of directories is the same as the github branches in the repository.
- Ensure that the **prod** is tagged as default branch by the git subversioning system.
- Ensure correctness of the [values.yaml](./values.yaml) file. These environment variables will be provided to the helm terraform module, enabling one to configure the Jenkins cluster in kubernetes. Here are three starting points to check the Helm configuration [one](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release), [two](https://raw.githubusercontent.com/jenkinsci/helm-charts/main/charts/jenkins/values.yaml) and most importantly, [three](https://www.jenkins.io/doc/book/installing/kubernetes/).

In reviewing the implementation in values.yaml, one needs to:
- Adjust Jenkins dependencies in the values.yaml file. For now, an updated set of minimal dependencies is contained under the `installPlugins:` key.
- Review kubernetes cluster as well as container template specs within.
- Ensure correctness of pipeline jobs, (git-) multibranchPipelineJob 



### Finalizing prod setup

1. Add the necessary components (skip the optional one, more info the the [mod-dev readme](../pipelines/environments/README.md)).
2. Create shared files directory, with symlinks from env and prod

## Last notes

Getting GCP Composer, Compute Engine, Cloud Storage, Kubernetes, Terraform and Jenkins to work seamlessly is not a trivial task. 

As you proceed with the implemenation, work methodically, plan your steps in advance and record your progress corresponding to the effectuated changes. \
Do not get discouraged. When debugging a configuration becomes too hard, test components indepedently. \

Lastly here are some common topics which can be useful.

### Self links

In GCP, *Self links* are strings that specify the project, region, zone, type and instance for a resource univocally. For instance:

`projects/ornate-reef-342810/regions/europe-west3/subnetworks/default`

If the value is provided as an argument to a terraform module or resource, one can interpolate strings as necessary:

`projects/${var.project_id}/regions/${var.region}/subnetworks/default`

### Permissions

All permissions necessary to creating and managing IAM resources should be defined through the [google-terraform modules](https://cloud.google.com/docs/terraform/blueprints/terraform-blueprints).

While giving yourself (or a service account) permissions through GCP Console is an effective way of debugging permissions problems, one should not forget to implement those in this configuration.

The same goes for other resources, such as Firewall rules, Networks and subnetworks, etc.
