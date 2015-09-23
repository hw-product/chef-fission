actions :install, :uninstall
default_action :install

attribute :system_package_url, :kind_of => String
attribute :package_url, :kind_of => String
attribute :install_directory, :kind_of => String
attribute :config_directory, :kind_of => String
attribute :java_options, :kind_of => Array
attribute :user, :kind_of => String, :default => 'fission'
attribute :group, :kind_of => String
attribute :configuration, :kind_of => Hash
attribute :sudo, :kind_of => [TrueClass, FalseClass], :default => false
attribute :environment, :kind_of => Hash
attribute :java, :kind_of => [TrueClass, FalseClass], :default => false
