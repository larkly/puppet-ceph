#!/bin/bash

set -x
set -e

AGENT_OPTIONS="--onetime --verbose --ignorecache --no-daemonize --no-usecacheonfailure --no-splay --show_diff --debug"

# ensure a correct domain name is set from dhclient
grep -q 'supersede domain-name "test";' /etc/dhcp/dhclient.conf ||  {
    echo 'supersede domain-name "test";' >> /etc/dhcp/dhclient.conf
    pkill -9 dhclient
    dhclient eth0
}

# add hosts to /etc/hosts
grep -q "puppetmaster" /etc/hosts || echo "192.168.251.5 puppetmaster puppetmaster.test" >> /etc/hosts
grep -q "ceph-mon0" /etc/hosts || echo "192.168.251.10	ceph-mon0 ceph-mon0.test" >> /etc/hosts
grep -q "ceph-mon1" /etc/hosts || echo "192.168.251.11	ceph-mon1 ceph-mon1.test" >> /etc/hosts
grep -q "ceph-mon2" /etc/hosts || echo "192.168.251.12	ceph-mon2 ceph-mon2.test" >> /etc/hosts
grep -q "ceph-osd0" /etc/hosts || echo "192.168.251.100	ceph-osd0 ceph-osd0.test" >> /etc/hosts
grep -q "ceph-osd1" /etc/hosts || echo "192.168.251.101	ceph-osd1 ceph-osd1.test" >> /etc/hosts
grep -q "ceph-osd2" /etc/hosts || echo "192.168.251.102	ceph-osd2 ceph-osd2.test" >> /etc/hosts
grep -q "ceph-mds0" /etc/hosts || echo "192.168.251.150	ceph-mds0 ceph-mds0.test" >> /etc/hosts
grep -q "ceph-mds1" /etc/hosts || echo "192.168.251.151	ceph-mds1 ceph-mds1.test" >> /etc/hosts

aptitude update

# Install ruby 1.8 and ensure it is the default
aptitude install -y ruby
#update-alternatives --set ruby /usr/bin/ruby1.9.1


