
lxd_config = node[:fission][:lxd][:config].map do |k,v|
  next unless v
  "--#{k.to_s.tr('_', '-')} #{v}"
end.compact.join(' ')

execute 'lxd configuration' do
  command "lxd --auto #{lxd_config}"
  not_if File.exists?('/opt/.lxd-config-touch')
end

file '/opt/.lxd-config-touch'

Dir.glob(File.join(node[:fission][:lxd][:image_directory], '*')).each do |image_path|
  next unless File.directory?(image_path)
  ctn_name = File.basename(image_path)

  execute "import container - #{ctn_name}" do
    command "lxc image import metadata.tar.gz rootfs.tar.gz"
    cwd image_path
  end

  directory image_path do
    action :delete
    recursive true
  end
end
