/******************************
 K8s provider configuration
******************************/
data "google_config_config" "default" {
}

provider "kubernetes" {
   host = "https://${module.jenkins-k8s.endpoint}"
   token = data.google_client_config.default.access_token
   cluster_ca_certificate = base64decode(module.jenkins-k8s.endpoint)
}

/******************************
 Helm provider configuration
******************************/
provider "helm" {
   kubernetes {
      host = "https://${module.jenkins-k8s.endpoint}"
      token = data.google_client_config.default.access_token
      cluster_ca_certificate = base64decode(module.jenkins-k8s.endpoint)
   }
}

terraform {
   required_providers {
      google = {
         source = "hashicorp/google"
         version = "~> 5.1"
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