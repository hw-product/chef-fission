actions :install, :uninstall
default_action :install

attribute :package_url, :kind_of => String
attribute :install_directory, :kind_of => String
attribute :config_directory, :kind_of => String
attribute :java_options, :kind_of => Array
attribute :user, :kind_of => String
attribute :group, :kind_of => String
attribute :logger_config_name, :kind_of => String, :default => 'configurationFile'
attribute :log_config, :kind_of => Hash
attribute :config, :kind_of => Hash
