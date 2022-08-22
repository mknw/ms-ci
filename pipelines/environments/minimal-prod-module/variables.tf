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


#  This configuration sets defaults for both dev and prod. 
#  Each environment overrides the relative settings in 
#  `environments/{env,prod}/terraform.tfvars`.


variable "project_id" {
  type        = string
  description = "Project ID of GCP project to be used"
  default     = "ornate-reef-342810"
}

variable "environment" {
  type        = string
  description = "Name of the environment (dev or prod)"
  default     = "dev"
}

variable "subnet1_region" {
  type        = string
  description = "GCP Region where first subnet will be created"
  default     = "europe-west4"
}

variable "subnet1_zone" {
  type        = string
  description = "GCP Zone within Subnet1 Region where GCE instance will be created"
  default     = "europe-west4-a"
}

variable "subnet1_cidr" {
  type        = string
  description = "VPC Network CIDR to be assigned to the VPC being created"
  default     = "10.0.0.0/16"
}

variable "subnet2_region" {
  type        = string
  description = "GCP Region where first subnet will be created"
  default     = "europe-west4"
}

variable "subnet2_zone" {
  type        = string
  description = "GCP Zone within Subnet2 Region where GCE instance will be created"
  default     = "europe-west4-a"
}

variable "subnet2_cidr" {
  type        = string
  description = "VPC Network CIDR to be assigned to the VPC being created"
  default     = "20.0.0.0/16"
}

variable "composer_env_name" {
  description = "Name of Cloud Composer Environment."
  default     = "exp-composer-env"
  type        = string
}

# variable "composer_service_account" {
#   description = "Service Account to be used for running Cloud Composer Environment."
#   type        = string
# }

variable "pod_ip_allocation_range_name" {
  description = "The name of the cluster's secondary range used to allocate IP addresses to pods."
  type        = string
  default     = "ip-range-pods"
}

variable "service_ip_allocation_range_name" {
  type        = string
  description = "The name of the services' secondary range used to allocate IP addresses to the cluster."
  default     = "ip-range-svc"
}

/*
New Vars
*/

variable "environment_size" {
  type = string
  default = "ENVIRONMENT_SIZE_MEDIUM"
}