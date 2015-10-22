class atlassian::confluence (
  $manage_package               = true,
  $package_name                 = 'confluence',
  $package_ensure               = 'present',

  $manage_service               = true,
  $service_name                 = 'confluence',
  $service_ensure               = 'running',
  $service_enable               = true,
  $service_provider             = 'init',

  $port                         = '8090',
  $user                         = 'confluence',
  $group                        = 'confluence',
  $jvm_min_memory               = '1024m',
  $jvm_max_memory               = '1024m',
  $jvm_support_recommended_args = '',

  $server_conf_path             = '/usr/share/atlassian/confluence/conf/server.xml',
  $setenv_path                  = '/usr/share/atlassian/confluence/bin/setenv.sh',

  $symlink_logs                 = true,
  $log_path                     = '/var/atlassian/application-data/confluence/logs',
  $log_target                   = '/var/log/atlassian/confluence',

  $manage_database              = true,
  $database_provider            = 'mysql',
  $database_name                = 'confluence',
  $database_user                = 'confluence',
  $database_password_hash       = undef,
  $database_server              = 'localhost',

  $manage_proxy                 = true,
  $proxy_provider               = 'apache',
  $alias                        = 'confluence',
  $proxy_port                   = '80',
  $proxy_ssl                    = true,
  $proxy_ssl_port               = '443',
  $proxy_ssl_cert               = 'USE_DEFAULTS',
  $proxy_ssl_key                = 'USE_DEFAULTS',
) {

  if $proxy_ssl_cert == 'USE_DEFAULTS' {
    $proxy_ssl_cert_real = "/etc/pki/tls/certs/${atlassian::confluence::alias}.crt"
  } else {
    $proxy_ssl_cert_real = $proxy_ssl_cert
  }
  if $proxy_ssl_key == 'USE_DEFAULTS' {
    $proxy_ssl_key_real = "/etc/pki/tls/private/${atlassian::confluence::alias}.key"
  } else {
    $proxy_ssl_key_real = $proxy_ssl_key
  }

  if $manage_package {
    package { 'confluence':
      ensure => $package_ensure,
      name   => $package_name,
    }
  }

  if $manage_service {
    service { 'confluence':
      ensure    => $service_ensure,
      name      => $service_name,
      enable    => $service_enable,
      provider  => $service_provider,
      subscribe => [ File['confluence-server.xml'],
                     File['confluence-setenv.sh'],],
    }
  }

  file { 'confluence-server.xml':
    path    => $server_conf_path,
    ensure  => 'file',
    owner   => $user,
    group   => $group,
    mode    => '0644',
    content => template('atlassian/confluence-server.xml.erb'),
  }

  file { 'confluence-setenv.sh':
    path => $setenv_path,
    owner => $user,
    group => $group,
    mode => '0755',
    content => template('atlassian/confluence-setenv.sh.erb'),
  }

  if $manage_package and $manage_service {
    Package['confluence'] -> Service['confluence']
  }

  if $symlink_logs {
    file { 'confluence-log-source':
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
