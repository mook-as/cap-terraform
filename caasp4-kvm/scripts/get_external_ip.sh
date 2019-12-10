#!/bin/sh

out=$(virsh qemu-agent-command $1 '{"execute":"guest-network-get-interfaces"}')
: "${address:=$(echo $out | grep -o -e 'eth1'.*.'ipv4'.*.'"prefix":24' | grep -o -e '"'.[0-9].'.'.*.'.'.[0-9].'"')}" "${address:=\"0.0.0.0\"}"
echo -n "{\"address\":${address}}"
