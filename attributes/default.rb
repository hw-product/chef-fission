default[:fission][:name] = 'fission'
default[:fission][:pkg_url] = "node[:fission][:pkg_url] must be set"
default[:fission][:directories][:install] = '/opt'
default[:fission][:directories][:config] = '/etc/fission'
default[:fission][:java_version] = 7

default[:fission][:user] = 'fission'
default[:fission][:group] = 'fission'
default[:fission][:home] = '/opt/fission-home'
default[:fission][:java_path] = '/usr/bin/java'
default[:fission][:java_options] = [
  '-Xms1024M',
  '-Xmx1024M'
]

default[:fission][:instances] = {}
default[:fission][:service_timeout] = 60

default[:fission][:working_directory] = '/tmp/fission'

default[:fission][:web][:pkg_url] = "node[:fission][:pkg_url] must be set"
default[:fission][:web][:directories][:install] = '/opt'
default[:fission][:web][:directories][:config] = '/etc/fissionweb'
default[:fission][:web][:redirect_http] = false

default[:fission][:web][:user] = 'fissionweb'
default[:fission][:web][:group] = 'fissionweb'
default[:fission][:web][:java_options] = [
  '-Xms1024M',
  '-Xmx1024M'
]

default[:fission][:web][:log_config] = {
  :configuration => {
    :appender => [
      {
        :@name => 'file',
        :@class => 'ch.qos.logback.core.rolling.RollingFileAppender',
        :File => '/var/log/fission-web',
        :encoder => {
          :pattern => '%d{yyyy-MM-dd HH:mm:ss} %-5p %c{1}:%L - %m'
        },
        :rollingPolicy => {
          :@class => 'ch.qos.logback.core.rolling.FixedWindowRollingPolicy',
          :maxIndex => 10,
          :FileNamePattern => '/var/log/fission-web.%i'
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
}

default[:fission][:web][:instances] = {}

default[:fission][:default_config][:instance] = {}
default[:fission][:default_config][:web] = {}
default[:fission][:users][:directory] = '/home'
default[:fission][:generator][:gpg_key] = 'packager'

default[:fission][:gems] = Mash.new
default[:fission][:service][:action] = 'start'
