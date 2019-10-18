data "external" "external_interface" {
  program = ["/bin/bash", "scripts/get_external_ip.sh"]
  query = {
    id = libvirt_domain.lb.name
  }
}

output "cluster_stack_name" {
  value = var.stack_name
}

output "ip_load_balancer-internal" {
  value = libvirt_domain.lb.network_interface[0].addresses[0]
}

output "ip_load_balancer-external" {
  value = "${element(split(",", data.external.external_interface.result["address"]), 0)}" 
}

output "ip_masters" {
  value = [libvirt_domain.master.*.network_interface.0.addresses.0]
}

output "ip_workers" {
  value = [libvirt_domain.worker.*.network_interface.0.addresses.0]
}

