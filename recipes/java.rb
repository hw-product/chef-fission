node.set[:java][:jdk_version] = node[:fission][:java_version]

if platform_family?("debian")
  node.default[:java][:java_home] = "/usr/lib/jvm/default-java"
  node.default[:java][:openjdk_packages] = [
    "openjdk-#{node[:java][:jdk_version]}-jdk",
    "openjdk-#{node[:java][:jdk_version]}-jre-headless"
  ]
end

include_recipe 'java'
