/**
 * Copyright 2022 Google LLC
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

module "exp-composer-environment" {
  source                           = "terraform-google-modules/composer/google//modules/create_environment_v2"
  project_id                       = var.project_id
  composer_env_name                = var.composer_env_name
  region                           = var.region
  # composer_service_account         = var.composer_service_account
  network                          = "default"
  subnetwork                       = var.subnetwork
  subnetwork_region                = var.region
  # pod_ip_allocation_range_name     = var.pod_ip_allocation_range_name
  # service_ip_allocation_range_name = var.service_ip_allocation_range_name
  # grant_sa_agent_permission        = true # by default
  environment_size                 = "ENVIRONMENT_SIZE_SMALL"
  scheduler = {
    cpu        = 0.5
    memory_gb  = 1.875
    storage_gb = 1
    count      = 1
  }
  web_server = {
    cpu        = 0.5
    memory_gb  = 1.875
    storage_gb = 1
  }
  worker = {
    cpu        = 0.5
    memory_gb  = 1.875
    storage_gb = 1
    min_count  = 1
    max_count  = 3
  }
}


/* Create a VM for HTTP API requests (bidstream, contextual API's)
* This 
*/

# resource "google_compute_subnetwork" "network-with-private-secondary-ip-ranges" {
#   name          = "test-vm-subnetwork"
#   ip_cidr_range = "10.2.0.0/16"
#   region        = var.region
#   network       = "default"
#   secondary_ip_range {
#     range_name    = "tf-test-secondary-range-update1"
#     ip_cidr_range = "192.168.10.0/16"
#   }
# }


module "service_accounts" {
  source        = "terraform-google-modules/service-accounts/google"
  # version       = "~> 3.0"
  project_id    = var.project_id
  names         = ["vm-terraform"]
  project_roles = ["${var.project_id}=>roles/compute.instanceAdmin"]
  display_name  = "VM Terraform"
  description   = "Service Account used by terraform-cloud to create instance templates and spin up new VM's."
}


module "instance_template" {
  source          = "terraform-google-modules/vm/google//modules/instance_template"
  region          = var.region
  # zone            = var.zone
  project_id      = var.project_id
  # network         = "default"
  subnetwork      = "projects/${var.project_id}/regions/${var.region}/subnetworks/default"
  subnetwork_project = var.project_id
  service_account = {
      email       = module.service_accounts.email
      scopes      = []
  }
  additional_networks = []
}

module "compute_instance" {
  source              = "terraform-google-modules/vm/google//modules/compute_instance"
  region              = var.region
  subnetwork      = "projects/${var.project_id}/regions/${var.region}/subnetworks/default"
  num_instances       = "1" # default.
  hostname            = "scraping-machine"
  instance_template   = module.instance_template.self_link

  access_config = [
    # to be added after first apply.
  ]
}