class atlassian::apache::setup {
  class { '::apache':
    default_vhost => false,
  }
  class {'::apache::mod::proxy_wstunnel':}
}
