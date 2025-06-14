
resource "ionoscloud_pg_cluster" "postgres" {
  postgres_version        = "15"
  instances               = 1
  cores                   = 4
  ram                     = 4096
  storage_size            = 102400
  storage_type            = "HDD"
  connection_pooler {
    enabled = true
    pool_mode = "session"
  }
  connections   {
    datacenter_id         =  ionoscloud_datacenter.dataminded-test.id
    lan_id                =  ionoscloud_lan.private_lan.id
    cidr                  =  "192.168.100.1/24"
  }
  location                = ionoscloud_datacenter.dataminded-test.location
  display_name            = "PostgreSQL_cluster"
  maintenance_window {
    day_of_the_week       = "Sunday"
    time                  = "09:00:00"
  }
  credentials {
    username              = var.ionos_user
    password              = var.ionos_database_password
  }
  synchronization_mode    = "ASYNCHRONOUS"
}

resource "ionoscloud_pg_database" "postgres_database" {
  cluster_id = ionoscloud_pg_cluster.postgres.id
  name = "linkedin"
  owner = "thorsten"
}

