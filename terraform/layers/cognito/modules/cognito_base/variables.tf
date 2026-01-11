variable "environment" {
  description = "The environment for the deployment (e.g., dev, staging, prod)"
  type        = string
}

variable "region" {
  description = "The AWS region to deploy resources"
  type        = string
}

variable "app_id" {
  type = string
}

variable "google_client_id" {
  type = string
}

variable "google_client_secret" {
  type = string
}