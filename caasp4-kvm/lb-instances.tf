data "template_file" "lb_repositories" {
  count    = length(var.lb_repositories)
  template = file("cloud-init/repository.tpl")

  vars = {
    repository_url  = element(values(var.lb_repositories), count.index)
    repository_name = element(keys(var.lb_repositories), count.index)
  }
}

data "template_file" "haproxy_apiserver_backends_master" {
  count    = var.masters
  template = "server $${fqdn} $${ip}:6443 check check-ssl verify none\n"

  vars = {
    fqdn = "${var.stack_name}-master-${count.index}.${var.dns_domain}"
    ip   = cidrhost(var.network_cidr, 512 + count.index)
  }
}

data "template_file" "haproxy_gangway_backends_master" {
  count    = var.masters
  template = "server $${fqdn} $${ip}:32001 check check-ssl verify none\n"

  vars = {
    fqdn = "${var.stack_name}-master-${count.index}.${var.dns_domain}"
    ip   = cidrhost(var.network_cidr, 512 + count.index)
  }
}

data "template_file" "haproxy_dex_backends_master" {
  count    = var.masters
  template = "server $${fqdn} $${ip}:32000 check check-ssl verify none\n"

  vars = {
    fqdn = "${var.stack_name}-master-${count.index}.${var.dns_domain}"
    ip   = cidrhost(var.network_cidr, 512 + count.index)
  }
}

data "template_file" "lb_cloud_init_userdata" {
  count    = var.lbs
  template = file("cloud-init/lb.tpl")

  vars = {
    apiserver_backends = join(
      "      ",
      data.template_file.haproxy_apiserver_backends_master.*.rendered,
    )
    gangway_backends = join(
      "      ",
      data.template_file.haproxy_gangway_backends_master.*.rendered,
    )
    dex_backends = join(
      "      ",
      data.template_file.haproxy_dex_backends_master.*.rendered,
    )
    authorized_keys = join("\n", formatlist("  - %s", var.authorized_keys))
    repositories    = join("\n", data.template_file.lb_repositories.*.rendered)
    username        = var.username
    password        = var.password
    ntp_servers     = join("\n", formatlist("    - %s", var.ntp_servers))
    ip_master0     = var.ip_master0
    ip_worker0     = var.ip_worker0
    ip_worker1     = var.ip_worker1
  }
}

resource "libvirt_volume" "lb" {
  name           = "${var.stack_name}-lb-volume"
  pool           = var.pool
  size           = var.disk_size
  base_volume_id = libvirt_volume.img.id
}

resource "libvirt_cloudinit_disk" "lb" {
  name = "${var.stack_name}-lib-cloudinit-disk"
  pool = var.pool

  user_data = data.template_file.lb_cloud_init_userdata[0].rendered
}

resource "libvirt_domain" "lb" {
  name      = "${var.stack_name}-lb-domain"
  memory    = var.lb_memory
  vcpu      = var.lb_vcpu
  cloudinit = libvirt_cloudinit_disk.lb.id
  qemu_agent = true

  cpu = {
    mode = "host-passthrough"
  }

  disk {
    volume_id = libvirt_volume.lb.id
  }

  network_interface {
    network_id     = libvirt_network.network.id
    hostname       = "${var.stack_name}-lb"
    addresses      = [cidrhost(var.network_cidr, 256)]
    wait_for_lease = true 
  }

  network_interface {
    bridge         = var.bridge_name
    mac            = var.lb_ext_mac
  }


  graphics {
    type        = "vnc"
    listen_type = "address"
  }
}

resource "null_resource" "lb_wait_cloudinit" {
  depends_on = [libvirt_domain.lb]
  count      = var.lbs

  connection {
    host = element(
      libvirt_domain.lb.*.network_interface.0.addresses.0,
      count.index,
    )
    user     = var.username
    password = var.password
    type     = "ssh"
    timeout  = "10m"
  }

  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait > /dev/null",
    ]
  }
}

resource "null_resource" "lb_zypperup" {
  depends_on = [null_resource.lb_wait_cloudinit]
  count      = var.lbs

  provisioner "local-exec" {
    environment = {
      user = var.username
      host = element(
        libvirt_domain.lb.*.network_interface.0.addresses.0,
        count.index,
      )
    }

    command = <<EOT
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $user@$host "sudo zypper up -y -l --auto-agree-with-product-licenses 2>&1>/dev/null"
EOT
  }
}

resource "null_resource" "lb_exteth1" {
  depends_on = [null_resource.lb_zypperup]
  count      = var.lbs

  provisioner "local-exec" {
    environment = {
      user = var.username
      host = element(
        libvirt_domain.lb.*.network_interface.0.addresses.0,
        count.index,
      )
    }

    command = <<EOT
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null config/ifcfg-eth1 $user@$host:/tmp
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $user@$host "sudo mv /tmp/ifcfg-eth1 /etc/sysconfig/network/"
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $user@$host "sudo wicked ifup eth1"
hostmac=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $user@$host "sudo cat /sys/class/net/eth1/address")
duidprefix=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $user@$host "sudo wicked duid get" | awk '{print$2}' | cut -d ":" -f1-8)
newduid=$(echo "$duidprefix:$hostmac")
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $user@$host "sudo sed -i '$ a DHCLIENT_SET_DEFAULT_ROUTE='no'' /etc/sysconfig/network/ifcfg-eth0"
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $user@$host "sudo rm -f /var/lib/wicked/lease-eth1-dhcp-ipv6.xml"
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $user@$host "sudo wicked duid set $newduid"
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $user@$host "sudo ip route del default"
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $user@$host "sudo netconfig update -f"
EOT
  }
}

resource "null_resource" "lb_reboot" {
  depends_on = [null_resource.lb_exteth1]
  count      = var.lbs

  provisioner "local-exec" {
    environment = {
      user = var.username
      host = element(
        libvirt_domain.lb.*.network_interface.0.addresses.0,
        count.index,
      )
    }

    command = <<EOT
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $user@$host sudo reboot || :
# wait for ssh ready after reboot
sleep 20
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectionAttempts=80 $user@$host /usr/bin/true
EOT
  }
}
