node.set[:java][:jdk_version] = node[:fission][:java_version]

if platform_family?("debian")
  node.default[:java][:java_home] = "/usr/lib/jvm/default-java"
  node.default[:java][:openjdk_packages] = [
    "openjdk-#{node[:java][:jdk_version]}-jdk",
    "openjdk-#{node[:java][:jdk_version]}-jre-headless"
  ]
end

if(platform_family?('debian'))
  include_recipe 'apt'
end

include_recipe 'java'

ruby_block 'encrypted databag(write secret)' do
  block do
    %w(/etc/chef/validation.pem /etc/chef/fission-validator.pem /tmp/encrypted_data_bag_secret).each do |path|
      if(File.exists?(path))
        FileUtils.cp(path, '/etc/chef/encrypted_data_bag_secret')
        Chef::Log.info "Encrypted data bag secret imported from: #{path}"
      end
    end
  end
  action :nothing
  not_if do
    File.exists?('/etc/chef/encrypted_data_bag_secret')
  end
end.run_action(:create)
