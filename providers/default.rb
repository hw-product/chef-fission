use_inline_resources(true) if self.respond_to?(:use_inline_resources)

def load_current_resource
  # Default resource attributes to node attributes
  {
    :install_directory => node[:fission][:directories][:install],
    :config_directory => node[:fission][:directories][:config],
    :user => node[:fission][:user],
    :group => node[:fission][:group],
    :package_url => node[:fission][:pkg_url],
    :java_options => node[:fission][:java_options]
  }.each do |resource_method, default_value|
    unless(new_resource.send(resource_method))
      new_resource.send(resource_method, default_value)
    end
  end
end

action :install do
  run_context.include_recipe 'fission::setup'

  jar_path = File.join(
    new_resource.install_directory,
    File.basename(new_resource.package_url)
  )
  current_jar_path = ::File.join(
    new_resource.install_directory,
    new_resource.name
  )
  config_file = ::File.join(
    new_resource.config_directory,
    "#{new_resource.name}.json"
  )

  user new_resource.user do
    system true
  end

  group new_resource.group do
    users [new_resource.user]
  end

  directory new_resource.install_directory do
    recursive true
  end

  directory new_resource.config_directory do
    recursive true
  end

  remote_file jar_path do
    source new_resource.package_url
    mode 0644
  end

  link jar_path do
    to current_jar_path
  end

  file config_file do
    content Chef::JSONCompat.to_json(new_resource.config)
    mode 0644
  end

  if(platform_family?('mac_os_x'))

    plist = "/Library/LaunchDaemons/com.hw-ops.#{new_resource.name}.plist"
    log_file = "/Library/Logs/Fission/#{new_resource.name}-daemon.log"

    directory ::File.dirname(log_file) do
      owner new_resource.user
      group new_resource.group
      recursive true
    end

    template plist do
      source "com.hw-ops.fission.plist.erb"
      mode 0644
      variables(
        :app_name => new_resource.name,
        :user => new_resource.user,
        :group => new_resource.group,
        :java_path => node[:fission][:java_path],
        :java_options => new_resource.java_options,
        :jar_path => current_jar_path,
        :log_file => log_file
      )
    end

    service new_resource.name do
      service_name "com.hw-ops.fission"
      action :start
      subscribes :restart, "remote_file[#{jar_path}]"
      subscribes :restart, "file[#{config_file}]"
      subscribes :restart, "template[#{plist}]"
    end

  else
    run_context.include_recipe 'runit'

    runit_service new_resource.name do
      run_template_name 'fission'
      options(
        :user => new_resource.user,
        :group => new_resource.group,
        :java_path => node[:fission][:java_path],
        :java_options => new_resource.java_options,
        :jar_path => current_jar_path,
        :config_file => config_file
      )
      default_logger true
      subscribes :restart, "remote_file[#{jar_path}]"
      subscribes :restart, "file[#{config_file}]"
    end
  end
end

action :uninstall do

  jar_path = File.join(
    new_resource.install_directory,
    File.basename(new_resource.package_url)
  )
  current_jar_path = ::File.join(
    new_resource.install_directory,
    new_resource.name
  )
  config_file = ::File.join(
    new_resource.config_directory,
    "#{new_resource.name}.json"
  )

  [jar_path, current_jar_path, config_file].each do |file_path|
    file file_path do
      action :delete
    end
  end
end