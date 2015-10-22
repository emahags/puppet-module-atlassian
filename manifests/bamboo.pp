class atlassian::bamboo (
  $manage_package               = true,
  $package_name                 = 'bamboo',
  $package_ensure               = 'present',

  $manage_service               = true,
  $service_name                 = 'bamboo',
  $service_ensure               = 'running',
  $service_enable               = true,
  $service_provider             = 'init',

  $port                         = '8085',
  $user                         = 'bamboo',
  $group                        = 'bamboo',
  $jvm_min_memory               = '256m',
  $jvm_max_memory               = '384m',
  $jvm_support_recommended_args = '',

  $server_conf_path             = '/usr/share/atlassian/bamboo/conf/server.xml',
  $setenv_path                  = '/usr/share/atlassian/bamboo/bin/setenv.sh',

  $symlink_logs                 = true,
  $log_path                     = '/var/atlassian/application-data/bamboo/logs',
  $log_target                   = '/var/log/atlassian/bamboo',

  $manage_database              = true,
  $database_provider            = 'mysql',
  $database_name                = 'bamboo',
  $database_user                = 'bamboo',
  $database_password_hash       = undef,
  $database_server              = 'localhost',

  $manage_proxy                 = true,
  $proxy_provider               = 'apache',
  $alias                        = 'bamboo',
  $proxy_port                   = '80',
  $proxy_ssl                    = true,
  $proxy_ssl_port               = '443',
  $proxy_ssl_cert               = 'USE_DEFAULTS',
  $proxy_ssl_key                = 'USE_DEFAULTS',
) {

  if $proxy_ssl_cert == 'USE_DEFAULTS' {
    $proxy_ssl_cert_real = "/etc/pki/tls/certs/${atlassian::bamboo::alias}.crt"
  } else {
    $proxy_ssl_cert_real = $proxy_ssl_cert
  }
  if $proxy_ssl_key == 'USE_DEFAULTS' {
    $proxy_ssl_key_real = "/etc/pki/tls/private/${atlassian::bamboo::alias}.key"
  } else {
    $proxy_ssl_key_real = $proxy_ssl_key
  }

  if $manage_package {
    package { 'bamboo':
      ensure => $package_ensure,
      name   => $package_name,
    }
  }

  if $manage_service {
    service { 'bamboo':
      ensure    => $service_ensure,
      name      => $service_name,
      enable    => $service_enable,
      provider  => $service_provider,
      subscribe => [ File['bamboo-server.xml'],
                     File['bamboo-setenv.sh'],],
    }
  }

  file { 'bamboo-server.xml':
    path    => $server_conf_path,
    ensure  => 'file',
    owner   => $user,
    group   => $group,
    mode    => '0644',
    content => template('atlassian/bamboo-server.xml.erb'),
  }

  file { '/etc/init.d/bamboo':
    ensure => 'file',
    mode => '0755',
    content => template('atlassian/bamboo.init.erb'),
  }

  file { 'bamboo-setenv.sh':
    path => $setenv_path,
    owner => $user,
    group => $group,
    mode => '0755',
    content => template('atlassian/bamboo-setenv.sh.erb'),
  }

  if $manage_package and $manage_service {
    Package['bamboo'] -> Service['bamboo']
  }

  if $symlink_logs {
    file { 'bamboo-log-source':
      ensure => 'link',
      path   => $log_path,
      target => $log_target,
    }
  }

  if $manage_database {
    if $database_provider == 'mysql' {
      atlassian::mysql { $database_name:
        user           => $database_user,
        password       => $database_password_hash,
        server         => $database_server,
      }
    } else {
      fail("${database_provider} is not a valid database provider.")
    }
  }

  if $manage_proxy {
    if $proxy_provider == 'apache' {
      atlassian::apache { $alias:
        server_alias   => $alias,
        port           => $port,
        proxy_ssl      => $proxy_ssl,
        proxy_port     => $proxy_port,
        proxy_ssl_port => $proxy_ssl_port,
        proxy_ssl_cert => $proxy_ssl_cert_real,
        proxy_ssl_key  => $proxy_ssl_key_real,
      }
    } else {
      fail("${proxy_provider} is not a valid proxy provider.")
    }
  }
}
