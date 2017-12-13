require_relative '../../../puppet_x/puppetlabs/aws.rb'

Puppet::Type.type(:es).provide(:v2, :parent => PuppetX::Puppetlabs::Aws) do
  confine feature: :aws
  mk_resource_methods

  def initialize(value={})
    Puppet.debug("es initialize")
    super(value)
    @property_flush = {}
  end

  def self.instances
    regions.collect do |region|
      instances = []
      instance = es_client(region)
      instance.list_domain_names.domain_names.each do |domain_name|
        hash = es_to_hash(region, domain_name)
        instances << new(hash) if has_name?(hash)
      end
      instances
    end.flatten
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if resource = resources[prov.name] # rubocop:disable Lint/AssignmentInCondition
        resource.provider = prov if resource[:region] == prov.region
      end
    end
  end

  def self.es_to_hash(region, name)
    config = {
      domain_name: name,
      region: region,
      ensure: :present,
    }
    config
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

  def exists?
    Puppet.debug("Checking if Elasticsearch Service Domain #{name} is present in region #{target_region}")
    @property_hash[:ensure] == :present
  end

  def create
    Puppet.info("Creating new Elasticsearch Service Domain #{name} in region #{target_region}")
    es = es_client(target_region)

    config = {
      domain_name: name,
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
      advanced_options: resource[:advanced_options],
    }

    es.create_elasticsearch_domain(config)
    @property_hash[:ensure] = :present
  end

  def destroy
    Puppet.info("Deleting Domain #{name} in region #{resource[:region]}")
    es = es_client(target_region)
    response = es.delete_elasticsearch_domain({
      domain_name: name,
    })

    @property_hash[:ensure] = :absent
    if response.error
      fail("Failed to delete Elasticsearch Domain: #{response.error}") if response.error
    end
    response.error
  end

  def flush
    if @property_hash[:ensure] != :absent and not @property_flush.nil?
      Puppet.debug("Flushing Elasticsearch Service for #{@property_hash[:name]}")

      if @property_flush.keys.size > 0
        domain_config_update = {
          domain_name: @property_hash[:name]
        }

        @property_flush.each {|k,v|
          domain_config_update[k] = v
        }

        es_client(@property_hash[:region]).update_elasticsearch_domain_config(domain_config_update)
      end
    end

  end

end
