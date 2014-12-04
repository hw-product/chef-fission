include_recipe 'fission::setup'

# Loop attribute driven fission LWRP creation

node[:fission][:instances].each do |fission_name, fission_opts|

  # If we have a pkg_url then we know we have a jar build to configure
  # and run. However, we encounter no pkg_url it is assumed a gem
  # install and will install gems and proxy to jackal cookbook
  fission fission_name do
    if(fission_opts[:pkg_url])
      fission_opts.each do |attribute_name, attribute_value|
        self.send(attribute_name, attribute_value)
      end
    else
      include_recipe 'fission::fission-gems'
      include_recipe 'jackal'
      node.set[:jackal][:apps][fission_name] = fission_opts
    end
  end
end

# Loop attribute driven fission web app LWRP creation

node[:fission][:web][:instances].each do |fission_name, fission_opts|
  fission_web_app fission_name do
    fission_opts.each do |attribute_name, attribute_value|
      self.send(attribute_name, attribute_value)
    end
  end
end
