# We assume up front lxd is here

package 'lxd'
package 'lxd-tools'
package 'lxd-client'

file '/etc/default/lxd-bridge' do
  content <<-EOS
USE_LXD_BRIDGE="true"
LXD_BRIDGE="lxdbr0"
UPDATE_PROFILE="true"
LXD_CONFILE=""
LXD_DOMAIN="lxd"
LXD_IPV4_ADDR="10.0.8.1"
LXD_IPV4_NETMASK="255.255.255.0"
LXD_IPV4_DHCP_RANGE="10.0.8.2,10.0.8.254"
LXD_IPV4_NETWORK="10.0.8.1/24"
LXD_IPV4_DHCP_MAX="253"
LXD_IPV4_NAT="true"
LXD_IPV6_ADDR=""
LXD_IPV6_NETWORK=""
LXD_IPV6_NAT="false"
LXD_IPV6_PROXY="false"
EOS
end

service 'lxd-bridge' do
  subscribes :stop, 'file[/etc/default/lxd-bridge]', :immediately
end

service 'lxd' do
  supports :restart => true
  subscribes :restart, 'file[/etc/default/lxd-bridge]', :immediately
end

execute 'open lxd API' do
  command 'lxc config set core.https_address [::]:8443'
end

execute 'set lxd password' do
  command "lxc config set core.trust_password #{node[:fission][:lxd][:password]}"
end

execute 'add lxd images server' do
  command 'lxc remote add images images.linuxcontainers.org'
  not_if 'lxc remote list | grep images.linuxcontainers.org'
end

execute 'start base ubuntu for setup' do
  command 'lxc launch ubuntu:16.04 base-ubuntu'
  not_if 'lxc image info fission-default || lxc info base-ubuntu'
end

execute "wait for network on base ubuntu" do
  command "lxc exec base-ubuntu -- ip addr show eth0 | grep 'inet '"
  not_if 'lxc image info fission-default'
  retries 20
end

execute 'update apt in base ubuntu' do
  command 'lxc exec base-ubuntu -- apt-get update -qy'
  not_if 'lxc image info fission-default'
end

execute 'install packages to base ubuntu' do
  command 'lxc exec base-ubuntu -- apt-get install ruby ruby-dev libyajl-dev build-essential zip unzip -qy'
  not_if 'lxc image info fission-default'
end

execute 'install expected gems' do
  command 'lxc exec base-ubuntu -- gem install --no-document attribute_struct bundler'
  not_if 'lxc image info fission-default'
end

execute 'stop base ubuntu' do
  command 'lxc stop base-ubuntu'
  not_if 'lxc image info fission-default'
end

execute 'image base ubuntu to fission-default' do
  command 'lxc publish base-ubuntu --alias fission-default'
  not_if 'lxc image info fission-default'
end

execute 'destroy base container' do
  command 'lxc delete base-ubuntu'
  only_if 'lxc info base-ubuntu'
end

node[:fission][:lxd][:images].each do |ctn_alias, ctn_name|

  next unless ctn_name

  run_ctn = ctn_alias.tr('_', '-')

  execute "initialize container - #{ctn_name} -> #{run_ctn}" do
    command "lxc launch images:#{ctn_name} #{run_ctn}"
    not_if "lxc image info #{ctn_alias}"
  end

  packages = node[:fission][:lxd][:packages].fetch(
    ctn_alias.to_s.split('_').first,
    node[:fission][:lxd][:packages][:default]
  )
  pkg_app = ctn_alias.to_s.split('_').first == 'centos' ? 'yum' : 'apt-get'

  execute "wait for network - #{run_ctn}" do
    command "lxc exec #{run_ctn} -- ip addr show eth0 | grep 'inet '"
    action :nothing
    subscribes :run, "execute[initialize container - #{ctn_name} -> #{run_ctn}]", :immediately
    retries 20
  end

  execute "update package repositories - #{run_ctn}" do
    command "lxc exec #{run_ctn} -- #{pkg_app} update -yq"
    action :nothing
    subscribes :run, "execute[initialize container - #{ctn_name} -> #{run_ctn}]", :immediately
  end

  execute "package install container - #{run_ctn}" do
    command "lxc exec #{run_ctn} -- #{pkg_app} install -yq #{packages.join(' ')}"
    action :nothing
    subscribes :run, "execute[initialize container - #{ctn_name} -> #{run_ctn}]", :immediately
  end

  execute "chef install script container - #{run_ctn}" do
    command "lxc exec #{run_ctn} -- curl -o /tmp/install.sh https://www.opscode.com/chef/install.sh"
    action :nothing
    subscribes :run, "execute[initialize container - #{ctn_name} -> #{run_ctn}]", :immediately
  end

  execute "chef install container - #{run_ctn}" do
    command "lxc exec #{run_ctn} -- bash /tmp/install.sh -v 11"
    action :nothing
    subscribes :run, "execute[initialize container - #{ctn_name} -> #{run_ctn}]", :immediately
  end

  execute "stop container for imaging - #{run_ctn}" do
    command "lxc stop #{run_ctn} --force"
    action :nothing
    subscribes :run, "execute[initialize container - #{ctn_name} -> #{run_ctn}]", :immediately
  end

  execute "image container - #{ctn_alias}" do
    command "lxc publish #{run_ctn} --alias #{ctn_alias}"
    action :nothing
    subscribes :run, "execute[initialize container - #{ctn_name} -> #{run_ctn}]", :immediately
  end

  execute "destroy container - #{run_ctn}" do
    command "lxc delete #{run_ctn}"
    action :nothing
    subscribes :run, "execute[initialize container - #{ctn_name} -> #{run_ctn}]", :immediately
  end

end
