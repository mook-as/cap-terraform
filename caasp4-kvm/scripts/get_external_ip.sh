#!/bin/sh

address=\"0.0.0.0\"
out=$(virsh qemu-agent-command tf8-c4-lb-domain '{"execute":"guest-network-get-interfaces"}') && address=$(echo ${out} | jq '. | .return[2]."ip-addresses"[0]."ip-address"') 
echo -n "{\"address\":${address}}"

