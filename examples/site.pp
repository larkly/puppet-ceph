$fsid = '07d28faa-48ae-4356-a8e3-19d5b81e159e'
$mon_secret = 'AQD7kyJQQGoOBhAAqrPAqSopSwPrrfMMomzVdw=='
$apt_source_location = 'http://ceph.com/debian-firefly'

Exec {
  path => '/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin'
}

#
class role_ceph (
  $fsid,
  $auth_type = 'cephx'
) {

  class { 'ceph::conf':
    fsid            => $fsid,
    auth_type       => $auth_type,
    cluster_network => "${::network_eth2}/24",
    public_network  => "${::network_eth1}/24"
  }

  include ceph::apt::ceph

}

#
class role_ceph_mon (
  $id
) {

  class { 'role_ceph':
    fsid      => $::fsid,
    auth_type => 'cephx',
  }

  ceph::mon { $id:
    monitor_secret => $::mon_secret,
    mon_port       => 6789,
    mon_addr       => $::ipaddress_eth2,
  }

}

node 'puppetmaster.test' {
}

node 'gitlab.test' {
  include docker
  docker::run { 'gitlab-postgresql':
    image => 'sameersbn/postgresql',
    env => ['DB_NAME=gitlabhq_production', 'DB_USER=gitlab', 'DB_PASS=password'],
    volumes => ['/vagrant/examples/gitlab/postgresql:/var/lib/postgresql'],
    pull_on_start => true,
  }
  docker::run { 'gitlab-redis':
    image => 'sameersbn/redis',
    #env => ['DB_NAME=gitlabhq_production', 'DB_USER=gitlab', 'DB_PASS=password'],
    pull_on_start => true,
  }
  docker::run { 'gitlab':
    image => 'sameersbn/gitlab',
    ports => ['80', '443', '22'],
    expose => ['80', '443'],
    pull_on_start => true,
    links => 'gitlab-postgresql:postgresql',
    #depends => 'gitlab-postgresql',
  }
}

node 'ceph-mon0.test' {
  if !empty($::ceph_admin_key) {
    @@ceph::key { 'admin':
      secret       => $::ceph_admin_key,
      keyring_path => '/etc/ceph/keyring',
    }
  }
  class { 'role_ceph_mon': id => 0 }
}

node 'ceph-mon1.test' {
  class { 'role_ceph_mon': id => 1 }
}

node 'ceph-mon2.test' {
  class { 'role_ceph_mon': id => 2 }
}

node /ceph-osd.?\.test/ {

  class { 'role_ceph':
    fsid      => $::fsid,
    auth_type => 'cephx',
  }

  class { 'ceph::osd' :
    public_address  => $ipaddress_eth1,
    cluster_address => $ipaddress_eth2,
  }

  #ceph::osd::device { '/dev/sdb': journal => '/dev/sdd1' }
  ceph::osd::device { '/dev/sdb':  }
  #ceph::osd::device { '/dev/sdc': journal => '/dev/sdd2' }
  ceph::osd::device { '/dev/sdc':  }
}

node 'ceph-mds0.test' {
    class { 'ceph_mds': id => 0 }
}

node 'ceph-mds1.test' {
    class { 'ceph_mds': id => 1 }
}
