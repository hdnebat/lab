#===============================================================================
# vSphere Provider
#===============================================================================

provider "vsphere" {
  version              = "1.9.1"
  vsphere_server       = "${var.vcenter_server}"
  user                 = "${var.vcenter_user}"
  password             = "${var.vcenter_password}"
  allow_unverified_ssl = "${var.vcenter_unverified_ssl}"
}



#===============================================================================
# vSphere Data
#===============================================================================

data "vsphere_datacenter" "dc" {
  name = "${var.vsphere_datacenter}"
}

data "vsphere_compute_cluster" "cluster" {
  name          = "${var.vsphere_drs_cluster}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_resource_pool" "pool" {
  name          = "${var.vsphere_resource_pool}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_datastore_cluster" "datastore_cluster" {
  name          = "${var.vm_datastore}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_network" "network" {
  name          = "${var.vm_network}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_virtual_machine" "template" {
  name          = "${var.vm_template}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

#===============================================================================
# vSphere Resources
#===============================================================================

resource "vsphere_virtual_machine" "managers" {
  count                = "${length(var.sw_manager_ips)}"
  name                 = "${var.sw_node_prefix}-manager-${count.index}"
  resource_pool_id     = "${data.vsphere_resource_pool.pool.id}"
  datastore_cluster_id = "${data.vsphere_datastore_cluster.datastore_cluster.id}"

  num_cpus = "${var.sw_manager_cpu}"
  memory   = "${var.sw_manager_ram}"
  guest_id = "${data.vsphere_virtual_machine.template.guest_id}"

  network_interface {
    network_id   = "${data.vsphere_network.network.id}"
    adapter_type = "${data.vsphere_virtual_machine.template.network_interface_types[0]}"
  }

  disk {
    label            = "${var.sw_node_prefix}-manager-${count.index}.vmdk"
    size             = "${data.vsphere_virtual_machine.template.disks.0.size}"
    thin_provisioned = "${data.vsphere_virtual_machine.template.disks.0.thin_provisioned}"
  }

  clone {
    template_uuid = "${data.vsphere_virtual_machine.template.id}"
    linked_clone  = "${var.vm_linked_clone}"

    customize {
      linux_options {
        host_name = "${var.sw_node_prefix}-manager-${count.index}"
        domain    = "${var.lab_domain}"
      }

      network_interface {
        ipv4_address = "${lookup(var.sw_manager_ips, count.index)}"
        ipv4_netmask = "${var.lab_netmask}"
      }

      ipv4_gateway    = "${var.lab_gateway}"
      dns_server_list = ["${var.lab_dns}"]
    }
  }
}

resource "vsphere_virtual_machine" "workers" {
  count                = "${length(var.sw_worker_ips)}"
  name                 = "${var.sw_node_prefix}-worker-${count.index}"
  resource_pool_id     = "${data.vsphere_resource_pool.pool.id}"
  datastore_cluster_id = "${data.vsphere_datastore_cluster.datastore_cluster.id}"

  num_cpus = "${var.sw_worker_cpu}"
  memory   = "${var.sw_worker_ram}"
  guest_id = "${data.vsphere_virtual_machine.template.guest_id}"

  network_interface {
    network_id   = "${data.vsphere_network.network.id}"
    adapter_type = "${data.vsphere_virtual_machine.template.network_interface_types[0]}"
  }

  disk {
    label            = "${var.sw_node_prefix}-worker-${count.index}.vmdk"
    size             = "${data.vsphere_virtual_machine.template.disks.0.size}"
    thin_provisioned = "${data.vsphere_virtual_machine.template.disks.0.thin_provisioned}"
  }

  clone {
    template_uuid = "${data.vsphere_virtual_machine.template.id}"
    linked_clone  = "${var.vm_linked_clone}"

    customize {
      linux_options {
        host_name = "${var.sw_node_prefix}-worker-${count.index}"
        domain    = "${var.lab_domain}"
      }

      network_interface {
        ipv4_address = "${lookup(var.sw_worker_ips, count.index)}"
        ipv4_netmask = "${var.lab_netmask}"
      }

      ipv4_gateway    = "${var.lab_gateway}"
      dns_server_list = ["${var.lab_dns}"]
    }
  }
}


#===============================================================================
# Templates
#===============================================================================

# Hosts Manager first
data "template_file" "manager-first" {
    template = "${file("templates/hosts.tpl")}"
    vars {
    hostname = "${var.sw_node_prefix}-manager-0"
    host_ip  = "${lookup(var.sw_manager_ips, 0)}"
  }
}

data "template_file" "managers" {
    count    = "${length(var.sw_manager_ips) - 1}"
    template = "${file("templates/hosts.tpl")}"
 
    vars {
    hostname = "${var.sw_node_prefix}-manager-${count.index + 1}"
    host_ip  = "${lookup(var.sw_manager_ips, count.index + 1)}"
  }
}

data "template_file" "workers" {
    count    = "${length(var.sw_worker_ips)}"
    template = "${file("templates/hosts.tpl")}"
 
    vars {
    hostname = "${var.sw_node_prefix}-worker-${count.index}"
    host_ip  = "${lookup(var.sw_worker_ips, count.index)}"
  }
}

#===============================================================================
# Local Resources
#===============================================================================

# Create Hosts.ini from terraform template
resource "local_file" "ansible_hosts" {
  content  = "[manager-first]\n${data.template_file.manager-first.rendered}\n[managers]\n${join("", data.template_file.managers.*.rendered)}\n[workers]\n${join("", data.template_file.workers.*.rendered)}"
  filename = "ansible/hosts.ini"
}

resource "null_resource" "create_swarm" {
  provisioner "local-exec" {
    command = "cd ansible && ansible-playbook -i hosts.ini -b -u ${var.vm_user} -v docker-swarm.yml"
  }
   depends_on = ["vsphere_virtual_machine.workers","vsphere_virtual_machine.managers", "local_file.ansible_hosts"]
}