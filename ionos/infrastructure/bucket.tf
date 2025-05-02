resource "ionoscloud_s3_bucket" "bucket" {
  name                = "dataminded-terraform-test"
  region              = "eu-central-3"
  object_lock_enabled = false
  force_destroy       = true

  tags = {
    key1 = "dataminded"
    key2 = "test-bucket"
  }

  timeouts {
    create = "10m"
    delete = "10m"
  }
}