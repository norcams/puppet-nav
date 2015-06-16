class nav::service() {

  # service { 'carbon_cache':
  #   ensure    => running,
  #   enable    => true,
  #   require => Class['nav::config']
  # }

  service { 'ipdevpoll':
    enable   => true,
    ensure   => running,
    provider => systemd,
    require  => Class['nav::config']
  }

}
