default[:nellie][:pkg_url] = "node[:nellie][:pkg][:url] must be set"
default[:nellie][:jar_path] = "/opt/nellie/nellie.jar"
default[:nellie][:config_file] = "/etc/nellie/config.json"
default[:nellie][:config][:options] = Hash.new

default[:nellie][:java_version] = 7

default[:nellie][:user] = "nellie"
default[:nellie][:group] = "nellie"
default[:nellie][:java_path] = "/usr/bin/java"
default[:nellie][:java_options] = "-Xms1024M -Xmx1024M"
