require 'spec_helper'

type_class = Puppet::Type.type(:es)

describe type_class do

  let :params do
    [
      :name,
    ]
  end

  let :properties do
    [
      :region,
      :elasticsearch_version,
      :instance_type,
      :instance_count,
      :dedicated_master_enabled,
      :zone_awareness_enabled,
      :automated_snapshot_start_hour,
      :subnet_ids,
      :security_group_ids,
      :advanced_options,
      :access_policies,
    ]
  end

  it 'should have expected properties' do
    properties.each do |property|
      expect(type_class.properties.map(&:name)).to be_include(property)
    end
  end

  it 'should have expected parameters' do
    params.each do |param|
      expect(type_class.parameters).to be_include(param)
    end
  end

  it 'should require a name' do
    expect {
      type_class.new({})
    }.to raise_error(Puppet::Error, 'Title or name must be provided')
  end

  it 'region should not contain spaces' do
    expect {
      type_class.new(:name => 'sample', :region => 'sa east 1')
    }.to raise_error(Puppet::ResourceError, /region should be a valid AWS region/)
  end

  it 'IOPS must be an integer' do
    expect {
      type_class.new(:name => 'sample', :iops => 'Ten')
    }.to raise_error(Puppet::ResourceError, /IOPS must be an integer/)
  end

#  it 'should default skip_final_snapshot to false' do
#    srv = type_class.new(:name => 'sample')
#    expect(srv[:skip_final_snapshot]).to eq(:false)
#  end


# integer
    :instance_count,
# boolean
    :dedicated_master_enabled,
    :zone_awareness_enabled,
# list
    :subnet_ids,
    :security_group_ids,

  [
    :name,
    :region,
    :elasticsearch_version,
    :instance_type,
    :automated_snapshot_start_hour,
    :advanced_options,
    :access_policies,
  ].each do |property|
    it "should require #{property} to be a string" do
      expect(type_class).to require_string_for(property)
    end
  end

#  [
#    :endpoint,
#    :port,
#  ].each do |property|
#    it "should have a read-only property of #{property}" do
#      expect {
#        config = {:name => 'sample'}
#        config[property] = 'present'
#        type_class.new(config)
#      }.to raise_error(Puppet::Error, /#{property} is read-only/)
#    end
#  end


end
