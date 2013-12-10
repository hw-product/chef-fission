node.default[:java][:jdk_version] = node[:nellie][:java_version]

pkg_url       = node[:nellie][:pkg_url]
jar_path      = node[:nellie][:jar_path]
current_jar   = node[:nellie][:current_jar]
download_path = File.join(File.dirname(jar_path), File.basename(pkg_url))
config_file   = node[:nellie][:config_file]

if platform_family?("debian")
  node.default[:java][:java_home] = "/usr/lib/jvm/default-java"
  node.default[:java][:openjdk_packages] = [
    "openjdk-#{node[:java][:jdk_version]}-jdk",
    "openjdk-#{node[:java][:jdk_version]}-jre-headless"
  ]
end

include_recipe "apt" if platform_family?("debian")
include_recipe "java"

user node[:nellie][:user]
group node[:nellie][:group]

directory ::File.dirname(config_file) do
  recursive true
end

file config_file do
  owner node[:nellie][:user]
  group node[:nellie][:group]
  mode "0644"
  content node[:nellie][:config][:options].to_json
end

directory ::File.dirname(jar_path) do
  recursive true
end

remote_file download_path do
  source pkg_url
  owner node[:nellie][:user]
  group node[:nellie][:group]
  mode "0644"
end

link jar_path do
  to "./#{current_jar}"
  owner node[:nellie][:user]
  group node[:nellie][:group]
end

if platform_family?("mac_os_x")
  plist = "/Library/LaunchDaemons/com.hw-ops.nellie.plist"
  log_file = "/Library/Logs/Nellie/daemon.log"

  directory ::File.dirname(log_file) do
    owner node[:nellie][:user]
    group node[:nellie][:group]
    recursive true
  end

  template plist do
    source "com.hw-ops.nellie.plist.erb"
    mode 0644
    variables(
      :user => node[:nellie][:user],
      :group => node[:nellie][:group],
      :java_path => node[:nellie][:java_path],
      :java_options => node[:nellie][:java_options],
      :jar_path => jar_path,
      :log_file => log_file
    )
  end

  service "nellie" do
    service_name "com.hw-ops.nellie"
    action :start
    subscribes :restart, "remote_file[#{jar_path}]"
    subscribes :restart, "file[#{config_file}]"
    subscribes :restart, "template[#{plist}]"
  end
else
  runit_log_dir = node[:nellie][:runit][:log_dir]

  include_recipe "runit"

  directory runit_log_dir do
    recursive true
    user node[:nellie][:user]
    group node[:nellie][:group]
  end

  runit_service "nellie" do
    options({
      :user => node[:nellie][:user],
      :group => node[:nellie][:group],
      :java_path => node[:nellie][:java_path],
      :java_options => node[:nellie][:java_options],
      :jar_path => jar_path,
      :config_file => node[:nellie][:config_file]
    })
    subscribes :restart, "remote_file[#{jar_path}]"
    subscribes :restart, "file[#{config_file}]"
    subscribes :restart, "directory[#{runit_log_dir}]"
  end
end
