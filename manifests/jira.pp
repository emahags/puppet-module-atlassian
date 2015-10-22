class atlassian::jira (
  $manage_package               = true,
  $package_name                 = 'jira',
  $package_ensure               = 'present',

  $manage_service               = true,
  $service_name                 = 'jira',
  $service_ensure               = 'running',
  $service_enable               = true,
  $service_provider             = 'init',

  $port                         = '8080',
  $user                         = 'jira',
  $group                        = 'jira',
  $jvm_min_memory               = '1024m',
  $jvm_max_memory               = '1024m',
  $jvm_support_recommended_args = '',

  $server_conf_path             = '/usr/share/atlassian/jira/conf/server.xml',
  $setenv_path                  = '/usr/share/atlassian/jira/bin/setenv.sh',

  $symlink_logs                 = true,
  $log_path                     = '/var/atlassian/application-data/jira/logs',
  $log_target                   = '/var/log/atlassian/jira',

  $manage_database              = true,
  $database_provider            = 'mysql',
  $database_name                = 'jira',
  $database_user                = 'jira',
  $database_password_hash       = undef,
  $database_server              = 'localhost',

  $manage_proxy                 = true,
  $proxy_provider               = 'apache',
  $alias                        = 'jira',
  $proxy_port                   = '80',
  $proxy_ssl                    = true,
  $proxy_ssl_port               = '443',
  $proxy_ssl_cert               = 'USE_DEFAULTS',
  $proxy_ssl_key                = 'USE_DEFAULTS',

  $maildirs                     = undef,
) {

  if $proxy_ssl_cert == 'USE_DEFAULTS' {
    $proxy_ssl_cert_real = "/etc/pki/tls/certs/${atlassian::jira::alias}.crt"
  } else {
    $proxy_ssl_cert_real = $proxy_ssl_cert
  }
  if $proxy_ssl_key == 'USE_DEFAULTS' {
    $proxy_ssl_key_real = "/etc/pki/tls/private/${atlassian::jira::alias}.key"
  } else {
    $proxy_ssl_key_real = $proxy_ssl_key
  }

  if $manage_package {
    package { 'jira':
      ensure => $package_ensure,
      name   => $package_name,
    }
  }

  if $manage_service {
    service { 'jira':
      ensure    => $service_ensure,
      name      => $service_name,
      enable    => $service_enable,
      provider  => $service_provider,
      subscribe => [ File['jira-server.xml'],
                     File['jira-setenv.sh'],],
    }
  }

  file { 'jira-server.xml':
    path    => $server_conf_path,
    ensure  => 'file',
    owner   => $user,
    group   => $group,
    mode    => '0644',
    content => template('atlassian/jira-server.xml.erb'),
  }

  file { 'jira-setenv.sh':
    path => $setenv_path,
    owner => $user,
    group => $group,
    mode => '0755',
    content => template('atlassian/jira-setenv.sh.erb'),
  }

  if $manage_package and $manage_service {
    Package['jira'] -> Service['jira']
  }

  if $symlink_logs {
    file { 'jira-log-source':
      ensure => 'link',
      path   => $log_path,
      target => $log_target,
    }
  }

  define jiramaildir {
    file { "/var/atlassian/application-data/jira/import/mail/${name}":
      ensure => directory,
      mode   => 0777,
    }
  }

  if $maildirs {
    file { "/var/atlassian/application-data/jira":
      ensure => 'directory',
      mode => '0755',
      owner => $owner,
      group => $group,
      require => Package['jira'],
    }
    file { "/var/atlassian/application-data/jira/import":
      ensure => 'directory',
      mode => '0755',
      owner => $owner,
      group => $group,
      require => File['/var/atlassian/application-data/jira'],
    }
    file { "/var/atlassian/application-data/jira/import/mail":
      ensure => 'directory',
      mode => '0755',
      owner => $owner,
      group => $group,
      require => File['/var/atlassian/application-data/jira/import'],
    }
    jiramaildir { $maildirs: }
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
