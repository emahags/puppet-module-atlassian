define atlassian::apache(
  $server_alias,
  $port,
  $proxy_ssl      = false,
  $proxy_port     = 80,
  $proxy_ssl_port = 443,
  $proxy_ssl_cert = "/etc/pki/tls/certs/${server_alias}.crt",
  $proxy_ssl_key  = "/etc/pki/tls/private/${server_alias}.key",

) {
  include ::atlassian::apache::setup

  if $proxy_ssl {
    apache::vhost { "${server_alias}":
      servername    => "${server_alias}.${domain}",
      port          => $proxy_port,
      docroot       => '/var/www/html/',
      redirect_dest => "https://${server_alias}.${domain}:${proxy_ssl_port}/",
    }
    apache::vhost { "${server_alias}-ssl":
      servername          => "${server_alias}.${domain}",
      port                => $proxy_ssl_port,
      docroot             => '/var/www/html/',
      ssl                 => true,
      ssl_cert            => $proxy_ssl_cert,
      ssl_key             => $proxy_ssl_key,
      ssl_proxyengine     => true,
      proxy_preserve_host => true,
      proxy_pass          => [
        { 'path' => '/',
          'url' => "http://${server_alias}.${domain}:${port}/",
        },
      ],
    }
  } else {
    apache::vhost { "${server_alias}":
      servername => "${server_alias}.${domain}",
      port       => $proxy_port,
      docroot    => '/var/www/html/',
      proxy_pass => [
        { 'path' => '/',
          'url'  => "http://${server_alias}.${domain}:${port}/",
        },
      ],
    }
  }
}
