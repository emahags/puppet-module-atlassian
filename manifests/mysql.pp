define atlassian::mysql (
  $user,
  $password,
  $server              = 'localhost',
) {
  include ::atlassian::mysql::setup

  mysql::db { $name:
    user           => $user,
    password       => $password,
    host           => $server,
    grant          => 'ALL',
    charset        => 'utf8',
    collate        => 'utf8_bin',
  }
}
