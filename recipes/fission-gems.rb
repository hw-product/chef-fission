# Install fission gems from private gemstore

require 'rubygems/remote_fetcher'
require 'rubygems/name_tuple'

gemstore = discovery(
  'gemstore',
  :environment_aware => true,
  :empty_ok => false
)

node.default[:fission][:private_gem_store] = "https://#{gemstore[:geminabox][:auth_required].to_a.first.join(':')}@#{gemstore.ipaddress}"

Gem::Source.new(node[:fission][:private_gem_store]).load_specs(:released).find_all do |spec|
  spec.name.start_with?('fission')
end.map(&:name).uniq.each do |gem_name|

  gem_package gem_name do
    action :install
    source node[:fission][:private_gem_store]
    if(node[:fission][:gems][gem_name])
      version node[:fission][:gems][gem_name]
    end
  end

end
