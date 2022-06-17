# CI/CD for Massarius on K8S

Massarius Continuous Integration

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

### 2. Define initial infrastructure. 
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
     - gke (`<resource> = project` enables K8s to view and pull artifacts from GCS. AIM role: `roles/objectViewer`)
     - cluster-dev (`<resource> = project` enables GSA to add and delete pods for jenkins builder. AIM role: `roles/container.developer`)
     - tf-state-writer (`<resource> = storage_bucket` allows Jenkins to write TF state for pipelines into GCS backend. AIM role: `roles/storage.admin`)
     - jenkins-project (`<resource> = project` grant Jenkins project editor permissions. AIM role: `roles/editor`)
   - Helm Chart: `jenkinsci/jenkins` (Kubernetes plugin for Jenkins Clusters)
     
[Exemplary Code](https://github.com/GoogleCloudPlatform/solutions-terraform-jenkins-gitops/blob/dev/jenkins-gke/tf-gke/main.tf)

### 3. Add necessary components

The Helm Chart for the job scheduler: DolphinScheduler; will be needed to install the software on k8s. After downloading the chart, one can look at how the 'jenkins` chart is installed (previous section) to perform the same operations with DS.

In order to download the chart, find the newest [src](https://dolphinscheduler.apache.org/en-us/download/download.html), download it as shown and check its integrity: 

    $ tar -zxvf apache-dolphinscheduler-3.0.0-beta-1-src.tar.gz
    $ cp apache-dolphinscheduler-3.0.0-beta-1-src/deploy/kubernetes/dolphinscheduler ROOT_PROJECT
   
where `ROOT_PROJECT` is the location of the present repository. This will make available values.yaml to the main.tf terraform file
by using the `helm_release` terraform module.

These changes are implemented in the current repository as of 16/06/2022 and can be found at: terraform/main.tf.

### 4. Configure DolphinScheduler. 

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

We wish to



## TODO

1. create Jenkinsfile reflecting python app with tf plan + apply
2. do we need an artifact storage for the system image of each node pool? 
   a) can substitute containerregistry.googleapis.com to [artifactregistry.googleapis.com](https://cloud.google.com/artifact-registry/docs/reference/rest) 
   b) if necessary change `resource "google_project_iam_member" "gke"` resource in main.tf.


continue with: https://plugins.jenkins.io/kubernetes/#plugin-content-declarative-pipeline (already open in firefox.)

