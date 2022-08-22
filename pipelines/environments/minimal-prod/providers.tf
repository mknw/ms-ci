/*****************************************
  Google Provider Configuration
 *****************************************/
terraform {
  required_providers {
    # google = {
    #   source = "hashicorp/google"
    #   version = ">=4.30"
    # }
    google-beta = {
      source = "hashicorp/google-beta"
      version = ">=4.32"
    }
  }
}

# provider "google" {
#   # Configuration options
#   project = var.project_id
#   region = var.subnet1_region
#   zone = var.subnet1_zone
# }

provider "google-beta" {
  # Configuration options
  project = var.project_id
  region = var.subnet1_region
  zone = var.subnet1_zone
  request_timeout = "30m"
}