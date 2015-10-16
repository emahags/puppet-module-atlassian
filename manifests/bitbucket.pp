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
  $proxy_ssl_cert               = "/etc/pki/tls/certs/${alias}.crt",
  $proxy_ssl_key                = "/etc/pki/tls/private/${alias}.key",
  $proxy_ssl_port               = '443',
) {

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
      subscribe => [ File['server.xml'],
                     File['setenv.sh'],],
    }
  }

  file { 'server.xml':
    path    => $server_conf_path,
    ensure  => 'file',
    owner   => $user,
    group   => $group,
    mode    => '0644',
    content => template('atlassian/bitbucket-server.xml.erb'),
  }

  file { 'setenv.sh':
    path => $setenv_path,
    owner => $user,
    group => $group,
    mode => '0755',
    content => template('atlassian/bitbucket-setenv.sh.erb'),
  }

  if $manage_package and $manage_service {
    Package['bitbucket'] -> Service['bitbucket']
  }

  if $symlink_logs {
    file { 'bitbucket-log-source':
      ensure => 'link',
      path   => $log_path,
      target => $log_target,
    }
  }

  if $manage_database {
    if $database_provider == 'mysql' {
      if $database_password_hash {
        include atlassian::mysql
        mysql::db { $database_name:
          user             => $database_user,
          password         => $database_password_hash,
          password_is_hash => true,
          host             => $database_server,
          grant            => 'ALL',
          charset          => 'utf8',
          collate          => 'utf8_bin',
        }
      } else {
        fail("You must set a password hash")
      }
    } else {
      fail("${database_provider} is not a valid database provider.")
    }
  }

  if $manage_proxy {
    if $proxy_provider == 'apache' {
      include atlassian::apache
      if $proxy_ssl {
        apache::vhost { "${alias}":
          servername    => "${alias}.${domain}",
          port          => $proxy_port,
          docroot       => '/var/www/html/',
          redirect_dest => "https://${alias}.${domain}:${proxy_ssl_port}/",
        }
        apache::vhost { "${alias}-ssl":
          servername          => "${alias}.${domain}",
          port                => $proxy_ssl_port,
          docroot             => '/var/www/html/',
          ssl                 => true,
          ssl_cert            => $proxy_ssl_cert,
          ssl_key             => $proxy_ssl_key,
          ssl_proxyengine     => true,
          proxy_preserve_host => true,
          proxy_pass          => [
            { 'path' => '/',
              'url' => "http://${alias}.${domain}:${port}/",
            },
          ],
        }
      } else {
        apache::vhost { "${alias}":
          servername => "${alias}.${domain}",
          port       => $proxy_port,
          docroot    => '/var/www/html/',
          proxy_pass => [
            { 'path' => '/',
              'url'  => "http://${alias}.${domain}:${port}/",
            },
          ],
        }
      }
    } else {
      fail("${proxy_provider} is not a valid proxy provider.")
    }
  }
}
