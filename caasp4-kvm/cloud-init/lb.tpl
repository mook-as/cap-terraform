#cloud-config

# set locale
locale: en_US.UTF-8

# set timezone
timezone: Etc/UTC

# set root password
chpasswd:
  list: |
    root:linux
    ${username}:${password}
  expire: False

ssh_authorized_keys:
${authorized_keys}

ntp:
  enabled: true
  ntp_client: chrony
  config:
    confpath: /etc/chrony.conf
  servers:
${ntp_servers}

# need to disable gpg checks because the cloud image has an untrusted repo
zypper:
  repos:
${repositories}
  config:
    gpgcheck: "off"
    solver.onlyRequires: "true"
    download.use_deltarpm: "true"

# need to remove the standard docker packages that are pre-installed on the
# cloud image because they conflict with the kubic- ones that are pulled by
# the kubernetes packages
packages:
  - haproxy

write_files:
- path: /etc/haproxy/haproxy.cfg
  content: |
    defaults
      timeout connect 10s
      timeout client 86400s
      timeout server 86400s

    listen stats
      bind    *:9000
      mode    http
      stats   hide-version
      stats   uri       /stats

    listen cap-80
      bind   *:80
      server ${ip_master0} ${ip_master0}:80
      server ${ip_worker0} ${ip_worker0}:80
      server ${ip_worker1} ${ip_worker1}:80

    listen cap-443
      bind   *:443
      server ${ip_master0} ${ip_master0}:443
      server ${ip_worker0} ${ip_worker0}:443
      server ${ip_worker1} ${ip_worker1}:443

    listen cap-2222
      bind   *:2222
      server ${ip_master0} ${ip_master0}:2222
      server ${ip_worker0} ${ip_worker0}:2222
      server ${ip_worker1} ${ip_worker1}:2222

    listen cap-2793
      bind   *:2793
      server ${ip_master0} ${ip_master0}:2793
      server ${ip_worker0} ${ip_worker0}:2793
      server ${ip_worker1} ${ip_worker1}:2793

    listen cap-4443
      bind   *:4443
      server ${ip_master0} ${ip_master0}:4443
      server ${ip_worker0} ${ip_worker0}:4443
      server ${ip_worker1} ${ip_worker1}:4443

    listen cap-7443
      bind   *:7443
      option httpchk GET /healthz
      server ${ip_master0} ${ip_master0}:7443
      server ${ip_worker0} ${ip_worker0}:7443
      server ${ip_worker1} ${ip_worker1}:7443

    listen cap-8443
      bind   *:8443
      server ${ip_master0} ${ip_master0}:8443
      server ${ip_worker0} ${ip_worker0}:8443
      server ${ip_worker1} ${ip_worker1}:8443

    listen cap-20000
      bind   *:20000
      server ${ip_master0} ${ip_master0}:20000
      server ${ip_worker0} ${ip_worker0}:20000
      server ${ip_worker1} ${ip_worker1}:20000

    listen cap-20001
      bind   *:20001
      server ${ip_master0} ${ip_master0}:20001
      server ${ip_worker0} ${ip_worker0}:20001
      server ${ip_worker1} ${ip_worker1}:20001

    listen cap-20002
      bind   *:20002
      server ${ip_master0} ${ip_master0}:20002
      server ${ip_worker0} ${ip_worker0}:20002
      server ${ip_worker1} ${ip_worker1}:20002

    listen cap-20003
      bind   *:20003
      server ${ip_master0} ${ip_master0}:20003
      server ${ip_worker0} ${ip_worker0}:20003
      server ${ip_worker1} ${ip_worker1}:20003

    listen cap-20004
      bind   *:20004
      server ${ip_master0} ${ip_master0}:20004
      server ${ip_worker0} ${ip_worker0}:20004
      server ${ip_worker1} ${ip_worker1}:20004

    listen cap-20005
      bind   *:20005
      server ${ip_master0} ${ip_master0}:20005
      server ${ip_worker0} ${ip_worker0}:20005
      server ${ip_worker1} ${ip_worker1}:20005

    listen cap-20006
      bind   *:20006
      server ${ip_master0} ${ip_master0}:20006
      server ${ip_worker0} ${ip_worker0}:20006
      server ${ip_worker1} ${ip_worker1}:20006

    listen cap-20007
      bind   *:20007
      server ${ip_master0} ${ip_master0}:20007
      server ${ip_worker0} ${ip_worker0}:20007
      server ${ip_worker1} ${ip_worker1}:20007

    listen cap-20008
      bind   *:20008
      server ${ip_master0} ${ip_master0}:20008
      server ${ip_worker0} ${ip_worker0}:20008
      server ${ip_worker1} ${ip_worker1}:20008

    listen cap-20009
      bind   *:20009
      server ${ip_master0} ${ip_master0}:20009
      server ${ip_worker0} ${ip_worker0}:20009
      server ${ip_worker1} ${ip_worker1}:20009

    frontend apiserver
      bind :6443
      default_backend apiserver-backend

    frontend gangway
      bind :32001
      default_backend gangway-backend

    frontend dex
      bind :32000
      default_backend dex-backend

    backend apiserver-backend
      option httpchk GET /healthz
      ${apiserver_backends}

    backend gangway-backend
      option httpchk GET /
      ${gangway_backends}

    backend dex-backend
      option httpchk GET /healthz
      ${dex_backends}

runcmd:
  # Since we are currently inside of the cloud-init systemd unit, trying to
  # start another service by either `enable --now` or `start` will create a
  # deadlock. Instead, we have to use the `--no-block-` flag.
  - [ systemctl, enable, --now, --no-block, haproxy ]
  - [ systemctl, disable, --now, --no-block, firewalld ]
  # The template machine should have been cleaned up, so no machine-id exists
  - [ dbus-uuidgen, --ensure ]
  - [ systemd-machine-id-setup ]
  # With a new machine-id generated the journald daemon will work and can be restarted
  # Without a new machine-id it should be in a failed state
  - [ systemctl, restart, systemd-journald ]

bootcmd:
  - ip link set dev eth0 mtu 1400
  # Hostnames from DHCP - otherwise localhost will be used
  - /usr/bin/sed -ie "s#DHCLIENT_SET_HOSTNAME=\"no\"#DHCLIENT_SET_HOSTNAME=\"yes\"#" /etc/sysconfig/network/dhcp
  - netconfig update -f

final_message: "The system is finally up, after $UPTIME seconds"
