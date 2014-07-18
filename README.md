docker-halfhitch
================

This is a collection of tools to assist in binding docker containers
to a docker host, particularly with respect to networking.  Docker's
networking support leaves some anxiety-inducing gaps.

To install, clone this repository, cd to it, and run `./setup.sh`.
*Do not delete the git repository clone.*  Ongoing operation uses
the files; they are not copied elsewhere.

Docker-halfhitch sets up two things:

* a cron job in `/etc/cron.d/docker-hosts-cron`
	This cron job runs every 5 minutes, and updates the hosts file
	with IP entries for docker containers.  See below for details.

* it enables hostname-based rules in iptables
	Some pieces of iptables rules accept hostnames, but not all. For
	NAT port forwarding, for example, will take only an IP address --
	but that's very much the kind of thing you want while running
	Docker.  So this lets you use the notation `{hostname}` to indicate
	a runtime substitution of `hostname`'s IP address.  We modify
	/etc/init.d/iptables to do so.

	*The `iptables` script we use is bundled, and comes from the
	Scientific Linux 6 distribution. It probably will not work
	in other distributions.*

### Cron job

The cron job runs `build-docker-hosts` and `update-hosts-file`.

`setup.sh` creates a directory at /etc/hosts.d (if needed) and places a
file named `00-base` in it.  `00-base` is a copy of your extant
`/etc/hosts`.  `build-docker-hosts` works inside this directory; it
lists all Docker containers, extracting their names and IP addresses,
and constructing a hosts file for those containers in `10-docker`.

`update-hosts-file` concatenates all files in `/etc/hosts.d` into
a temporary file.  If that file is the same as `/etc/hosts`, it does
nothing.  If different, it replaces `/etc/hosts` with the new hosts
file, then restarts iptables.  If confirms that at least `localhost`
is in the new hosts file first.

### iptables

The modified version of `/etc/init.d/iptables` does only one thing
differently from a stock SL6 script: if `IPTABLES_FILTER` is defined,
it filters `/etc/sysconfig/iptables` through that program before
running `iptables-restore`.  `IPTABLES_FILTER` may be defined in
`/etc/sysconfig/iptables-config`.

The `setup.sh` script appends IPTABLES_FILTER to `iptables-config`.

`filter-iptables` is the filter program that is used.  It does very
little: it only copies stdin to stdout, replacing any hostname in curly
brackets with its IP address.  For example, this line:
	-A INPUT ! --dport 53 -d {google-public-dns-a.google.com} -j DROP

would translate to:
	-A INPUT ! --dport 53 -d 8.8.8.8 -j DROP

and block the use of any DNS except Google's.

