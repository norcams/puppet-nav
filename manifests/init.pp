class nav(
  $packages = 'nav-omnibus',
  $install_dir = '/usr/local/nav',
  $nav_user_name = 'navcron',
  $nav_user_uid = '512',
  $nav_user_group = 'nav',
  $nav_user_gid = '512',
  $nav_create_db = true,
  $graphite_dir = '/opt/graphite',
  $graphite_user_name = 'graphite',
  $graphite_user_uid = '513',
  $graphite_user_group = 'graphite',
  $graphite_user_gid = '513',
  $graphite_create_db = true,
  $db_password = undef,
  $debug = false,
  $web_service = 'httpd',
  $cronjobs = {
    activeip => { ensure => true, minute => '*/30', command => 'collect_active_ip.py'},
    logengine_regular => { ensure => true, command => 'logengine.py -q' },
    logengine_del => { ensure => true, minute => 3, hour => 3, command => 'logengine.py -d' },
    mactrace => { ensure => true, minute => [11,26,41,56], command => 'macwatch.py'},
    maintengine => { ensure => true, minute => '*/5', command => 'maintengine.py' },
    netbiostracker => { ensure => true, minute => '*/15', command => 'netbiostracker.py' }, 
    psuwatch => { ensure => true, minute => 5, command => 'powersupplywatch.py'},
    thresholdmon => { ensure => true, minute => '*/5' },
    topology => { ensure => true, minute => 35, command => 'navtopology --l2 --vlan' }
  }
) {

  class { nav::install: } ->
  class { nav::config: } ->
  class { nav::service: }

}
