default[:fission][:lxd][:images] = {
 :centos_6 => 'centos/6/amd64',
 :centos_7 => 'centos/7/amd64',
 :fedora_22 => 'fedora/22/amd64',
 :fedora_23 => 'fedora/23/amd64',
# :opensuse_132 => 'opensuse/13.2/amd64',
 :oracle_6 => 'oracle/6/amd64',
 :oracle_7 => 'oracle/7/amd64',
 :debian_7 => 'debian/wheezy/amd64',
 :debian_8 => 'debian/jessie/amd64',
 :debian_testing => 'debian/stretch/amd64',
 :debian_unstable => 'debian/sid/amd64',
 :ubuntu_1204 => 'ubuntu/precise/amd64',
 :ubuntu_1404 => 'ubuntu/trusty/amd64',
 :ubuntu_1604 => 'ubuntu/xenial/amd64',
 :ubuntu_1610 => 'ubuntu/yakkety/amd64'

}
default[:fission][:lxd][:packages][:centos] = ['autoconf', 'bison', 'flex', 'make', 'gcc', 'gcc-c++', 'kernel-devel', 'm4', 'patch', 'curl', 'unzip', 'zip']
default[:fission][:lxd][:packages][:default] = ['build-essential', 'curl', 'zip', 'unzip']
default[:fission][:lxd][:password] = SecureRandom.hex
default[:fission][:lxd][:image_directory] = '/opt/lxd-images'
default[:fission][:lxd][:config][:storage_backend] = 'dir'
default[:fission][:lxd][:config][:storage_create_device] = nil
default[:fission][:lxd][:config][:storage_create_loop] = 2
default[:fission][:lxd][:config][:storage_pool] = 'lxd'
