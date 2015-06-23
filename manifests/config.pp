class nav::config(
  $install_dir          = $nav::install_dir,
  $python_path          = $nav::python_path,
  $nav_user_name        = $nav::nav_user_name,
  $nav_user_uid         = $nav::nav_user_uid,
  $navcron_user_name    = $nav::navcron_user_name,
  $navcron_user_uid     = $nav::navcron_user_uid,
  $nav_user_group       = $nav::nav_user_group,
  $nav_user_gid         = $nav::nav_user_gid,
  $nav_create_db        = $nav::nav_create_db,
  $db_password          = $nav::db_password,
  $cronjobs             = $nav::cronjobs,
  $debug                = $nav::debug
) {

  # Fix bug in nav-omnibus package
  file { "${install_dir}/lib/python2.7/nav":
    ensure => link,
    target => "${install_dir}/lib/python/nav"
  }

  # Easy access to conf
  file { '/etc/nav':
    ensure => link,
    target => "${install_dir}/etc",
  }

  # Cronjobs
  create_resources('nav::cronjob', $cronjobs)

  file { $install_dir:
    ensure => directory,
    owner => $nav_user_name,
    group => $nav_user_group,
    require => User[$nav_user_name]
  }

  exec { 'chgrp_installdir_var':
    command  => "chgrp -R ${nav_user_group} ${install_dir}/var && find ${install_dir}/var -type d | /usr/bin/xargs chmod -R 775",
    path     => '/bin:/usr/bin',
    provider => 'shell',
    unless   => "test $(stat -c %G ${install_dir}/var) = ${nav_user_group}",
    require  => User[$nav_user_group]
  }

  # Create nav user and group
  user { $nav_user_name:
    uid => $nav_user_uid,
    managehome => false,
    gid => $nav_user_group,
    home => $install_dir,
    require => Class['nav::install']
  }

  user { $navcron_user_name:
    uid => $navcron_user_uid,
    managehome => false,
    gid => [ $nav_user_group, 'dialout' ],
    home => $install_dir,
    require => Class['nav::install']
  }

  group { $nav_user_group:
    gid => $nav_user_gid,
    before => User[$nav_user_name]
  }

  # Filthy, nasty db generating
  if $nav_create_db and $db_password {
    file_line { 'set_db_password':
      path  => '/usr/local/nav/etc/db.conf',
      line  => "userpw_nav=\"${db_password}\"",
      match => '^userpw_nav',
      require => Class['nav']
    } ->
    exec { 'create_db':
      user => 'postgres',
      provider => 'shell',
      command => "source ${install_dir}/bin/activate && navsyncdb -c",
      unless => 'psql -l | grep nav',
      require => Class['postgresql::server::service']
    }
  }

  # Add init our own init scripts
  file { '/etc/systemd/system/ipdevpoll.service':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template("${module_name}/etc/systemd/ipdevpoll.service.erb"),
    require => Class['nav::install']
  }

  # Store PYTHONPATH in an environment file for systemd service
  file { '/etc/sysconfig/nav' :
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template("${module_name}/etc/sysconfig/nav.erb"),
    require => Class['nav::install']
  }

  # Use debug in django
  if $debug {
    file_line { 'set_debug':
      path  => "${install_dir}/etc/nav.conf",
      line  => 'DJANGO_DEBUG=true',
      match => '^DJANGO_DEBUG',
      require => Class['nav::install']
    }
  }

}
