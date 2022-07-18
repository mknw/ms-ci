/**
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/*****************************************
  Locals
 *****************************************/
locals {
  vpc_network_name = "vpc-${var.environment}"
  nat_subnet_name = "vpc-${var.environment}-${var.subnet2_region}-nat" 
  vm_name = "vm-${var.environment}-api-endpoint"
}

/*****************************************
  Google Provider Configuration
 *****************************************/
provider "google" {
  version = "~> 4.25" # was "~> 2.18.0". Revert in case of compatibility issues.
}

/*****************************************
  IAM member permissions
 *****************************************/
resource "google_project_iam_member" "composer_agent_service_account" {
  count   = var.grant_sa_agent_permission ? 1 : 0
  project = data.google_project.project.project_id
  role    = "roles/composer.ServiceAgentV2Ext"
  member  = format("serviceAccount:%s", local.cloud_composer_sa)
}

/*****************************************
  Create a VPC Network 
 *****************************************/
module "data-vpc" {
  source       = "terraform-google-modules/network/google"
  version      = "~> 5.1"
  project_id   = var.project_id
  network_name = local.vpc_network_name
  mtu          = 1460

  subnets = [
    {
      subnet_name   = "${local.vpc_network_name}-${var.subnet1_region}"
      subnet_ip     = var.subnet1_cidr
      subnet_region = var.subnet1_region
    },
    {
      subnet_name = local.nat_subnet_name
      subnet_ip = var.subnet2_cidr 
      subnet_region = var.subnet2_region
    }
  ]
}


/*****************************************
  Create Composer Instance
 *****************************************/

module simple-composer-environment {
  source = "terraform-google-modules/composer/google//modules/create_environment_v2"
  project_id                       = var.project_id
  composer_env_name                = var.composer_env_name
  region                           = var.subnet1_region
  composer_service_account         = var.composer_service_account
  network                          = local.vpc_network_name
  # subnetwork                      = var.subnetwork
  subnetwork                       = module.data-vpc.subnets_self_links[0]
  pod_ip_allocation_range_name     = var.pod_ip_allocation_range_name
  service_ip_allocation_range_name = var.service_ip_allocation_range_name
  grant_sa_agent_permission        = true
  environment_size                 = "ENVIRONMENT_SIZE_MEDIUM"
  environment_variables            = {} // just the default, for future config.

  scheduler = {
    cpu        = 0.875
    memory_gb  = 1.875
    storage_gb = 1
    count      = 1
  }
  web_server = {
    cpu        = 0.875
    memory_gb  = 2
    storage_gb = 1
  }
  worker = {
    cpu        = 1
    memory_gb  = 2.5
    storage_gb = 2
    min_count  = 1
    max_count  = 3
  }
}


/*****************************************
  Create a GCE VM Instance
 *****************************************/
resource "google_compute_instance" "api" {
  project      = var.project_id
  zone         = var.subnet1_zone
  name         = local.vm_name
  machine_type = "e2-medium"
  network_interface {
    network    = module.data-vpc.network_self_link
    subnetwork = module.data-vpc.subnets_self_links[0]
  }
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }
}

/**************
Service Account for NAT connection
**************/
resource "google_project_iam_member" "project" {
  project = var.project_id
  role    = "roles/iap.tunnelResourceAccessor"
  member  = "serviceAccount:nat-tunnel-access@${var.project_id}.iam.gserviceaccount.com"
}

/********************
 Make firewall rule
********************/
resource "google_compute_firewall" "rules" {
  project = var.project_id
  name    = "allow-ssh"
  network = module.data-vpc.network_self_link # Replace with a reference or self link to your network, in quotes

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["35.235.240.0/20"]
}


/**************
Setup NAT router
**************/
resource "google_compute_router" "router" {
  project = var.project_id
  name    = "nat-router"
  network = module.data-vpc.network_self_link
  region  = var.subnet1_region
}

/*************
Cloud NAT
**************/
module "cloud-nat" {
  source                             = "terraform-google-modules/cloud-nat/google"
  version                            = "~> 2.0.0"
  project_id                         = var.project_id
  region                             = var.subnet1_region
  router                             = google_compute_router.router.name
  name                               = "nat-access"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}