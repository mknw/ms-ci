# CI/CD for Massarius on K8S

Massarius Continuous Integration

For an updated description of this repository, please read this documents in the following order:

1. [](pipelines/environments/README.md)
2. [](pipelines/environments/mod-dev/README.md)
3. [](terraform-jenkins-gke/README.md)

> **Disclaimer**: this instructions have been superseeded by the minimal configurations in [pipelines](pipelines/environments/mod-dev).  
The current information is left here as a tangential reference of what previously attempted solutions explored, as well as a potential testbed for future DevOps experiments. When reading what follows, please be aware of the limitations of the settings in which it was written.

## How to use

### Create Jenkins K8S cluster

1. Change fields such as: zones, regions, project, et cetera. For now, this fields can be kept as they are for the experimental environment. 

2. if you haven't done it already, run `gcloud services enable compute.googleapis.com

3. Source the script in this repo at helper-scripts/local-setup, after filling in your information. For the PAT (personal access token), you can provide the scope 'repo'. Please modify the script to a file called `my-local-setup`, which is already ignored by git (see .gitignore). 

4. terraform init

5. `terraform plan --var "github_username=$GITHUB_USER" --var "github_token=$GITHUB_TOKEN"`

6. `terraform apply --auto-approve --var "github_username=$GITHUB_USER" --var "github_token=$GITHUB_TOKEN"`

7. `cd ..` (or `cd $PROJECT_ROOT`)

8. `gcloud container clusters get-credentials jenkins --zone=europe-west4 --project=${PROJECT_ID}` will retrieve the cluster credentials for jenkins internal use. Run it, the output should be: `Fetching cluster endpoint and auth data. kubeconfig entry generated for jenkins`.
You will need to run this command every time you want to be able to execute kubectl commands locally.

9. Once Jenkins is provided with cluster credentials, you can output jenkins URL and credentials as follows: 

```
# JENKINS_IP=$(kubectl get service jenkins -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
# line above kept for reference.
JENKINS_PASSWORD=$(kubectl get secret jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode);echo
printf "Jenkins user: admin\nJenkins password: $JENKINS_PASSWORD\n"
```


Now let's port-forward the `jenkins` service so we can access it. 
Run `kubectl port-forward pods/jenkins-0 8080:8080` to connect to the jenkins pod. 
(You can leave LOCAL_PORT unspecified to let kubectl choose your port) This command will print the local address at which you can access the remote Jenkins instance.
This command does not return, therefore you can run it in a different shell than the one containing your environment variables.

(to get jenkins token one can run `curl -v -X GET http://LOCAL_HOST:LOCAL_PORT/crumbIssuer/api/json --user username:password`. This info is useless here but we keep it for reference).

`export POD_NAME=$(kubectl get pods --namespace default -l "app.kubernetes.io/component=jenkins-master" -l "app.kubernetes.io/instance=jenkins" -o jsonpath="{.items[0].metadata.name}")`


## Configuration

Initial steps taken to setup the repository and documented below.

### 1. Create the following files: 
main.tf
: The main Configuration object, where each resource is defined.
  
