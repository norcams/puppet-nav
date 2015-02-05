class nav::ldap(
  $install_dir = $nav::install_dir,
  $web_service = $nav::web_service,
  $debug       = $nav::debug,
  $settings    = hiera_hash('nav::ldap_settings', { enable => false })
){

  # {   **enable => false,
  #     *server => 'ldap.ha.uib.no',
  #     *port => '636',
  #     encryption => 'ssl',
  #     uid_attr => 'uid',
  #     name_attr => 'cn',
  #     *basedn => 'dc=uib,dc=no',
  #     require_group => '',
  #     *debug => 'yes'
  # }

  # LDAP config
  file { "${install_dir}/etc/webfront/webfront.conf":
    ensure => file,
    owner => 'root',
    group => 'root',
    mode => '0644',
    content => template("${module_name}/etc/webfront.conf.erb"),
    require => Class['nav::install'],
    notify =>$web_service? { undef => undef, default => Service[$web_service] }
  }
}
