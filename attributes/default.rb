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

default[:fission][:web][:pkg_url] = "node[:fission][:pkg_url] must be set"
default[:fission][:web][:directories][:install] = '/opt'
default[:fission][:web][:directories][:config] = '/etc/fissionweb'

default[:fission][:web][:user] = 'fissionweb'
default[:fission][:web][:group] = 'fissionweb'
default[:fission][:web][:java_options] = [
  '-Xms1024M',
  '-Xmx1024M'
]

default[:fission][:web][:instances] = {}

default[:fission][:default_config][:instance] = {}
default[:fission][:default_config][:web] = {}
default[:fission][:users][:directory] = '/usr/local/fission/users'
default[:fission][:generator][:gpg_key] = 'packager'
