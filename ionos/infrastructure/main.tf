terraform {
  required_version = ">= 1.9.0"
  required_providers {
    ionoscloud = {
      source  = "ionos-cloud/ionoscloud"
      version = ">= 6.4.10"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0" # or latest
    }
  }
}

# Provider for IONOS Cloud API
provider "ionoscloud" {
  token = var.ionos_token

  s3_access_key = var.ionos_s3_access_key
  s3_secret_key = var.ionos_s3_secret_key
  s3_region     = "eu-central-3"
}

locals {
  # AWS region must be a valid AWS region string
  # even if we talk to Ionos S3 via custom endpoint
  dummy_aws_region = "eu-central-1"
}


# Provider for S3-compatible API (Ionos S3) via AWS provider
provider "aws" {
  access_key                  = var.ionos_s3_access_key
  secret_key                  = var.ionos_s3_secret_key
  region                      = local.dummy_aws_region
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    s3 = "https://s3.eu-central-3.ionoscloud.com"
  }
}

# -------------------------------
# S3 Bucket Policy Setup
# -------------------------------

# Generate the S3 bucket policy document
data "aws_iam_policy_document" "s3_bucket_policy" {
  statement {
    sid    = "AllowEssentialS3Actions"
    effect = "Allow"

    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]

    resources = [
      "arn:aws:s3:::${var.bucket_name}",
      "arn:aws:s3:::${var.bucket_name}/*"
    ]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
}

# Apply the bucket policy
resource "aws_s3_bucket_policy" "s3_policy" {
  bucket = var.bucket_name
  policy = data.aws_iam_policy_document.s3_bucket_policy.json
}
