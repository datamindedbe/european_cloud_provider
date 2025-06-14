resource "ionoscloud_lan"  "lan" {
  datacenter_id           = ionoscloud_datacenter.dataminded-test.id
  public                  = true
  name                    = "public-lan"
}

resource "ionoscloud_lan"  "private_lan" {
  datacenter_id           = ionoscloud_datacenter.dataminded-test.id
  public                  = false
  name                    = "private-lan"
}