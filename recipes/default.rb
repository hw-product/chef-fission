include_recipe 'fission::setup'

# Loop attribute driven fission LWRP creation

node[:fission][:instances].each do |fission_name, fission_opts|

  # If we have a pkg_url then we know we have a jar build to configure
  # and run. However, we encounter no pkg_url it is assumed a gem
  # install and will install gems and proxy to jackal cookbook
  if(fission_opts[:package_url] || fission_opts[:system_package_url] || node.run_state[:fission_pkg_url])
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

# enable nginx proxy to redirect HTTP->HTTPS
if(node[:fission][:web][:redirect_http] == true)
  include_recipe 'nginx'

  nginx_site 'default' do
    enable false
  end

  template ::File.join(node[:nginx][:dir], 'sites-available', 'fission') do
    owner node[:nginx][:user]
    group node[:nginx][:group]
    mode '0755'
    source 'fission-nginx.erb'
  end

  nginx_site 'fission' do
    action :enable
  end

end
