vcenter_user = "administrator"
vcenter_server = "10.196.1.152"
vcenter_unverified_ssl = true
vsphere_datacenter = "Godwit.io"
vsphere_drs_cluster = "Development"
vsphere_resource_pool = "Swarm"
vm_user = "root"
vm_ssh_private_key = "~/.ssh/id_rsa"
vm_datastore = "ds"
vm_network = "Private"
vm_template = "template"
sw_haproxy_ip = "10.10.40.30"
sw_haproxy_cpu = 2
sw_haproxy_ram = 2048

sw_jaeger_ip = "10.10.40.31"
sw_jaeger_cpu = 2
sw_jaeger_ram = 2048


sw_prometheus_ip = "10.10.40.32"
sw_prometheus_cpu = 2
sw_prometheus_ram = 2048

sw_manager_ips = {
    "0" = "10.10.40.10"
    "1" = "10.10.40.11"
    "2" = "10.10.40.12"
}
sw_worker_ips = {
    "0" = "10.10.40.20"
    "1" = "10.10.40.21"
    "2" = "10.10.40.22"
    "3" = "10.10.40.23"
    "4" = "10.10.40.24"
    "5" = "10.10.40.25"
    "6" = "10.10.40.26"
}

lab_netmask = "24"
sw_node_prefix = "lab"
lab_gateway = "10.10.40.1"
lab_dns = "10.10.40.1"
lab_domain = "localdomain"
sw_manager_cpu = 2
sw_manager_ram = 1536
sw_worker_cpu = 4
sw_worker_ram = 4096

sw_elk_ips = {
    "0" = "10.10.40.35"
    "1" = "10.10.40.36"
    "2" = "10.10.40.37"
}
sw_elk_cpu = 4
sw_elk_ram = 8192