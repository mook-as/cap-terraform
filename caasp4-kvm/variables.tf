variable "libvirt_uri" {
  default     = "qemu:///system"
  description = "URL of libvirt connection - default to localhost"
}

variable "pool" {
  default     = "default"
  description = "Pool to be used to store all the volumes"
}

variable "image_uri" {
  default     = ""
  description = "URL of the image to use"
}

variable "repositories" {
  type        = map(string)
  default     = {}
  description = "Urls of the repositories to mount via cloud-init"
}

variable "stack_name" {
  default     = ""
  description = "Identifier to make all your resources unique and avoid clashes with other users of this terraform project"
}

variable "authorized_keys" {
  type        = list(string)
  default     = []
  description = "SSH keys to inject into all the nodes"
}

variable "ntp_servers" {
  type        = list(string)
  default     = []
  description = "List of NTP servers to configure"
}

variable "packages" {
  type = list(string)

  default = [
    "kernel-default",
    "-kernel-default-base",
  ]

  description = "List of packages to install"
}

variable "username" {
  default     = "sles"
  description = "Username for the cluster nodes"
}

variable "password" {
  default     = "linux"
  description = "Password for the cluster nodes"
}

variable "caasp_registry_code" {
  default     = ""
  description = "SUSE CaaSP Product Registration Code"
}

variable "ha_registry_code" {
  default     = ""
  description = "SUSE Linux Enterprise High Availability Extension Registration Code"
}

variable "rmt_server_name" {
  default     = ""
  description = "SUSE Repository Mirroring Server Name"
}

variable "disk_size" {
  default     = "21474836480"
  description = "Disk size (in bytes)"
}

variable "master_disk_size" {
  default     = "64424509440"
  description = "Disk size (in bytes)"
}

variable "worker_disk_size" {
  default     = "107374182400"
  description = "Disk size (in bytes)"
}

variable "dns_domain" {
  type        = string
  default     = "caasp.local"
  description = "Name of DNS Domain"
}

variable "network_cidr" {
  type        = string
  default     = "10.16.0.0/22"
  description = "Network used by the cluster"
}

variable "network_mode" {
  type        = string
  default     = "nat"
  description = "Network mode used by the cluster"
}

variable "lbs" {
  default     = 1
  description = "Number of load-balancer nodes"
}

variable "lb_memory" {
  default     = 2048
  description = "Amount of RAM for a load balancer node"
}

variable "lb_vcpu" {
  default     = 1
  description = "Amount of virtual CPUs for a load balancer node"
}

variable "lb_repositories" {
  type = map(string)

  default = {
    sle_server_pool    = "http://download.suse.de/ibs/SUSE/Products/SLE-Product-SLES/15-SP1/x86_64/product/"
    basesystem_pool    = "http://download.suse.de/ibs/SUSE/Products/SLE-Module-Basesystem/15-SP1/x86_64/product/"
    ha_pool            = "http://download.suse.de/ibs/SUSE/Products/SLE-Module-HA/15/x86_64/product/"
    sle_server_updates = "http://download.suse.de/ibs/SUSE/Updates/SLE-Product-SLES/15-SP1/x86_64/update/"
    basesystem_updates = "http://download.suse.de/ibs/SUSE/Updates/SLE-Module-Basesystem/15-SP1/x86_64/update/"
  }
}

variable "masters" {
  default     = 1
  description = "Number of master nodes"
}

variable "master_memory" {
  default     = 2048
  description = "Amount of RAM for a master"
}

variable "master_vcpu" {
  default     = 2
  description = "Amount of virtual CPUs for a master"
}

variable "workers" {
  default     = 2
  description = "Number of worker nodes"
}

variable "worker_memory" {
  default     = 2048
  description = "Amount of RAM for a worker"
}

variable "worker_vcpu" {
  default     = 2
  description = "Amount of virtual CPUs for a worker"
}

variable "bridge_name" {
  default     = "br0"
  description = "Bridge to connect the loadbalancer to"
}

variable "lb_ext_mac" {
  default     = "52:54:00:db:00:01"
  description = "MAC address for the external bridged network interface of the loadbalancer"
}

variable "master0_ext_mac" {
  default     = "52:54:00:db:00:02"
  description = "MAC address for the external bridged network interface of master1"
}

variable "worker0_ext_mac" {
  default     = "52:54:00:db:00:03"
  description = "MAC address for the external bridged network interface of worker1"
}

variable "worker1_ext_mac" {
  default     = "52:54:00:db:00:04"
  description = "MAC address for the external bridged network interface of worker2"
}

variable "ip_master0" {
  default     = "10.16.2.0"
  description = "Internal IP of first master for haproxy"
}

variable "ip_worker0" {
  default     = "10.16.3.0"
  description = "Internal IP of first worker for haproxy"
}

variable "ip_worker1" {
  default     = "10.16.3.1"
  description = "Internal IP of second worker for haproxy"
}
