default[:fission][:name] = 'fission'
default[:fission][:pkg_url] = "node[:fission][:pkg_url] must be set"
default[:fission][:directories][:install] = '/opt'
default[:fission][:directories][:config] = '/etc/fission'
default[:fission][:java_version] = 7

default[:fission][:user] = 'fission'
default[:fission][:group] = 'fission'
default[:fission][:java_path] = '/usr/bin/java'
default[:fission][:java_options] = [
  '-Xms1024M',
  '-Xmx1024M'
]

default[:fission][:instances] = {}
default[:fission][:service_timeout] = 60
