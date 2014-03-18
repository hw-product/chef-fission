node.set[:vagabond][:disable_default_zero] = true

include_recipe 'vagabond'

begin
  lxc_precise = node.run_context.resource_collection.lookup('lxc[ubuntu_1204]')
  lxc_precise.initialize_commands << '/opt/chef/embedded/bin/gem install attribute_struct --no-rdoc --no-ri'
  lxc_precise.initialize_commands << 'apt-get install lxc --no-install-recommends'
rescue => e
  Chef::Log.warn "Failed to customize Packager lxc install: #{e.class}: #{e}"
end
