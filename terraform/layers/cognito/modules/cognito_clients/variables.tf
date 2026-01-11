variable "environment" {
  description = "The environment for the deployment (e.g., dev, staging, prod)"
  type        = string
  default     = "staging"
}

variable "callback_urls" {
  type    = list(string)
  default = ["http://localhost:5173/"]
}

variable "logout_urls" {
  type    = list(string)
  default = ["http://localhost:5173/"]
}

variable "cognito_user_pool_id" {
  description = "Cognito user pool id"
  type        = string
}
