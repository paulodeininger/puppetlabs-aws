elasticsearch_service { 'test-public':
  ensure                          => present,
  region                          => 'us-east-1',
  elasticsearch_version           => '6.0',
  instance_type                   => 't2.small.elasticsearch',
  ebs_enabled                     => true,
  volume_type                     => 'standard',
  volume_size                     => 11,
  instance_count                  => 1,
  dedicated_master_enabled        => false,
  zone_awareness_enabled          => false,
  automated_snapshot_start_hour   => 4,
  advanced_options                => {
    'rest.action.multi.allow_explicit_index' => 'true',
  },
}
