elasticsearch_service { 'test-public':
  ensure                          => present,
  region                          => 'us-east-1',
  elasticsearch_version           => '6.0',
  instance_type                   => 't2.small.elasticsearch',
  ebs_enabled                     => true,
  volume_type                     => 'standard',
  volume_size                     => 10,
  instance_count                  => 1,
  dedicated_master_enabled        => false,
  zone_awareness_enabled          => false,
  automated_snapshot_start_hour   => 3,
  advanced_options                => {
    'rest.action.multi.allow_explicit_index' => 'false',
  },
}

# elasticsearch_service { 'test-vpc':
#   ensure                          => present,
#   region                          => 'us-east-1',
#   elasticsearch_version           => '6.0',
#   instance_type                   => 't2.small.elasticsearch',
#   ebs_enabled                     => true,
#   volume_type                     => 'standard',
#   volume_size                     => 10,
#   instance_count                  => 1,
#   dedicated_master_enabled        => false,
#   zone_awareness_enabled          => false,
#   automated_snapshot_start_hour   => 3,
#   subnet_ids                      => [<YOUR_SUBNET_LIST_HERE>],
#   security_group_ids              => [<YOUR_SECURITY_GROUP_LIST_HERE>],
#   advanced_options                => {
#     'rest.action.multi.allow_explicit_index' => 'false',
#   },
#   access_policies                 => '<YOUR_ACCESS_POLICY_JSON_HERE>',
# }
