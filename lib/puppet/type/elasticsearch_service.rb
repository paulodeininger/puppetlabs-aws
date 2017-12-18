require_relative '../../puppet_x/puppetlabs/property/region.rb'

Puppet::Type.newtype(:elasticsearch_service) do
  @doc = 'Type representing an Elasticsearch Service Domain.'

  ensurable

  newparam(:name, namevar: true) do
    desc 'The name of the Elasticsearch domain that you are creating.'
    validate do |value|
      fail 'name should be a String' unless value.is_a?(String)
      fail 'Elasticsearch Service must have a name for domain_name' if value == ''
    end
  end

  newproperty(:region, :parent => PuppetX::Property::AwsRegion) do
    desc 'The region in which to launch the instance.'
  end

  newproperty(:elasticsearch_version)
  newproperty(:instance_type)
  newproperty(:instance_count)
  newproperty(:dedicated_master_enabled)
  newproperty(:zone_awareness_enabled)
  newproperty(:dedicated_master_type)
  newproperty(:dedicated_master_count)
  newproperty(:ebs_enabled)
  newproperty(:volume_type)
  newproperty(:volume_size)
  newproperty(:iops)

  newproperty(:access_policies) do
    desc 'The policy document JSON string'
    validate do |value|
      unless value.to_s.empty?
        JSON.parse(value)
      end
    end
    munge do |value|
      begin
        data = JSON.parse(value)
        JSON.pretty_generate(data)
      rescue
        fail('Document string is not valid JSON')
      end
    end

    def insync?(is)
      one = JSON.parse(is)
      two = JSON.parse(should)
      provider.class.normalize_hash(one) == provider.class.normalize_hash(two)
    end
  end

  newproperty(:automated_snapshot_start_hour)
  newproperty(:subnet_ids)

  newproperty(:security_group_ids, :array_matching => :all) do
    desc 'An array of security group names (or IDs) within the VPC to assign to the instance.'
    munge do |value|
      provider.vpc_security_group_munge(value)
    end
  end

  newproperty(:kms_key_id)
  newproperty(:advanced_options)
  newproperty(:log_publishing_options)

end