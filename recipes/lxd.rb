
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
  not_if File.exists?('/opt/.lxd-config-touch')
end

service 'lxd' do
  action :start
end

service 'lxd-bridge' do
  action :start
end

file '/opt/.lxd-config-touch'

Dir.glob(File.join(node[:fission][:lxd][:image_directory], '*')).each do |image_path|
  next unless File.directory?(image_path)
  ctn_name = File.basename(image_path).tr('-', '_')
  tarball = File.basename(Dir.glob(File.join(image_path, '*.tar.gz')).first)

  execute "import container - #{image_path}" do
    command "lxc image import #{tarball}"
    cwd image_path
  end

  execute "alias imported container - #{ctn_name}" do
    command "lxc image alias create #{ctn_name} #{tarball.slice(0, 12)}"
  end

  directory image_path do
    action :delete
    recursive true
  end
end
