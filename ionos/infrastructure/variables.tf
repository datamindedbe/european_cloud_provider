
variable "ionos_s3_access_key" {
  type        = string
  description = "S3 access key"
  sensitive   = true
}

variable "ionos_s3_secret_key" {
  type        = string
  description = "S3 secret key"
  sensitive   = true
}

variable "ionos_token" {
  type        = string
  description = "Personal access token to ionos cloud"
  sensitive   = true
}

variable "bucket_name" {
  type        = string
  description = "test bucket"
  default     = "dataminded-terraform-test"
}