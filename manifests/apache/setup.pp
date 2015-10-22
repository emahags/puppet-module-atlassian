class atlassian::apache::setup {
  class { '::apache':
    default_vhost => false,
  }
}
