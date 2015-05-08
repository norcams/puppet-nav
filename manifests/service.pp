class nav::service() {

  # service { 'carbon_cache':
  #   ensure    => running,
  #   enable    => true,
  #   require => Class['nav::config']
  # }

  service { 'ipdevpoll':
    ensure  => running,
    require => Class['nav::config']
  }

}
