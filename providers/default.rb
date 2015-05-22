require 'uri'

use_inline_resources if self.respond_to?(:use_inline_resources)

def load_current_resource
  # Default resource attributes to node attributes
  {
    :install_directory => node[:fission][:directories][:install],
    :config_directory => node[:fission][:directories][:config],
    :user => node[:fission][:user],
    :group => node[:fission][:group],
#    :package_url => node[:fission][:pkg_url],
    :java_options => node[:fission][:java_options]
  }.each do |resource_method, default_value|
    unless(new_resource.send(resource_method))
      new_resource.send(resource_method, default_value)
    end
  end
end

action :install do
  run_context.include_recipe 'fission::setup'
  run_context.include_recipe 'fission::java'

  new_resource.config_directory ::File.join(
    new_resource.config_directory,
    new_resource.name
  )

  if(new_resource.package_url)
    jar_path = ::File.join(
      new_resource.install_directory,
      ::File.basename(
        URI.parse(new_resource.package_url).path
      )
    )
  else
    jar_path = ::File.join(
      new_resource.install_directory,
      'fission/fission.jar'
    )
  end

  current_jar_path = ::File.join(
    new_resource.install_directory,
    new_resource.name
  )
  config_file = ::File.join(
    new_resource.config_directory,
    "#{new_resource.name}.json"
  )

  fission_user new_resource.user

  group new_resource.group do
    users [new_resource.user]
  end

  sudo_args = {
    :name => new_resource.name,
    :user => new_resource.user,
    :enabled => new_resource.sudo
  }

  sudo sudo_args[:name] do
    user sudo_args[:user]
    nopasswd true
    only_if{ sudo_args[:enabled] }
  end

  directory new_resource.install_directory do
    recursive true
  end

  directory new_resource.config_directory do
    recursive true
  end

  if(new_resource.package_url)

    remote_file jar_path do
      source new_resource.package_url
      mode 0644
      notifies :restart, "runit_service[#{new_resource.name}]"
    end

  else
    cache_path = ::File.join(Chef::Config[:file_cache_path], "#{new_resource.name}.syspkg")

    dpkg_package 'fission' do
      source cache_path
      action :nothing
      notifies :restart, "runit_service[#{new_resource.name}]"
    end

    remote_file cache_path do
      source new_resource.system_package_url
      headers 'Accept' => 'application/octet-stream'
      mode 0644
      notifies :install, "dpkg_package[fission]", :immediately
    end

  end

  link current_jar_path do
    to jar_path
  end

  file config_file do
    content Chef::JSONCompat.to_json_pretty(
      Chef::Mixin::DeepMerge.merge(
        Mash.new(Chef::JSONCompat.from_json(Chef::JSONCompat.to_json(node[:fission][:default_config].fetch(:instance, Mash.new)))),
        Mash.new(Chef::JSONCompat.from_json(Chef::JSONCompat.to_json(new_resource.configuration)))
      )
    ).gsub('$NODE_NAME$', node.name)
    mode 0644
  end

  if(platform_family?('mac_os_x'))

    fission_service = "com.hw-ops.#{new_resource.name}"
    plist = ::File.join('/Library/LaunchDaemons', "#{fission_service}.plist")
    log_file = ::File.join('/Library/Logs', new_resource.name, 'daemon.log')

    directory ::File.dirname(log_file) do
      recursive true
    end

    template plist do
      source "com.hw-ops.fission.plist.erb"
      mode 0644
      variables(
        :service_name => fission_service,
        :user => new_resource.user,
        :group => new_resource.group,
        :timeout => new_resource.service_timeout || node[:fission][:service_timeout],
        :java_path => node[:fission][:java_path],
        :java_options => new_resource.java_options,
        :jar_path => current_jar_path,
        :log_file => log_file
      )
    end

    service new_resource.name do
      service_name fission_service
      action :start
      subscribes :restart, "link[#{current_jar_path}]"
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
        :config_file => ::File.dirname(config_file)
      )
      restart_on_update false
      default_logger true
      subscribes :restart, "link[#{current_jar_path}]"
      subscribes :restart, "file[#{config_file}]"
    end
  end
end

action :uninstall do

  jar_path = ::File.join(
    new_resource.install_directory,
    ::File.basename(new_resource.package_url)
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
