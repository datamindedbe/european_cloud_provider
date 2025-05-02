resource "ionoscloud_datacenter" "dataminded-test" {
  name                = "Datacenter Dataminded"
  location            = "de/fra"
  description         = "datacenter description"
  sec_auth_protection = false
}