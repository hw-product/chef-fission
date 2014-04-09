actions :enable, :disable
default_action :enable

attribute :repmgr, :kind_of => [TrueClass, FalseClass], :default => false
