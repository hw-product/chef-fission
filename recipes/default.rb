include_recipe 'fission::setup'

# Loop attribute driven fission LWRP creation

node[:fission][:instances].each do |fission_name, fission_opts|

  # If we have a pkg_url then we know we have a jar build to configure
  # and run. However, we encounter no pkg_url it is assumed a gem
  # install and will install gems and proxy to jackal cookbook
  if(fission_opts[:pkg_url])
    fission fission_name do
      fission_opts.each do |attribute_name, attribute_value|
        self.send(attribute_name, attribute_value)
      end
    end
  else
    include_recipe 'fission::fission-gems'
    node.set[:jackal][:apps][fission_name] = fission_opts
  end
end

if(node[:jackal][:apps])
  node.set[:jackal][:exec_name] = 'fission'
  include_recipe 'jackal'
end

# Loop attribute driven fission web app LWRP creation

node[:fission][:web][:instances].each do |fission_name, fission_opts|
  fission_web_app fission_name do
    fission_opts.each do |attribute_name, attribute_value|
      self.send(attribute_name, attribute_value)
    end
  end
end
