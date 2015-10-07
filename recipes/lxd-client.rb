package 'openssl'

directory '/etc/fission/ssl' do
  recursive true
end

execute 'create LXD key and certificate' do
  command 'openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -keyout /etc/fission/ssl/lxd.key -out /etc/fission/ssl/lxd.crt'
  creates '/etc/fission/ssl/lxd.key'
end

['lxd.key', 'lxd.crt'].each do |file|
  file "/etc/fission/ssl/lxd/#{file}" do
    owner node[:fission][:user]
    group node[:fission][:group]
    mode 0600
  end
end
