require_relative '../../../puppet_x/puppetlabs/aws.rb'

Puppet::Type.type(:es).provide(:v2, :parent => PuppetX::Puppetlabs::Aws) do
  confine feature: :aws
  mk_resource_methods

  def self.prefetch(resources)
    instances.each do |prov|
      if resource = resources[prov.name] # rubocop:disable Lint/AssignmentInCondition
        resource.provider = prov if resource[:region] == prov.region
      end
    end
  end


  def exists?
    Puppet.debug("Checking if Elasticsearch Service Domain #{domain_name} is present in region #{target_region}")
    @property_hash[:ensure] == :present
  end



end
