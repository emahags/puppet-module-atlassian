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
  $proxy_ssl_cert               = "/etc/pki/tls/certs/${alias}.crt",
  $proxy_ssl_key                = "/etc/pki/tls/private/${alias}.key",
  $proxy_ssl_port               = '443',
) {

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
      if $database_password_hash {
        include atlassian::mysql
        mysql::db { $database_name:
          user             => $database_user,
          password         => $database_password_hash,
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
