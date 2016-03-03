include_recipe 'apt'

[node[:fission][:github_package_repo]].flatten.compact.each do |github_repo|

  srv_name = github_repo.split('/').last

  chef_gem 'octokit'
  require 'uri'
  require 'octokit'
  client = Octokit::Client.new(
    :access_token => github_repo
  )
  package_asset = client.releases(github_repo).sort_by(&:created_at).last.assets.detect do |asset|
    asset.name.end_with?('.deb')
  end
  package_url = URI.parse(package_asset)
  package_url.userinfo = node[:fission][:github_access_token]
  local_path = File.join(Chef::Config[:file_cache_path], "#{srv_name}.deb")

  dpkg_package srv_name do
    source local_path
    action :nothing
    notifies :restart, "service[#{srv_name}]"
  end

  remote_file local_path do
    source package_url.to_s
    headers 'Accept' => 'application/octet-stream'
    mode 0644
    notifies :install, "dpkg_package[#{srv_name}]", :immediately
  end

  service srv_name do
    supports :restart => true
    action [:enable, :start]
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
