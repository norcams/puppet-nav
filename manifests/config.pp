class nav::config(
  $install_dir          = $nav::install_dir,
  $python_path          = $nav::python_path,
  $use_scl              = $nav::use_scl,
  $nav_user_name        = $nav::nav_user_name,
  $nav_user_uid         = $nav::nav_user_uid,
  $navcron_user_name    = $nav::navcron_user_name,
  $navcron_user_uid     = $nav::navcron_user_uid,
  $nav_user_group       = $nav::nav_user_group,
  $nav_user_gid         = $nav::nav_user_gid,
  $nav_create_db        = $nav::nav_create_db,
  $graphite_dir         = $nav::graphite_dir,
  $graphite_user_name   = $nav::graphite_user_name,
  $graphite_user_uid    = $nav::graphite_user_uid,
  $graphite_user_group  = $nav::graphite_user_group,
  $graphite_user_gid    = $nav::graphite_user_gid,
  $graphite_create_db   = $nav::graphite_create_db,
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

  # Update graphite.conf
  file { "${install_dir}/etc/graphite.conf":
    ensure => file,
    owner => 'root',
    group => 'root',
    mode => '0644',
    content => template("${module_name}/etc/graphite.conf.erb"),
    require => Class['nav::install']
  }

  exec { 'chown_graphite_storage':
    command  => "chown -R ${graphite_user_name}:${graphite_user_group} ${graphite_dir}/storage && find ${graphite_dir}/storage -type d | /usr/bin/xargs chmod -R 775",
    path     => '/bin:/usr/bin',
    provider => 'shell',
    unless   => "test $(stat -c %U ${graphite_dir}/storage) = ${graphite_user_group}",
    require  => User[$graphite_user_name]
  }

  # Add carbon config files
  file { "${graphite_dir}/conf/carbon.conf":
    ensure => file,
    owner => 'root',
    group => 'root',
    mode => '0644',
    content => template("${module_name}/graphite/carbon.conf.erb"),
    require => Class['nav::install']
  }

  file { "${graphite_dir}/conf/storage-aggregation.conf":
    ensure => file,
    owner => 'root',
    group => 'root',
    mode => '0644',
    content => template("${module_name}/graphite/storage-aggregation.conf.erb"),
    require => Class['nav::install']
  }

  file { "${graphite_dir}/conf/storage-schemas.conf":
    ensure => file,
    owner => 'root',
    group => 'root',
    mode => '0644',
    content => template("${module_name}/graphite/storage-schemas.conf.erb"),
    require => Class['nav::install']
  }

  # Graphite wsgi conf
  # exec { 'create graphite.wsgi':
  #   creates => "${graphite_dir}/conf/graphite.wsgi",
  #   path => '/bin',
  #   provider => 'shell',
  #   command => "cd ${graphite_dir}/conf && cp graphite.wsgi.example graphite.wsgi",
  #   require => Class['nav::install']
  # }

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

  # Create graphite user and group
  user { $graphite_user_name:
    uid => $graphite_user_uid,
    managehome => false,
    gid => $graphite_user_gid,
    home => $graphite_dir,
    require => Class['nav::install']
  }
  group { $graphite_user_group:
    gid => $graphite_user_gid,
    before => User[$graphite_user_name]
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
      command => "source /opt/rh/python27/enable && source ${install_dir}/bin/activate && navsyncdb -c",
      unless => 'psql -l | grep nav',
      require => Class['postgresql::server::service']
    }
  }

  # And the same filthy, nasty, revolting db generation for graphite
  if $graphite_create_db {
    exec { 'create_graphite_db':
      user => 'graphite',
      provider => 'shell',
      environment => 'PYTHONPATH=/opt/graphite/lib/python2.6/site-packages',
      command => "python ${graphite_dir}/webapp/graphite/manage.py syncdb --noinput",
      unless => 'test -e /opt/graphite/storage/graphite.db',
      require => Class['nav']
    }
  }

  # Add $install_dir to python's sys.path
  file { "${python_path}/sitecustomize.py":
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template("${module_name}/python/sitecustomize.py.erb"),
    require => Class['nav::install']
  }

  # Add init our own init scripts
  file { '/etc/init.d/ipdevpoll':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => template("${module_name}/etc/init.d/ipdevpoll.erb"),
    require => Class['nav::install']
  }

  # Add init our own init scripts
  file { '/etc/init.d/carbon_cache':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => template("${module_name}/etc/init.d/carbon_cache.erb"),
    notify  => Service['carbon_cache'],
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
