/******************************
 K8s provider configuration
******************************/
data "google_client_config" "default" {
}

provider "kubernetes" {
   host = "https://${module.jenkins-gke.endpoint}"
   token = data.google_client_config.default.access_token
   cluster_ca_certificate = base64decode(module.jenkins-gke.ca_certificate)
}

/******************************
 Helm provider configuration
******************************/
provider "helm" {
   kubernetes {
      host = "https://${module.jenkins-gke.endpoint}"
      token = data.google_client_config.default.access_token
      cluster_ca_certificate = base64decode(module.jenkins-gke.ca_certificate)
   }
}

terraform {
   required_providers {
      google = {
         source = "hashicorp/google"
         version = "~> 4.25"
      }
      kubernetes = {
         source = "hashicorp/kubernetes"
         version = "~> 2.11"
      }
      helm = {
         source = "hashicorp/helm"
         version = "~> 2.5"
      }
   }
}