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

# output "vpc_name" {
#   description = "name of the VPC for composer and HTTP endpoint."
#   value = module.data-vpc.network_name
# }

# /*
# output "vm_name" {
#   description = "Name of the VM to connect for contextual and bidstream apis."
#   value = google_compute_instance.api.name
# }
# */

# output "service_accounts_iam_emails_list" {
#   description = "created service accounts"
#   value = module.service_accounts.iam_emails_list
# }

# output "service_accounts_emails_list" {
#   description = "created service accounts"
#   value = module.service_accounts.emails_list
# }

// Composer output:

# output "composer_env_name" {
#   description = "Name of the Cloud Composer Environment."
#   value       = module.simple-composer-environment.composer_env_name
# }

# output "composer_env_id" {
#   description = "ID of Cloud Composer Environment."
#   value       = module.simple-composer-environment.composer_env_id
# }

# output "gke_cluster" {
#   description = "Google Kubernetes Engine cluster used to run the Cloud Composer Environment."
#   value       = module.simple-composer-environment.gke_cluster
# }

# output "gcs_bucket" {
#   description = "Google Cloud Storage bucket which hosts DAGs for the Cloud Composer Environment."
#   value       = module.simple-composer-environment.gcs_bucket
# }

# output "airflow_uri" {
#   description = "URI of the Apache Airflow Web UI hosted within the Cloud Composer Environment."
#   value       = module.simple-composer-environment.airflow_uri
# }