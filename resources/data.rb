attr_reader :proxy_attributes

def initialize(*args)
  @proxy_attributes = Mash.new
  super
end

actions :enable, :disable
default_action :enable

attribute :type, :kind_of => String, :required => true

def method_missing(key, value)
  @proxy_attributes[key] = value
end
