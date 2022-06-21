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
  vm_name = "vm-${var.environment}-http-endpoint"
}

/*****************************************
  Google Provider Configuration
 *****************************************/
provider "google" {
  version = "~> 4.25" # was "~> 2.18.0". Revert in case of compatibility issues.
}

/*****************************************
  Create a VPC Network 
 *****************************************/
module "composer-vpc" {
  source       = "terraform-google-modules/network/google"
  version      = "~> 5.1"
  project_id   = var.project_id
  network_name = local.vpc_network_name

  subnets = [
    {
      subnet_name   = "${local.vpc_network_name}-${var.subnet1_region}"
      subnet_ip     = var.subnet1_cidr
      subnet_region = var.subnet1_region
    },
  ]
}


/*****************************************
  Create Composer Instance
 *****************************************/

module simple-composer-environment {
  source = "terraform-google-modules/composer/google//modules/create_environment_v2"
  project_id                       = var.project_id
  composer_env_name                = var.composer_env_name
  region                           = var.region
  composer_service_account         = var.composer_service_account
  network                          = var.network
  # subnetwork                      = var.subnetwork
  subnetwork                       = module.composer-vpc.subnets_self_links[0]
  pod_ip_allocation_range_name     = var.pod_ip_allocation_range_name
  service_ip_allocation_range_name = var.service_ip_allocation_range_name
  grant_sa_agent_permission        = false
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
resource "compute_instance" "http_endpoint" {
  project      = var.project_id
  zone         = var.subnet1_zone
  name         = local.vm_name
  machine_type = "e2-medium"
  network_interface {
    network    = module.composer-vpc.network_name
    subnetwork = module.composer-vpc.subnets_self_links[0]
  }
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }
}
