class nav::config(
  $install_dir          = $nav::install_dir,
  $nav_user_name        = $nav::nav_user_name,
  $nav_user_uid         = $nav::nav_user_uid,
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

  # Graphite wsgi conf
  exec { 'create graphite.wsgi':
    creates => "${graphite_dir}/conf/graphite.wsgi",
    path => '/bin',
    provider => 'shell',
    command => "cd ${graphite_dir}/conf && cp graphite.wsgi.example graphite.wsgi",
    require => Class['nav::install']
  }

  file { "${graphite_dir}/storage":
    ensure => directory,
    recurse => false,
    owner => 'graphite',
    group => 'graphite',
    require => User[$graphite_user_name] 
  }

  file { $install_dir:
    ensure => directory,
    owner => $nav_user_name,
    group => $nav_user_group,
    require => User[$nav_user_name]
  }

  # nav/var must be writable
  file { "${install_dir}/var":
    ensure => directory,
    recurse => false,
    owner => $nav_user_name,
    group => $nav_user_group,
    require => User[$nav_user_name]
  }

  # Create nav user and group
  user { $nav_user_name:
    uid => $nav_user_uid,
    managehome => false,
    gid => $nav_user_group,
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
