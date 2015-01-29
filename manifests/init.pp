# == Class: nav
#
# Sets up NAV with Graphite
#
# === Parameters
#
# TODO
#
# === Variables
#
# TODO
#
# === Examples
#
#  class { 'nav': }
#
# === Authors
#
# Anders Vaage <anders@unix.uib.no>
# Raymond Kristiansen <raymond@it.uib.no>
#
# === Copyright
#
# Copyright 2015 University of Bergen
#
class nav(
  $packages            = 'nav-omnibus',
  $install_dir         = '/usr/local/nav',
  $python_path         = '/usr/lib64/python2.7',
  $use_scl             = false,
  $nav_user_name       = 'nav',
  $nav_user_uid        = undef,
  $navcron_user_name   = 'navcron',
  $navcron_user_uid    = undef,
  $nav_user_group      = 'nav',
  $nav_user_gid        = undef,
  $nav_create_db       = true,
  $graphite_dir        = '/opt/graphite',
  $graphite_user_name  = 'graphite',
  $graphite_user_uid   = undef,
  $graphite_user_group = 'graphite',
  $graphite_user_gid   = undef,
  $graphite_create_db  = true,
  $db_password         = undef,
  $debug               = false,
  $web_service         = 'httpd',
  $cronjobs            = {
    activeip          => {},
    logengine_regular => {},
    logengine_del     => {},
    mactrace          => {},
    maintengine       => {},
    netbiostracker    => {},
    psuwatch          => {},
    thresholdmon      => {},
    topology          => {}
  }
) {

  class { nav::install: } ->
  class { nav::config: } ->
  class { nav::service: }

}