providers.tf
: Developer repo for each of the external module used. Here: Helm, K8s and Google. More [can be found](https://registry.terraform.io/browse/providers).

variables.tf
: Variables used in `main.tf`. 

backend.tf
: Our way to store the terraform state: [gcs](https://www.terraform.io/language/settings/backends/configuration) (Google Cloud Storage). Since versioning can be enabled on this backend type, risks of disruption due to configuration errors are mitigated. One can find the `tfstate` file in the 'buckets' section of GCP.

### 2. Define initial Jenkins infrastructure
The following list is brief summary of the content found in `main.tf`, divided by main block type: module and resource.

  Load the modules for: 
   - enabling required google apis (IAM, compute, container (GKE), logging, monitoring)
   - Jenkins-vpc (the *network* infr.: `terraform-google-modules/network`[/readme.md](https://registry.terraform.io/modules/terraform-google-modules/network/google/latest))
   - jenkins node pools (*'server'* infr.: `terraform-google-modules/kubernetes-engine/beta-public-cluster`[/readme.md](https://registry.terraform.io/modules/terraform-google-modules/kubernetes-engine/google/latest/submodules/beta-public-cluster))
   - Workload Identity (GCP access from k8s: `terraform-gogle-modules/kuberetes-engine/workload-identity`[/readme.md](https://registry.terraform.io/modules/terraform-google-modules/kubernetes-engine/google/latest/submodules/workload-identity))

   Create the resources: 
   - kubernetes_secrets, containing: 
     - `gh-secrets` (github credentials)
     - `jenkins-secrets` (credentials to access the jenkins-gke node pool in order to configure K8S executers)
   - Service Account Permissions, each defined as a `google_<resource>_aim_member` resource. They are:
     - gke (`<resource> = project` enables K8s to view and pull artifacts from GCS. IAM role: `roles/objectViewer`)
     - cluster-dev (`<resource> = project` enables GSA to add and delete pods for jenkins builder. IAM role: `roles/container.developer`)
     - tf-state-writer (`<resource> = storage_bucket` allows Jenkins to write TF state for pipelines into GCS backend. IAM role: `roles/storage.admin`)
     - jenkins-project (`<resource> = project` grant Jenkins project editor permissions. IAM role: `roles/editor`)
   - Helm Chart: `jenkinsci/jenkins` (Kubernetes plugin for Jenkins Clusters)
     
[Exemplary Code](https://github.com/GoogleCloudPlatform/solutions-terraform-jenkins-gitops/blob/dev/jenkins-gke/tf-gke/main.tf)

In `terraform-jenkins-gke/values.yaml`, Jenkins is configured to create two create two k8s pools (see 'templates'), on demand. These are labeled `jnlp-exec`, and `terraform-exec`. 
Furthermore, Github credentials and init-jobs are given as needed from terraform outputs (see `outputs.tf`).  
`init-jobs` also specify where the pipeline can be found, within the environment folder. 
To know more about JasC (Jenkins as Code), read [the docs](https://github.com/jenkinsci/configuration-as-code-plugin/blob/master/README.md).

To find explanation for the settings in the `JasC.config-scripts.init-jobs` section, one can inspect the [JasC preview tool](https://jenkinsci.github.io/job-dsl-plugin/#path/multibranchPipelineJob).

### 2.b Define pipeline

In order to create test infrastructure suitability for Dev and Prod environments,
these need to specified (see `pipelines/environments/`). 
Both `dev` and `prod` require the same implementation, which enables us to symlink the files `{main,outputs,variables}.tf` to each env.

Each environment is then built by jenkins, as defined in `pipelines/environments/Jenkinsfile`.

The conditional behaviour of the file is defined through shell scripting, and explained in the comments at the top.
This pipeline consists of three stages, which are started `when` a `changeRequest` is made to `prod` and `dev`. To understand more about the syntax, please consult [the pipeline syntax docs](https://www.jenkins.io/doc/book/pipeline/syntax/).

In practice, changes to the infrastructure are only implemented on GCP when a PR is merged to the `prod` branch.
Each container summoned by jenkins to validate, test and deploy the infrastructure is defined in the `terraform-jenkins-gke/values.yaml` file, described above.

### 2.c Define actual Environments (Dev and Prod)

The definition of the environments can be changed within `pipelines/create/*`.

Briefly, main.tf contains: 

- VPC to run our cluster. 
- A composer environment providing Airflow functionalities to the cluster. 
- A compute instance (VM) enabling a minimal version of an HTTP endpoint (Data Ingestion endpoint for contextual and bidstream)
- networking functionalities enabling connection to HTTP endpoint for direct connection on part of the developer.

This represents a minimal configuration of the production cluster, and its meant as initial configuration, on top of which further functionalities and improvements will be implemented.

The remaning part of this document is outdated, but the information contained still true for the present configuration. It can be read to understand the current configuration, but it should not be intended as a step by step guide. 

### 2.d Placeholder par.

The writing of this document was interrupted as we experienced issues in implementing the dev and prod environment. 

Currently, most of the work being done can be found in the `pipelines/environments` directory. Information on the relevant development can be found in the README.txt in that directory.




### (old) 5. Add Jenkins Environments definitions

Looking at [Diagram 2](https://github.com/Massarius/cloud/issues/175#issuecomment-1143720089), we can see that we are missing: 

1. Terraform files that define dev and prod environments. 
2. Jenkins pipeline to perform operations on the environments as needed.

The directory pipelines contains one set of files: `create/{main,outputs,variables}.tf`, which will be applied to both dev and prod envs. Note that, if symlinks in 1. are broken, you can run the following script in both dev and prod envs to restore them: 

    $ for file in main.tf outputs.tf variables.tf; do ln -s "../../create/${file}" ${file}; done

Pipelines themselves are defined within the [Jenkinsfile](https://www.jenkins.io/doc/book/pipeline/syntax/). In the webpage, specific info can be found to write a pipeline suitable for Kubernetes clusters.

### 6. Data Ingestion Endpoint

We wish to have a data ingestion endpoint to process data through HTTP API requests (contextual + bidstream).

This allows us to receive incoming raw data and (optionally) performing pre-processing before storing them to the PostgreSQL DB. 
The stored data will be later used by Apache Airflow implementing the necessary Business Logic. 


## Notes

### VPC requirements

When creating a cluster, the VPC needs:

- sufficient N of IP addresses for cluster, nodes and any other resource. (every pod get is own IP address)

### IP addresses

- Containers within a pod share the pod IP address and can communicate freely with each other.
- Pods can communicate with all other pods in the cluster using pod IP adresses
- Isolation is defined using network policies.

### K8s services

- Services abstract to a group of pods as a network service.
- Group of pods is usually defined using a *label selector*

This style of network can be called 'flat network'.