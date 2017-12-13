require_relative '../../../puppet_x/puppetlabs/aws.rb'

Puppet::Type.type(:es).provide(:v2, :parent => PuppetX::Puppetlabs::Aws) do
  confine feature: :aws
  mk_resource_methods

  def initialize(value={})
    super(value)
    @property_flush = {}
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if resource = resources[prov.name] # rubocop:disable Lint/AssignmentInCondition
        resource.provider = prov if resource[:region] == prov.region
      end
    end
  end

# TODO: config_with_dedicated_master
#      elasticsearch_cluster_config: {
#        dedicated_master_type: "m3.medium.elasticsearch",
#        dedicated_master_count: 1,

# TODO: config_with_ebs_options
#      ebs_options: {
#        ebs_enabled: false,
#        volume_type: "standard",
#        volume_size: 1,
#        iops: 1,
#      },

# TODO: config_with_encryption_at_rest_options
#      encryption_at_rest_options: {
#        enabled: false,
#        kms_key_id: "KmsKeyId",
#      },



  def create
    Puppet.info("Creating new Elasticsearch Service Domain #{domain_name} in region #{target_region}")
    es = es_client(target_region)

    config = {
      domain_name: resource[:domain_name],
      elasticsearch_version: resource[:elasticsearch_version],
      elasticsearch_cluster_config: {
        instance_type: resource[:instance_type],
        instance_count: resource[:instance_count],
        dedicated_master_enabled: resource[:dedicated_master_enabled],
        zone_awareness_enabled: resource[:zone_awareness_enabled],
      },
      access_policies: resource[:access_policies],
      snapshot_options: {
        automated_snapshot_start_hour: resource[:automated_snapshot_start_hour],
      },
      vpc_options: {
        subnet_ids: resource[:subnet_ids],
        security_group_ids: resource[:security_group_ids],
      },
      advanced_options: resource[:advanced_options]
    }

    es.create_elasticsearch_domain(config)
    @property_hash[:ensure] = :present
  end

  def exists?
    Puppet.debug("Checking if Elasticsearch Service Domain #{domain_name} is present in region #{target_region}")
    @property_hash[:ensure] == :present
  end



end
