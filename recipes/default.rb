node.default[:java][:jdk_version] = node[:nellie][:java_version]

jar_path = node[:nellie][:jar_path]

if platform_family?("debian")
  node.default[:java][:java_home] = "/usr/lib/jvm/default-java"
  node.default[:java][:openjdk_packages] = [
    "openjdk-#{node[:java][:jdk_version]}-jdk",
    "openjdk-#{node[:java][:jdk_version]}-jre-headless"
  ]
end

include_recipe "apt" if platform_family?("debian")
include_recipe "java"
include_recipe "runit"

directory ::File.dirname(jar_path) do
  recursive true
end

user node[:nellie][:user]
group node[:nellie][:group]

remote_file jar_path do
  source node[:nellie][:pkg_url]
  owner node[:nellie][:user]
  group node[:nellie][:group]
  mode "0644"
  notifies :restart, "runit_service[nellie]"
end

runit_service "nellie" do
  options({
    :user => node[:nellie][:user],
    :group => node[:nellie][:group],
    :java_path => node[:nellie][:java_path],
    :java_options => node[:nellie][:java_options],
    :jar_path => jar_path
  })
  notifies :restart, "runit_service[nellie]"
end
