class atlassian::mysql (
  $server_package_name = 'mysql-community-server',
  $client_package_name = 'mysql-community-client',
  $service_name        = 'mysqld',
  $config_file         = '/etc/my.cnf',
  $override_options    = {
    'mysqld' => {
      'character-set-server'     => 'utf8',
      'collation-server'         => 'utf8_bin',
      'default-storage-engine'   => 'INNODB',
      'max_allowed_packet'       => '256M',
      'innodb_log_file_size'     => '2G',
      'log-error'                => '/var/log/mysqld.log',
      'wait_timeout'             => '1000',
      'innodb_lock_wait_timeout' => '500',
      'pid-file'                 => '/var/run/mysqld/mysqld.pid',
    },
    'mysqld_safe' => {
      'log-error' => '/var/log/mysqld.log',
      'pid-file'  => '/var/run/mysqld/mysqld.pid',
    },
  }
) {
  class { '::mysql::server':
    package_name     => $server_package_name,
    service_name     => $service_name,
    config_file      => $config_file,
    override_options => $override_options
  }

  class { '::mysql::client':
    package_name => $client_package_name,
  }
}
