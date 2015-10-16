class atlassian::apache {
  class { '::apache':
    default_vhost => false,
  }
}
