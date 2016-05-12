include_recipe 'fission::backend'

runit_service 'fission' do
  run_template_name 'fission-ruby'
  options(
    :user => node[:fission][:user],
    :group => node[:fission][:user],
    :script_path => '/usr/local/fission/bin/fission',
    :config_file => '/etc/fission/app'
  )
  env(
    {'FISSION_APPLICATION_NAME' => 'fission'}.merge(
      node[:fission][:service][:env]
    )
  )
  restart_on_update true
  default_logger true
  sv_timeout 60
  action [node[:fission][:service][:action]].flatten.compact.map(&:to_sym)
  if(File.exist?('/etc/service/fission'))
    subscribes :restart, 'file[/etc/fission/app/backend.json]'
    subscribes :restart, 'file[/etc/fission/sql.json]'
    subscribes :restart, 'execute[fission install]'
  end
end
