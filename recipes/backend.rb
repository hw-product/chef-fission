include_recipe 'runit'
include_recipe 'fission::lxd'

user node[:fission][:user] do
  system true
  home node[:fission][:home]
end

directory node[:fission][:home] do
  recursive true
  owner node[:fission][:user]
end

directory '/etc/fission' do
  mode 0755
end

file '/etc/fission/backend.json' do
  content Chef::JSONCompat.to_json_pretty(
    Chef::Mixin::DeepMerge.merge(
      node[:fission][:default_config].fetch(:service, {}),
      node[:fission][:service][:config]
    )
  ).gsub('$NODE_NAME$', node.name)
  mode 0644
  notifies :restart, 'runit_service[fission]' if File.exists?('/etc/init.d/fission')
end

file '/etc/fission/sql.json' do
  content Chef::JSONCompat.to_json_pretty(
    :database => node[:fission][:data][:name],
    :host => node[:fission][:data].fetch(:host, '127.0.0.1'),
    :user => node[:fission][:data][:username],
    :password => node[:fission][:data][:password]
  )
  mode 0600
  owner node[:fission][:user]
end

remote_file File.join(Chef::Config[:file_cache_path], 'fission-backend.deb') do
  source node[:fission][:service][:asset_url]
  mode 0644
  notifies :install, 'dpkg_package[fission]', :immediately
end

dpkg_package 'fission' do
  source File.join(Chef::Config[:file_cache_path], 'fission-backend.deb')
  action :nothing
  notifies :restart, 'runit_service[fission]' if File.exists?('/etc/init.d/fission')
end

runit_service 'fission' do
  run_template_name 'fission-ruby'
  options(
    :user => node[:fission][:user],
    :group => node[:fission][:user],
    :script_path => '/usr/local/fission/bin/fission',
    :config_file => '/etc/fission'
  )
  env(
    {'FISSION_APPLICATION_NAME' => 'fission'}.merge(
      node[:fission][:service][:env]
    )
  )
  restart_on_update true
  default_logger true
  sv_timeout 20
end
