include_recipe 'runit'
include_recipe 'fission::java'

chef_gem 'xml-simple'
require 'xmlsimple'

user node[:fission][:user] do
  system true
  home node[:fission][:home]
end

directory node[:fission][:home] do
  recursive true
  owner node[:fission][:user]
end

directory '/etc/fission-web' do
  mode 0755
end

file '/etc/fission-web/app.json' do
  content Chef::JSONCompat.to_json_pretty(
    Chef::Mixin::DeepMerge.merge(
      node[:fission][:default_config].fetch(:web, {}),
      node[:fission][:web][:config]
    )
  )
  mode 0644
end

file '/etc/fission-web/log.xml' do
  content(
    XmlSimple.xml_out(
      node[:fission][:web][:log_config],
      'AttrPrefix' => true,
      'KeepRoot' => true
    )
  )
  mode 0644
end

remote_file '/opt/fission-web.war' do
  source node[:fission][:web][:asset]
  mode 0644
end

runit_service 'fission-web' do
  run_template_name 'fission-web'
  control ['d', 't', 'x']
  control_template_names(
    'd' => 'fission-web',
    't' => 'fission-web',
    'x' => 'fission-web'
  )
  options(
    :user => node[:fission][:user],
    :group => node[:fission].fetch(:group, node[:fission][:user]),
    :java_path => node[:fission][:java_path],
    :java_options => node[:fission][:web][:java_options],
    :jar_path => '/opt/fission-web.war',
    :log_config_file => '/etc/fission-web/log.xml',
    :logger_config_name => 'configurationFile',
    :config_file => '/etc/fission-web/app.json'
  )
  restart_on_update false
  default_logger true
  subscribes :restart, 'file[/etc/fission-web/app.json]' if File.exists?('/etc/fission-web/app.json')
  subscribes :restart, 'remote_file[/opt/fission-web.war]' if File.exists?('/opt/fission-web.war')
end
