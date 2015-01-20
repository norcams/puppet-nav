class nav::install(
  $packages = $nav::packages
) {

  package { $packages: 
    ensure => installed,
  }
}
