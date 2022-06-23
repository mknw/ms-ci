terraform {
  required_providers {
    provider "google" {
      version = "~> 4.25"
    }
  }
  required_version = ">= 0.14"
}
# provider "google" {
#   version = "~> 4.25"
# }

provider "google-beta" {
  version = "~> 4.25"
}