data "external" "external_interface" {
  depends_on = [null_resource.lb_reboot]
  program = ["/bin/bash", "scripts/get_external_ip.sh", libvirt_domain.lb.name]
  }

output "cluster_stack_name" {
  value = var.stack_name
}

output "ip_load_balancer-fqdn" {
  value = format("%s-lb.cap.suse.de", var.stack_name)
}

output "ip_load_balancer-external" {
  value = "${element(split(",", data.external.external_interface.result["address"]), 0)}"
  depends_on = [null_resource.lb_reboot]
}

output "ip_load_balancer-internal" {
  value = libvirt_domain.lb.network_interface[0].addresses[0]
}

output "ip_masters" {
  value = [libvirt_domain.master.*.network_interface.0.addresses.0]
}

output "ip_workers" {
  value = [libvirt_domain.worker.*.network_interface.0.addresses.0]
