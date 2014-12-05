default[:fission][:data][:stores] = {}
default[:fission][:data][:discovery] = ['riak', 'sql']
default[:fission][:data][:riak][:address_attribute] = 'ipaddress'
default[:fission][:data][:sql][:address_attribute] = 'ipaddress'
default[:fission][:data][:sql][:system_user] = node[:postgresql][:user]
default[:fission][:data][:sql][:credentials_data_bag] = "credentials"
