default[:fission][:lxd][:images] = {
  :centos_6 => 'centos/6/amd64',
  :centos_7 => 'centos/7/amd64',
  :debian_6 => 'debian/squeeze/amd64',
  :debian_7 => 'debian/wheezy/amd64',
  :debian_8 => 'debian/jessie/amd64',
  :ubuntu_1204 => 'ubuntu/precise/amd64',
  :ubuntu_1404 => 'ubuntu/trusty/amd64',
  :ubuntu_1504 => 'ubuntu/vivid/amd64'
}
default[:fission][:lxd][:packages][:centos] = ['autoconf', 'bison', 'flex', 'make', 'gcc', 'gcc-c++', 'kernel-devel', 'm4', 'patch', 'curl']
default[:fission][:lxd][:packages][:default] = ['build-essential', 'curl']
