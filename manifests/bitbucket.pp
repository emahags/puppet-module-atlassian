class atlassian::bitbucket (
  $manage_package               = true,
  $package_name                 = 'bitbucket',
  $package_ensure               = 'present',

  $manage_service               = true,
  $service_name                 = 'bitbucket',
  $service_ensure               = 'running',
  $service_enable               = true,
  $service_provider             = 'init',

  $port                         = '7990',
  $user                         = 'bitbucket',
  $group                        = 'bitbucket',
  $jvm_min_memory               = '512m',
  $jvm_max_memory               = '768m',
  $jvm_support_recommended_args = '',

  $server_conf_path             = '/usr/share/atlassian/bitbucket/conf/server.xml',
  $setenv_path                  = '/usr/share/atlassian/bitbucket/bin/setenv.sh',

  $symlink_logs                 = true,
  $log_path                     = '/var/atlassian/application-data/bitbucket/logs',
  $log_target                   = '/var/log/atlassian/bitbucket',

  $manage_database              = true,
  $database_provider            = 'mysql',
  $database_name                = 'bitbucket',
  $database_user                = 'bitbucket',
  $database_password_hash       = undef,
  $database_server              = 'localhost',

  $manage_proxy                 = true,
  $proxy_provider               = 'apache',
  $alias                        = 'bitbucket',
  $proxy_port                   = '80',
  $proxy_ssl                    = true,
  $proxy_ssl_port               = '443',
  $proxy_ssl_cert               = 'USE_DEFAULTS',
  $proxy_ssl_key                = 'USE_DEFAULTS',
) {

  if $proxy_ssl_cert == 'USE_DEFAULTS' {
    $proxy_ssl_cert_real = "/etc/pki/tls/certs/${atlassian::bitbucket::alias}.crt"
  } else {
    $proxy_ssl_cert_real = $proxy_ssl_cert
  }
  if $proxy_ssl_key == 'USE_DEFAULTS' {
    $proxy_ssl_key_real = "/etc/pki/tls/private/${atlassian::bitbucket::alias}.key"
  } else {
    $proxy_ssl_key_real = $proxy_ssl_key
  }

  if $manage_package {
    package { 'bitbucket':
      ensure => $package_ensure,
      name   => $package_name,
    }
  }

  if $manage_service {
    service { 'bitbucket':
      ensure    => $service_ensure,
      name      => $service_name,
      enable    => $service_enable,
      provider  => $service_provider,
      subscribe => [ File['bitbucket-server.xml'],
                     File['bitbucket-setenv.sh'],],
    }
  }

  file { 'bitbucket-server.xml':
    path    => $server_conf_path,
    ensure  => 'file',
    owner   => $user,
    group   => $group,
    mode    => '0644',
    content => template('atlassian/bitbucket-server.xml.erb'),
    require => Package['bitbucket'],
  }

  file { 'bitbucket-setenv.sh':
    path => $setenv_path,
    owner => $user,
    group => $group,
    mode => '0755',
    content => template('atlassian/bitbucket-setenv.sh.erb'),
    require => Package['bitbucket'],
  }

  if $manage_package and $manage_service {
    Package['bitbucket'] -> Service['bitbucket']
  }

  if $symlink_logs {
    file { 'bitbucket-log-source':
      ensure => 'link',
      path   => $log_path,
      target => $log_target,
      require => Package['bitbucket'],
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
