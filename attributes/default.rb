default[:fission][:name] = 'fission'
default[:fission][:pkg_url] = "node[:fission][:pkg_url] must be set"
default[:fission][:directories][:install] = '/opt'
default[:fission][:directories][:config] = '/etc/fission'
default[:fission][:config] = {}
default[:fission][:java_version] = 7

default[:fission][:user] = 'fission'
default[:fission][:group] = 'fission'
default[:fission][:java_path] = '/usr/bin/java'
default[:fission][:java_options] = [
  '-Xms1024M',
  '-Xmx1024M'
]



default[:fission][:jar_path] = "/opt/fission/fission.jar"
default[:fission][:current_jar] = File.basename(node[:fission][:pkg_url])
default[:fission][:config_file] = "/etc/fission/config.json"
default[:fission][:config][:options] = Hash.new

default[:fission][:java_version] = 7

default[:fission][:runit][:log_dir] = "/var/log/fission"

default[:fission][:user] = "fission"
default[:fission][:group] = "fission"
default[:fission][:java_path] = "/usr/bin/java"
default[:fission][:java_options] = [
  "-Xms1024M",
  "-Xmx1024M"
]
