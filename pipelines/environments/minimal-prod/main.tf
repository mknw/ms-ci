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
  service_account_suffix = "${var.environment}-tf"
  composer_env_name = "${var.environment}-composer-env"
}

resource "google_project_service" "composer_api" {
  provider = google-beta
  project = var.project_id
  service = "composer.googleapis.com"
  disable_on_destroy = false
}





/*****************************************
 Service Accounts 
 *****************************************/
# module "service_accounts" {
#   source        = "terraform-google-modules/service-accounts/google"
#   version       = ">= 4.1"
#   project_id    = var.project_id
#   prefix        = local.service_account_suffix
#   names         = ["composer"] #, "nat"]
#   project_roles = ["${var.project_id}=>roles/editor"]
#   display_name  = "Prod Env Composer"
#   description   = "SA for Composer in Production Environment"
# }

/**************
Service Account for composer Airflow
**************/
# resource "google_project_iam_member" "airflow_sa" {
#   project = var.project_id
#   member  = "${module.service_accounts.iam_emails_list[0]}"
#   role    = "roles/composer.ServiceAgentV2Ext"
# }

resource "google_compute_network" "test" {
  project = var.project_id
  name = "composer-test-network3"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "test" {
  project = var.project_id
  name = "composer-test-subnetwork"
  ip_cidr_range = var.subnet1_cidr
  region = var.subnet1_region 
  network = google_compute_network.test.id
}

resource "google_project_iam_member" "service_agent_role" {
  provider = google-beta
  project  = var.project_id
  member   = "serviceAccount:service-1006414158279@cloudcomposer-accounts.iam.gserviceaccount.com"
  role     = "roles/composer.ServiceAgentV2Ext"
}

resource "google_service_account" "custom_service_account" {
  provider = google-beta
  account_id   = "${var.environment}-tf-composer2"
  display_name = "Example Custom Service Account for Terraform setup."
}

resource "google_project_iam_member" "custom_service_account" {
  provider = google-beta
  project  = var.project_id
  member   = "serviceAccount:${google_service_account.custom_service_account.email}"
  // Role for Public IP environments
  role     = "roles/composer.worker"
}

resource "google_composer_environment" "exp_airflow_env" {
  provider = google-beta
  name = "exp-airflow-env"
  region = var.subnet1_region

  config {
    software_config {
      image_version = "composer-2-airflow-2"
    }

    workloads_config {
      scheduler {
        cpu        = 0.5
        memory_gb  = 1.875
        storage_gb = 1
        count      = 1
      }
      web_server {
        cpu        = 0.5
        memory_gb  = 1.875
        storage_gb = 1
      }
      worker {
        cpu = 0.5
        memory_gb  = 1.875
        storage_gb = 1
        min_count  = 1
        max_count  = 3
      }
    }
    environment_size = var.environment_size

    node_config {
      network = google_compute_network.test.id
      subnetwork = google_compute_subnetwork.test.id
      service_account = google_service_account.custom_service_account.email
    }
  }
}

/*****************************************
  IAM member permissions
 *****************************************/
# resource "google_project_iam_member" "composer_agent_service_account" {
#   count   = var.grant_sa_agent_permission ? 1 : 0
#   project = data.google_project.project.project_id
#   role    = "roles/composer.ServiceAgentV2Ext"
#   member  = format("serviceAccount:%s", local.composer_service_account)
# }

/*****************************************
  Create a VPC Network 
 *****************************************/
# module "data-vpc" {
#   source       = "terraform-google-modules/network/google"
#   version      = ">= 5.1"
#   project_id   = var.project_id
#   network_name = local.vpc_network_name
#   mtu          = 1460

#   subnets = [
#     {
#       subnet_name   = "${local.vpc_network_name}-${var.subnet1_region}"
#       subnet_ip     = var.subnet1_cidr
#       subnet_region = var.subnet1_region
#     },
#     {
#       subnet_name = local.nat_subnet_name
#       subnet_ip = var.subnet2_cidr 
#       subnet_region = var.subnet2_region
#     }
#   ]
# }


/*****************************************
  Create Composer Instance
 *****************************************/

# resource "google_composer_environment" "composer_env" {
#   provider = google-beta
#   name = local.composer_env_name
#   project = var.project_id
#   region = var.subnet1_region
#   labels = []

#   config {
#     software_config {
#       image_version = "composer-2.0.22-airflow-2.2.5"
#     }

#     node_config {
#       service_account = google_service_account.custom_service_account.email
#     }

#   }
# }


# module simple-composer-environment {
#   source = "terraform-google-modules/composer/google//modules/create_environment_v1"
#   project_id                       = var.project_id
#   composer_env_name                = local.composer_env_name
#   region                           = var.subnet1_region
#   # composer_service_account         = "${module.service_accounts.iam_emails_list[0]}"
#   # composer_service_account         = module.service_accounts.emails_list[0]
#   # composer_service_account         = "prod-tf-composer@ornate-reef-342810.iam.gserviceaccount.com"
#   composer_service_account         = google_service_account.custom_service_account.email
#   network                          = local.vpc_network_name
#   # subnetwork                       = module.data-vpc.subnets_names[0]
#   subnetwork                       = "subnet1"
#   pod_ip_allocation_range_name     = var.pod_ip_allocation_range_name
#   service_ip_allocation_range_name = var.service_ip_allocation_range_name
#   grant_sa_agent_permission        = true
#   environment_size                 = "ENVIRONMENT_SIZE_MEDIUM"
#   # environment_variables            = {} // just the default, for future config.

#   scheduler = {
#     cpu        = 0.875
#     memory_gb  = 1.875
#     storage_gb = 1
#     count      = 1
#   }
#   web_server = {
#     cpu        = 0.875
#     memory_gb  = 2
#     storage_gb = 1
#   }
#   worker = {
#     cpu        = 1
#     memory_gb  = 2.5
#     storage_gb = 2
#     min_count  = 1
#     max_count  = 3
#   }
# }


# /*****************************************
#   Create a GCE VM Instance
#  *****************************************/
# resource "google_compute_instance" "api" {
#   project      = var.project_id
#   zone         = var.subnet1_zone
#   name         = local.vm_name
#   machine_type = "e2-medium"
#   network_interface {
#     network    = module.data-vpc.network_self_link
#     subnetwork = module.data-vpc.subnets_self_links[0]
#   }
#   boot_disk {
#     initialize_params {
#       image = "debian-cloud/debian-9"
#     }
#   }
# }


# /**************
# Service Account for NAT connection
# **************/
# resource "google_project_iam_member" "nat_access" {
#   project = var.project_id
#   role    = "roles/iap.tunnelResourceAccessor"
#   member  = "${module.service_accounts.iam_emails_list[1]}"
#   # member  = "serviceAccount:nat-tunnel-access@${var.project_id}.iam.gserviceaccount.com"
# }

# /********************
#  Make firewall rule
# ********************/
# resource "google_compute_firewall" "rules" {
#   project = var.project_id
#   name    = "allow-ssh"
#   network = module.data-vpc.network_self_link # Replace with a reference or self link to your network, in quotes

#   allow {
#     protocol = "tcp"
#     ports    = ["22"]
#   }
#   source_ranges = ["35.235.240.0/20"] # coming from..?
# }


# /**************
# Setup NAT router
# **************/
# resource "google_compute_router" "router" {
#   project = var.project_id
#   name    = "nat-router"
#   network = module.data-vpc.network_self_link
#   region  = var.subnet1_region
# }

# /*************
# Cloud NAT
# **************/
# module "cloud-nat" {
#   source                             = "terraform-google-modules/cloud-nat/google"
#   version                            = ">= 2.2.1"
#   project_id                         = var.project_id
#   region                             = var.subnet1_region
#   router                             = google_compute_router.router.name
#   name                               = "nat-access"
#   source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
# }

# # NOTES:
# # See https://cloud.google.com/iap/docs/using-tcp-forwarding#grant-permission  
# # for necessary roles / permissions
# # See https://cloud.google.com/iap/docs/using-tcp-forwarding#tunneling_ssh_connections 
# # for SSH connection from terminal.