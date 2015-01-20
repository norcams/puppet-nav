define nav::cronjob(
  $ensure,
  $minute = undef,
  $hour = undef,
  $command = false,
  $path = false,
  $install_dir = $nav::install_dir,
  $nav_user_name = $nav::nav_user_name
) {

  #file { "/etc/cron.d/${name}":
  #  ensure => $ensure? { true => link, default => absent },
  #  target => "${install_dir}/etc/cron.d/${name}",
  #}

  if $command == false {
    $real_command = $name
  } else {
    $real_command = $command
  }

  if $path == false {
    $real_path = "${install_dir}/bin"
  } else {
    $real_path = $path
  }

  cron { "nav_${name}":
    ensure => $ensure? { true => present, present => present, default => absent },
    user => $nav_user_name,
    minute => $minute,
    hour => $hour,
    command => "source /opt/rh/python27/enable && source ${install_dir}/bin/activate && ${real_path}/${real_command}",
  }
}
