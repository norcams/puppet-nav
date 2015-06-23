class nav::service() {

  service { 'ipdevpoll':
    enable   => true,
    ensure   => running,
    provider => systemd,
    require  => Class['nav::config']
  }

}
