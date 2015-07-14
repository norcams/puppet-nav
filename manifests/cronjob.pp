define nav::cronjob(
  $ensure,
  $minute = undef,
  $hour = undef,
  $command = false,
  $path = false,
  $install_dir = $nav::install_dir,
  $nav_user_name = $nav::nav_user_name,
) {

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

  $python_path = "PYTHONPATH=\"${install_dir}/lib/python2.7:${install_dir}/lib/python2.7/site-packages\" 2>&1"

  cron { "nav_${name}":
    ensure  => $ensure? {
      true  => present,
      present => present,
      default => absent
    },
    user    => $nav_user_name,
    minute  => $minute,
    hour    => $hour,
    command => "${python_path} ${real_path}/${real_command}",
    require => Class['nav::install']
  }
}
