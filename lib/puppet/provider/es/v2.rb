require_relative '../../../puppet_x/puppetlabs/aws.rb'

Puppet::Type.type(:es).provide(:v2, :parent => PuppetX::Puppetlabs::Aws) do
  confine feature: :aws
  confine feature: :retries
  mk_resource_methods

  def initialize(value={})
    super(value)
    @property_flush = {}
  end

  def self.instances
    regions.collect do |region|
      instances = []
      es_client(region).list_domain_names.each do |response|
        response.domain_names.each do |es_instance|
          instance = es_client(region).describe_elasticsearch_domain({
            domain_name: es_instance.domain_name,
          })
          unless instance.domain_status.deleted
            hash = es_to_hash(region, instance.domain_status)
            instances << new(hash) if has_name?(hash)
          end
        end
      end
      instances
    end.flatten
  end

  read_only(:domain_name)

  def self.prefetch(resources)
    instances.each do |prov|
      if resource = resources[prov.name] # rubocop:disable Lint/AssignmentInCondition
        resource.provider = prov if resource[:region] == prov.region
      end
    end
  end

  def self.es_to_hash(region, instance)

    if !instance.vpc_options.nil?
      vpc_id              = instance.vpc_options.vpc_id
      subnet_ids          = instance.vpc_options.subnet_ids
      availability_zones  = instance.vpc_options.availability_zones
      security_group_ids  = instance.vpc_options.security_group_ids
    else
      vpc_id              = nil
      subnet_ids          = nil
      availability_zones  = nil
      security_group_ids  = nil
    end

    config = {
      ensure: :present,
      name: instance.domain_name,
      region: region,
      domain_name: instance.domain_name,
      elasticsearch_version: instance.elasticsearch_version,
      elasticsearch_cluster_config: {
        instance_type: instance.elasticsearch_cluster_config.instance_type,
        instance_count: instance.elasticsearch_cluster_config.instance_count,
        dedicated_master_enabled: instance.elasticsearch_cluster_config.dedicated_master_enabled,
        zone_awareness_enabled: instance.elasticsearch_cluster_config.zone_awareness_enabled,
        dedicated_master_type: instance.elasticsearch_cluster_config.dedicated_master_type,
        dedicated_master_count: instance.elasticsearch_cluster_config.dedicated_master_count,
      },
      ebs_options: {
        ebs_enabled: instance.ebs_options.ebs_enabled,
        volume_type: instance.ebs_options.volume_type,
        volume_size: instance.ebs_options.volume_size,
        iops: instance.ebs_options.iops,
      },
      access_policies: instance.access_policies,
      snapshot_options: {
        automated_snapshot_start_hour: instance.snapshot_options.automated_snapshot_start_hour,
      },
      vpc_options: {
        vpc_id: vpc_id,
        subnet_ids: subnet_ids,
        availability_zones: availability_zones,
        security_group_ids: security_group_ids,
      },
      encryption_at_rest_options: {
        enabled: instance.encryption_at_rest_options.enabled,
        kms_key_id: instance.encryption_at_rest_options.kms_key_id,
      },
      advanced_options: instance.advanced_options,
      log_publishing_options: instance.log_publishing_options,
    }
    config
  end

  def config_with_vpc_options(config)
    if !resource[:subnet_ids].nil?
      config[:vpc_options] = {
        subnet_ids: resource[:subnet_ids],
        security_group_ids: resource[:security_group_ids],
      }
    end
    config
  end

  def config_with_dedicated_master(config)
    if resource[:dedicated_master_enabled] == true
      config[:dedicated_master] = {
        elasticsearch_cluster_config: {
          dedicated_master_type: resource[:dedicated_master_type],
          dedicated_master_count: resource[:dedicated_master_count],
        }
      }
    end
    config
  end

  def config_with_ebs_options(config)
    if resource[:ebs_enabled] == true
      config[:ebs_options] = {
        ebs_enabled: resource[:ebs_enabled],
        volume_type: resource[:volume_type],
        volume_size: resource[:volume_size],
      }
    end
    if !resource[:iops].nil?
      config[:ebs_options].first[:iops] = resource[:iops]
    end
    config
  end

  def config_with_encryption_at_rest_options(config)
    if !resource[:kms_key_id].nil?
      config[:encryption_at_rest_options] = {
        enabled: true,
        kms_key_id: resource[:kms_key_id],
      }
    else
      config[:encryption_at_rest_options] = {
        enabled: false,
      }
    end
    config
  end

  def exists?
    Puppet.debug("Checking if Elasticsearch Service Domain #{name} is present in region #{target_region}")
    @property_hash[:ensure] == :present
  end

  def es_service_role_if_missing
    service_role_name = 'AWSServiceRoleForAmazonElasticsearchService'

    begin
      Puppet.info("Checking if Elasticsearch Service-Linked role #{service_role_name} exists")
      resp = iam_client.get_role({
        role_name: service_role_name,
      })
    rescue Aws::IAM::Errors::ServiceError => e
      fail e unless e.message == 'Role not found for AWSServiceRoleForAmazonElasticsearchService'

      Puppet.info("Creating Elasticsearch Service-Linked role #{service_role_name}")
      resp = iam_client.create_service_linked_role({
        aws_service_name: 'es.amazonaws.com',
      })
    end
    resp.role.arn
  end

  def create
    Puppet.info("Creating new Elasticsearch Service Domain #{name} in region #{target_region}")

    resp = es_service_role_if_missing
    Puppet.debug("Using service-linked role arn #{resp}")

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
      advanced_options: resource[:advanced_options],
    }
    config = config_with_vpc_options(config)
    config = config_with_dedicated_master(config)
    config = config_with_ebs_options(config)
    config = config_with_encryption_at_rest_options(config)

    Puppet.debug(config)
    es_client(target_region).create_elasticsearch_domain(config)
    @property_hash[:ensure] = :present
  end

  def destroy
    Puppet.info("Deleting Domain #{name} in region #{resource[:region]}")
    es = es_client(resource[:region])
    response = es.delete_elasticsearch_domain({
      domain_name: name,
    })
    @property_hash[:ensure] = :absent
    response
  end

  def elasticsearch_version=(value)
    @property_flush[:elasticsearch_version] = value
  end

  def instance_type=(value)
    @property_flush[:instance_type] = value
  end

  def instance_count=(value)
    @property_flush[:instance_count] = value
  end

  def dedicated_master_enabled=(value)
    @property_flush[:dedicated_master_enabled] = value
  end

  def zone_awareness_enabled=(value)
    @property_flush[:zone_awareness_enabled] = value
  end

  def dedicated_master_type=(value)
    @property_flush[:dedicated_master_type] = value
  end

  def dedicated_master_count=(value)
    @property_flush[:dedicated_master_count] = value
  end

  def ebs_enabled=(value)
    @property_flush[:ebs_enabled] = value
  end

  def volume_type=(value)
    @property_flush[:volume_type] = value
  end

  def volume_size=(value)
    @property_flush[:volume_size] = value
  end

  def iops=(value)
    @property_flush[:iops] = value
  end

  def access_policies=(value)
    @property_flush[:access_policies] = value
  end

  def automated_snapshot_start_hour=(value)
    @property_flush[:automated_snapshot_start_hour] = value
  end

  def subnet_ids=(value)
    @property_flush[:subnet_ids] = value
  end

  def security_group_ids=(value)
    @property_flush[:security_group_ids] = value
  end

  def kms_key_id=(value)
    @property_flush[:kms_key_id] = value
  end

  def advanced_options=(value)
    @property_flush[:advanced_options] = value
  end

  def log_publishing_options=(value)
    @property_flush[:log_publishing_options] = value
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
