include_recipe 'fission::setup'

# Loop attribute driven fission LWRP creation

node[:fission][:instances].each do |fission_name, fission_opts|
  fission fission_name do
    fission_opts.each do |attribute_name, attribute_value|
      self.send(attribute_name, attribute_value)
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
