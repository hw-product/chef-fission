use_inline_resource if respond_to?(:use_inline_resource)

def load_current_resource
end

action :add do

  userdir = ::File.join(node[:fission][:users][:directory], new_resource.name)

  user new_resource.name do
    system true
    home userdir
  end

  directory userdir do
    recursive true
    owner new_resource.name
  end

end

action :remove do
  user new_resource.name do
    action :remove
  end
end
