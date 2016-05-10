package 'lxd'
package 'lxd-tools'
package 'lxd-client'
package 'zfsutils-linux'

lxd_config = node[:fission][:lxd][:config].map do |k,v|
  next unless v
  "--#{k.to_s.tr('_', '-')} #{v}"
end.compact.join(' ')

service 'lxd' do
  action :stop
  not_if{ File.exist?('/opt/.lxd-config-touch') }
end

service 'lxd-bridge' do
  action :stop
  not_if{ File.exist?('/opt/.lxd-config-touch') }
end

execute 'lxd configuration' do
  command "lxd init --auto #{lxd_config}"
  not_if{ File.exists?('/opt/.lxd-config-touch') }
end

file '/etc/default/lxd-bridge' do
  content lazy{
    node[:fission][:lxd][:network].map do |key, value|
      "#{key.upcase}="#{value}"
    end.join("\n") + "\n"
  }
  if(File.exists?('/opt/.lxd-config-touch'))
    notifies :restart, 'service[lxd-bridge]', :immediately
  end
end

service 'lxd' do
  action :start
end

file '/opt/.lxd-config-touch'

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
  command "lxc launch ubuntu:#{node[:platform_version]} base-ubuntu"
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

# directory File.join(node[:fission][:lxd][:image_directory], 'fission-default') do
#   recursive true
# end

# execute 'export fission-default' do
#   command 'lxc image export local://fission-default'
#   cwd File.join(node[:fission][:lxd][:image_directory], 'fission-default')
# end

# execute 'destroy fission-default image' do
#   command 'lxc image delete local://fission-default'
# end

node[:fission][:lxd][:images].each do |ctn_alias, ctn_name|

  next unless ctn_name
  run_ctn = ctn_alias.tr('_', '-')
  export_directory = File.join(node[:fission][:lxd][:image_directory], run_ctn)

  execute "initialize container - #{ctn_name} -> #{run_ctn}" do
    command "lxc launch images:#{ctn_name} #{run_ctn}"
    not_if "lxc image info #{ctn_alias}"
  end

  packages = node[:fission][:lxd][:packages].fetch(
    ctn_alias.to_s.split('_').first,
    node[:fission][:lxd][:packages][:default]
  )
  pkg_app = ['centos', 'oracle', 'fedora'].include?(ctn_alias.to_s.split('_').first) ? 'yum' : 'apt-get'

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

  # directory export_directory do
  #   recursive true
  # end

  # execute "export container - #{ctn_alias}" do
  #   command "lxc image export local://#{ctn_alias}"
  #   cwd export_directory
  # end

  # execute "destroy container image - #{ctn_alias}" do
  #   command "lxc image delete local://#{ctn_alias}"
  # end

end

# execute "clear all remaining images" do
#   command 'lxc image list | grep -Eo "[a-z0-9]{12}" | xargs -n 1 lxc image delete'
# end


# Dir.glob(File.join(node[:fission][:lxd][:image_directory], '*')).each do |image_path|
#   next unless File.directory?(image_path)
#   ctn_name = File.basename(image_path).tr('-', '_')
#   tarball = File.basename(Dir.glob(File.join(image_path, '*.tar.gz')).first)

#   execute "import container - #{image_path}" do
#     command "lxc image import #{tarball}"
#     cwd image_path
#   end

#   execute "alias imported container - #{ctn_name}" do
#     command "lxc image alias create #{ctn_name} #{tarball.slice(0, 12)}"
#   end

#   execute "alias imported container - #{ctn_name.tr('_', '-')}" do
#     command "lxc image alias create #{ctn_name.tr('_', '-')} #{tarball.slice(0, 12)}"
#   end

#   directory image_path do
#     action :delete
#     recursive true
#   end
# end
