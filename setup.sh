#!/bin/sh

dir=$(dirname $0)
if [ "$dir" = "." ]; then
	dir=$(pwd)
fi

if [ ! -d /etc/hosts.d ]; then
	mkdir /etc/hosts.d
	cp /etc/hosts /etc/hosts.d/00-base
fi

if [ -f /etc/init.d/iptables ]; then
	mv -f /etc/init.d/iptables /etc/init.d/iptables:orig
else
	rm -rf /etc/init.d/iptables
fi
ln -s "$dir"/iptables /etc/init.d/iptables

cat <<EOF >/etc/cron.d/docker-hosts-cron
*/5 * * * * root "$dir/build-docker-hosts" && "$dir/update-hosts-file"
EOF

cat <<EOF >>/etc/sysconfig/iptables-config
IPTABLES_FILTER="$dir/filter-iptables"
EOF
