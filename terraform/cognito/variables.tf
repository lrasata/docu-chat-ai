variable "environment" {
  description = "The environment for the deployment (e.g., dev, staging, prod)"
  type        = string
}

variable "region" {
  description = "The AWS region to deploy resources"
  type        = string
}

variable "callback_urls" {
  type    = list(string)
}

variable "logout_urls" {
  type    = list(string)
}