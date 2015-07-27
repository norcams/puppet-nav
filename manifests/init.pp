# == Class: nav
#
# Sets up NAV
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
  $nav_user_name       = 'nav',
  $nav_user_uid        = undef,
  $navcron_user_name   = 'navcron',
  $navcron_user_uid    = undef,
  $nav_user_group      = 'nav',
  $nav_user_gid        = undef,
  $nav_create_db       = true,
  $db_password         = undef,
  $debug               = false,
  $web_service         = 'httpd',
  $cronjobs = {
    activeip => { ensure => false, minute => '*/30', command => 'collect_active_ip.py'},
    logengine_regular => { ensure => false, command => 'logengine.py -q' },
    logengine_del => { ensure => false, minute => 3, hour => 3, command => 'logengine.py -d' },
    mactrace => { ensure => false, minute => [11,26,41,56], command => 'macwatch.py'},
    maintengine => { ensure => false, minute => '*/5', command => 'maintengine.py' },
    netbiostracker => { ensure => false, minute => '*/15', command => 'netbiostracker.py' },
    psuwatch => { ensure => false, minute => 5, command => 'powersupplywatch.py'},
    thresholdmon => { ensure => false, minute => '*/5' },
    topology => { ensure => false, minute => 35, command => 'navtopology --l2 --vlan' }
  }
) {

  class { nav::install: } ->
  class { nav::config: } ->
  class { nav::service: }

}
