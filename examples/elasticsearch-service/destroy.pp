elasticsearch_service { 'test-public':
  ensure => absent,
  region => 'us-east-1',
}

# elasticsearch_service { 'test-vpc':
#   ensure => absent,
#   region => 'us-east-1',
# }
