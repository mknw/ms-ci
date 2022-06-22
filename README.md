# CI/CD for Massarius on K8S

Massarius Continuous Integration

## How to use

1. Change fields such as: zones, regions, project, et cetera. For now, this fields can be kept as they are for the experimental environment. 

2. Source the script in this repo at helper-scripts/local-setup, after filling in your information. For the PAT (personal access token), you can provide the scope 'repo'. Modify the script to a file called `my-local-setup`, which is already ignored by git (see .gitignore). 

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

### 2.b Define subsequent Dev and Prod environments

In order to create VPC's for Dev and Prod environments,
these need to specified (see `pipelines/environments/`). 
Both `dev` and `prod` require the same implementation, which enables us to symlink the files `{main,outputs,variables}.tf` to each env.

Each environment is then built by jenkins, as defined in `pipelines/environments/Jenkinsfile`.




### 3. Add necessary components

The Helm Chart for the job scheduler: DolphinScheduler; will be needed to install the software on k8s. After downloading the chart, one can look at how the 'jenkins` chart is installed (previous section) to perform the same operations with DS.

In order to download the chart, find the newest [src](https://dolphinscheduler.apache.org/en-us/download/download.html), download it as shown and check its integrity: 

    $ tar -zxvf apache-dolphinscheduler-3.0.0-beta-1-src.tar.gz
    $ cp apache-dolphinscheduler-3.0.0-beta-1-src/deploy/kubernetes/dolphinscheduler ROOT_PROJECT
   
where `ROOT_PROJECT` is the location of the present repository. This will make available values.yaml to the main.tf terraform file
by using the `helm_release` terraform module.

These changes are implemented in the current repository as of 16/06/2022 and can be found at: terraform/main.tf.

### 4. Configure DolphinScheduler

In addition to default values, we would like to add features such as: 

- External access the DolphinScheduler UI. 
  - enable ingress, *or* `kubectl port-forward`'ing ([source](https://dolphinscheduler.apache.org/en-us/docs/latest/user_doc/guide/installation/kubernetes.html))
- communication between: DolphSched DB (PostgreSQL) and data ingestion node pools.
- connection between: bigquery and DolphinScheduler Cluster

The overview of the existing DevOps flow given in [2. Define initial infrastructure](###2-define-initial-infrastructure) allows us to define the remaining architecture in a similar fashion.

Later in this document, our objective will be to create *modules* for: 
- node pool (FastAPI data ingestion endpoint).
- others?

and *resources* for: 
- Service Account Permissions involving: 
  - API endpoint to DB.
  - DolphinScheduler node pool and BigQuery API.

### 5. Add Jenkins Environments definitions

Looking at [Diagram 2](https://github.com/Massarius/cloud/issues/175#issuecomment-1143720089), we can see that we are missing: 

1. Terraform files that define dev and prod environments. 
2. Jenkins pipeline to perform operations on the environments as needed.

The directory pipelines contains one set of files: `create/{main,outputs,variables}.tf`, which will be applied to both dev and prod envs. Note that, if symlinks in 1. are broken, you can run the following script in both dev and prod envs to restore them: 

    $ for file in main.tf outputs.tf variables.tf; do ln -s "../../create/${file}" ${file}; done

Pipelines themselves are defined within the [Jenkinsfile](https://www.jenkins.io/doc/book/pipeline/syntax/). In the webpage, specific info can be found to write a pipeline suitable for Kubernetes clusters.

### 6. Data Ingestion Endpoint

We wish to have a data ingestion endpoint to process data through HTTP API requests (contextual + bidstream).

This allows us to receive incoming raw data and (optionally) performing pre-processing before storing them to the PostgreSQL DB. 
The stored data will be later used by DolphinScheduler implementing the necessary Business Logic. 

### 7. BigQuery Addition

Bigquery configuration can be performed by using the bigquery terraform module. 

## TODO

1. create Jenkinsfile reflecting python app with tf plan + apply
2. do we need an artifact storage for the system image of each node pool? 
   a) can substitute containerregistry.googleapis.com to [artifactregistry.googleapis.com](https://cloud.google.com/artifact-registry/docs/reference/rest) 
   b) if necessary change `resource "google_project_iam_member" "gke"` resource in main.tf.
3. Scripts to change locations in all `values.yaml` files, for all plugins (dolphinscheduler, etc.)
   - Alternatively, ensure that `terraform.tfvars` content is passed correctly to all submodules.
4. Data Confidentiality. Security / Anonimisation / Credentials Management. 



continue with: https://plugins.jenkins.io/kubernetes/#plugin-content-declarative-pipeline (already open in firefox.)

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
-  

This style of network can be called 'flat network'.