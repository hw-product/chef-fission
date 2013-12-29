use_inline_resources(true) if self.respond_to?(:use_inline_resources)

def load_current_resource
  # Default resource attributes to node attributes
  {
    :install_directory => node[:fission][:web][:directories][:install],
    :config_directory => node[:fission][:web][:directories][:config],
    :user => node[:fission][:web][:user],
    :group => node[:fission][:web][:group],
    :package_url => node[:fission][:web][:pkg_url],
    :java_options => node[:fission][:web][:java_options]
  }.each do |resource_method, default_value|
    unless(new_resource.send(resource_method))
      new_resource.send(resource_method, default_value)
    end
  end
end

action :install do

  set_log_config unless new_resource.log_config

  run_context.include_recipe 'fission::setup'
  chef_gem 'xml-simple'
  require 'xmlsimple'

  jar_path = ::File.join(
    new_resource.install_directory,
    ::File.basename(new_resource.package_url)
  )
  current_jar_path = ::File.join(
    new_resource.install_directory,
    new_resource.name
  )
  log_config_file = ::File.join(
    new_resource.config_directory,
    "#{new_resource.name}.log.xml"
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

  file log_config_file do
    content(
      SimpleXml.xml_out(
        new_resource.log_config,
        'AttrPrefix' => true,
        'KeepRoot' => true
      )
    )
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
      source "com.hw-ops.fission.plist-web.erb"
      mode 0644
      variables(
        :service_name => fission_service,
        :user => new_resource.user,
        :group => new_resource.group,
        :timeout => new_resource.service_timeout || node[:fission][:service_timeout],
        :java_path => node[:fission][:java_path],
        :java_options => new_resource.java_options,
        :jar_path => current_jar_path,
        :log_file => log_file,
        :log_config_file => log_config_file,
        :logger_config_name => new_resource.logger_config_name
      )
    end

    service new_resource.name do
      service_name fission_service
      action :start
      subscribes :restart, "link[#{jar_path}]"
      subscribes :restart, "template[#{plist}]"
    end

  else
    run_context.include_recipe 'runit'

    runit_service new_resource.name do
      run_template_name 'fission-web'
      options(
        :user => new_resource.user,
        :group => new_resource.group,
        :java_path => node[:fission][:java_path],
        :java_options => new_resource.java_options,
        :jar_path => current_jar_path,
        :log_config_file => log_config_file,
        :logger_config_name => new_resource.logger_config_name
      )
      default_logger true
      subscribes :restart, "link[#{jar_path}]"
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
  log_config_file = ::File.join(
    new_resource.config_directory,
    "#{new_resource.name}.log.xml"
  )

  [jar_path, current_jar_path, log_config_file].each do |file_path|
    file file_path do
      action :delete
    end
  end

end

def set_log_config
  new_resource.log_config(
    :configuration => {
      :appender => [
        {
          :@name => 'file',
          :@class => 'ch.qos.logback.core.rolling.RollingFileAppender',
          :File => ::File.join('/var/log', new_resource.name),
          :encoder => {
            :pattern => '%d{yyyy-MM-dd HH:mm:ss} %-5p %c{1}:%L - %m'
          },
          :rollingPolicy => {
            :@class => 'ch.qos.logback.core.rolling.FixedWindowRollingPolicy',
            :maxIndex => 10,
            :FileNamePattern => ::File.join('/var/log', "#{new_resource.name}.%i")
          },
          :triggeringPolicy => {
            :@class => 'ch.qos.logback.core.rolling.SizeBasedTriggeringPolicy',
            :MaxFileSize => '50MB'
          }
        },
        {
          :@name => 'stdout',
          :@class => 'ch.qos.logback.core.ConsoleAppender',
          :Target => 'System.out',
          :encoder => {
            :pattern => '%d{yyyy-MM-dd HH:mm:ss} %-5p %c{1}:%L - %m'
          }
        }
      ],
      :root => {
        :@level => 'INFO',
        'appender-ref' => [
          {:@ref => 'file'}, {:@ref => 'stdout'}
        ]
      }
    }
  )
end
