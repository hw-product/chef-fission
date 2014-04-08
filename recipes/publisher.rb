include_recipe 'apache2'

directory node[:fission][:publisher][:apache][:root] do
  recursive true
end

template File.join(node[:apache][:dir], 'sites-available', 'publisher.conf') do
  source 'apache.publisher.conf'
  mode 0644
  notifies :reload, 'service[apache2]'
end

apache_site 'publisher' do
  enable true
end
