require_relative '../../puppet_x/puppetlabs/property/region.rb'

Puppet::Type.newtype(:es) do
  @doc = 'Type representing an Elasticsearch Service Domain.'

  ensurable

  newparam(:name_domain, namevar: true) do
    desc 'The name of the Elasticsearch domain that you are creating.'
    validate do |value|
      fail 'domain_name should be a String' unless value.is_a?(String)
      fail 'Elasticsearch Service must have a domain_name' if value == ''
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
  newproperty(:automated_snapshot_start_hour)
  newproperty(:subnet_ids)
  newproperty(:security_group_ids)
  newproperty(:advanced_options)

  newproperty(:access_policies) do
    desc 'The policy document JSON string'
    validate do |value|
      fail Puppet::Error, 'Policy documents must be JSON strings' unless value.is_a? String
      JSON.parse(value)
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

end
