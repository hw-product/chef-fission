# Install fission gems from private gemstore

include_recipe 'build-essential'

['libxslt1-dev', 'libxml2-dev', 'zlib1g-dev'].each do |pkg|
  package pkg
end

gemstore = discovery_search(
  'gemstore',
  :environment_aware => true,
  :empty_ok => false
)

node.default[:fission][:private_gem_store] = "https://#{gemstore[:geminabox][:auth_required].to_a.first.join(':')}@#{gemstore.ipaddress}"

begin
  require 'rubygems/remote_fetcher'
  require 'rubygems/name_tuple'

  list = Gem::Source.new(node[:fission][:private_gem_store]).load_specs(:released).find_all do |spec|
    spec.name.start_with?('fission')
  end.map(&:name).uniq

rescue LoadError

  list = Gem::SpecFetcher.new.load_specs(
    URI.parse(node[:fission][:private_gem_store]), :specs
  ).find_all do |spec|
    spec.first.start_with?('fission')
  end.map(&:first).uniq

end

list.each do |gem_name|

  gem_package gem_name do
    action :install
    source node[:fission][:private_gem_store]
    if(node[:fission][:gems][gem_name])
      version node[:fission][:gems][gem_name]
    end
  end

end
