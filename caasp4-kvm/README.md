### Changes for CAP (cap.suse.de)

#### General

These scripts are modified to work with terraform 0.12+. Terraform should be installed and run on the SLE-15-SP1 host system of your KVM setup (running remote wasn't tested).

In addition to that ...

 * CAP related ports are configured on the LB (haproxy)
 * LB to have an external interface/IP (eth1, DHCP)
 * By default internal IBS repos are used (no key needed)
 * All updates are applied to SLE-15-SP1 and CaaSP4
 * `swapaccount` is enabled on KUBE nodes
 * Output with relevant information for bootstrapping

So on your KVM host system you need to prepare the following:

See CaaSP4 documentation on those topics: https://documentation.suse.com/suse-caasp/4.0/html/caasp-deployment/_deployment_instructions.html

 * Basic SSH Key Configuration
 * Installation Tools (again, you can use IBS repositories - see example below)

Find more information, and details to `terraform.tfvars.json.example` below.

Finally after deploying the nodes with terraform, you would continue to bootstrap the cluster using `skuba` - see CaaSP4 documentation.

---

## Introduction

These terraform definitions are going to create the whole
cluster on KVM via terraform-provider-libvirt.

## Prerequisites

Follow instructions at https://github.com/dmacvicar/terraform-provider-libvirt#installing to install terraform-provider-libvirt.

## Deployment

Use `terraform` to deploy the cluster. `-parallelism=1` used in apply command avoids potential concurrent issues in terraform-provider-libvirt.

```sh
terraform init
terraform apply -parallelism=1
```

## Machine access

It is important to have your public ssh key within the `authorized_keys`, this is done by `cloud-init` through a terraform variable called `authorized_keys`.

All the instances have a `sles` user, password is not set. User can login only as `sles` user over SSH by using his private ssh key. The `sles` user can perform `sudo` without specifying a password.

## Load balancer

The kubernetes api-server instances running inside of the cluster are
exposed by a load balancer managed by OpenStack.

## Customization

IMPORTANT: Please define unique `stack_name` value in `terrafrom.tfvars` file to not interfere with other deployments.

Copy the `terraform.tfvars.example` to `terraform.tfvars` and provide reasonable values.

## Variables

`image_uri` - URL of the image to use
`stack_name` - Identifier to make all your resources unique and avoid clashes with other users of this terraform project
`authorized_keys` - A list of ssh public keys that will be installed on all nodes
`repositories` - Additional repositories that will be added on all nodes
`packages` - Additional packages that will be installed on all nodes

### Please use one of the following options:

`caasp_registry_code` - Provide SUSE CaaSP Product Registration Code in `registration.auto.tfvars` file to register product against official SCC server  
`rmt_server_name` - Provide SUSE Repository Mirroring Tool Server Name in `registration.auto.tfvars` file to use repositories stored on RMT server

---

### Changes for CAP (cap.suse.de) - Details

#### Prerequisites (KVM host)

Also review steps above, e.g. for terraform-provider-libvirt.

* Make sure your terraform version is at 0.12+
* Install the following modules, products, patterns and packages on your KVM host system:
  - SLE-15-SP1 container module
  - CaaSP4 product
  - SUSE-CaaSP-Management pattern
  - jq package

Using IBS repos on your KVM host instead of registering with `SUSEConnect`) - ! VPN required from the outside !

```sh
zypper up -y -l --auto-agree-with-product-licenses
zypper ar --no-gpgcheck --enable --refresh --name containers_pool http://download.suse.de/ibs/SUSE/Products/SLE-Module-Containers/15-SP1/x86_64/product/ containers_pool
zypper ar --no-gpgcheck --enable --refresh --name containers_updates http://download.suse.de/ibs/SUSE/Updates/SLE-Module-Containers/15-SP1/x86_64/update/ containers_updates
zypper ar --no-gpgcheck --enable --refresh --name caasp_product http://download.suse.de/ibs/SUSE/Products/SUSE-CAASP/4.0/x86_64/product/ caasp_product
zypper ar --no-gpgcheck --enable --refresh --name caasp_updates http://download.suse.de/ibs/SUSE/Updates/SUSE-CAASP/4.0/x86_64/update/ caasp_updates
zypper in -y -l --auto-agree-with-product-licenses sle-module-containers-release
zypper in -y -l --auto-agree-with-product-licenses caasp-release
zypper in -y -l -t pattern SUSE-CaaSP-Management
zypper in -y -l jq
```

If you like to register with a valid key using `SUSEConnect`, refer to the CaaSP4 documentation mentioned above.

#### Variables

You would start with copying `terraform.tfvars.json.example` to `terraform.tfvars.json` to modify it.
Resource related variables like memory, vcpu and storage are more on the higher side. So check your targeted system for that.
Also variables had been extended for cap.suse.de QA deployments:

`network_cidr` e.g. "10.16.0.0/22" - for multiple clusters on the same host you should use e.g. "10.17.0.0/22" for a second one

Current status/workaround for lb rules is to support 1 Master and two Workers only, and to give their IPs separately:
`ip_master0` e.g. "10.16.2.0", resp. "10.17.2.0" for a second
`ip_worker0` e.g. "10.16.3.0", resp. "10.17.3.0" for a second
`ip_worker1` e.g. "10.16.3.1", resp. "10.17.3.1" for a second
`masters` 1
`workers` 2

#### External Interface (eth1) for the LB Instance (e.g. 10.16.1.0 internally on eth0)

Still within `terraform.tfvars.json` you'll have to preset a MAC address:

`lb_ext_mac` e.g. "52:54:00:00:00:00" - intended to match an existing DHCP entry in cap.suse.de

Otherwise it would get a dynamic DHCP address, if there's dynamic DHCP available.
! Of course you need to take care to not duplicate MAC addresses in your network !

In addition to that you could configure that interface in `config/ifcfg-eth1`, to e.g. set "MTU"

The LB external IP will be show in terraform output.

#### IBS repos used for your CaaSP4 cluster (registered without key)

Don't give anything but leave `registration.auto.tfvars` unchanged, to use IBS repos for your later CaaSP4 cluster (registered without key).
