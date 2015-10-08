package 'openssl'

directory '/etc/fission/ssl' do
  recursive true
end

execute 'create LXD key and certificate' do
  command 'openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -keyout /etc/fission/ssl/lxd.key -out /etc/fission/ssl/lxd.crt -batch'
  creates '/etc/fission/ssl/lxd.key'
end

['lxd.key', 'lxd.crt'].each do |file|
  file "/etc/fission/ssl/#{file}" do
    owner node[:fission][:user]
    group node[:fission][:group]
    mode 0600
  end
end

lxd_node = search(:node, "roles:lxd").first

if(lxd_node)
  node[:fission][:instances].each do |fission_name, fission_opts|
    fission_opts.default[:configuration][:fission][:remote_process] = Mash.new(
      :api_endpoint => "https://#{lxd_node.ipaddress}:8443",
      :password => node[:stack][:grouping],
      :ssl_key => '/etc/fission/ssl/lxd.key',
      :ssl_cert => '/etc/fission/ssl/lxd.crt'
    )
  end
end
