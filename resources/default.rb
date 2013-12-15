actions :install, :uninstal
default_action :install

attribute :package_url, :kind_of => String
attribute :install_directory, :kind_of => String
attribute :config_directory, :kind_of => String
attribute :java_options, :kind_of => Array
attribute :user, :kind_of => String
attribute :group, :kind_of => String
attribute :config, :kind_of => Hash
