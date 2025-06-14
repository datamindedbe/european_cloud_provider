data "ionoscloud_image" "debian" {
    type                  = "HDD"
    image_alias           = "ubuntu:latest"
    location              = "de/fra"
}


resource "ionoscloud_vcpu_server" "server" {
    name                  = "ubuntu-server"
    datacenter_id         = ionoscloud_datacenter.dataminded-test.id
    cores                 = 4
    ram                   = 16384
    availability_zone     = "AUTO"
    image_name            = data.ionoscloud_image.debian.id
    ssh_keys       = [file("~/.ssh/id_rsa.pub")]
    volume {
        name              = "system"
        size              = 500
        disk_type         = "SSD Standard"
        user_data = base64encode(<<EOF
#cloud-config
users:
  - name: thorsten
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - ${trimspace(file("~/.ssh/id_rsa.pub"))}
disable_root: true
preserve_hostname: true
hostname: ubuntu-server
EOF
    )
        bus               = "VIRTIO"
        availability_zone = "AUTO"
    }
    nic {
        lan               = ionoscloud_lan.lan.id
        name              = "system"
        dhcp              = true
        firewall_active   = false
        firewall_type     = "BIDIRECTIONAL"
        firewall {
          protocol          = "TCP"
          name              = "SSH"
          port_range_start  = 22
          port_range_end    = 22
          type              = "INGRESS" 
        }
    }

    

    
    label {
        key = "labelkey1"
        value = "labelvalue1"
    }
    label {
        key = "labelkey2"
        value = "labelvalue2"
    }
}

resource "ionoscloud_nic" "private_nic" {
  datacenter_id = ionoscloud_datacenter.dataminded-test.id
  server_id     = ionoscloud_vcpu_server.server.id
  lan           = ionoscloud_lan.private_lan.id
  name          = "system-private"
  dhcp          = true
}