include_recipe 'riak'

directory '/etc/fission' do
  recursive true
end

file '/etc/fission/riak.json' do
  content Chef::JSONCompat.to_json_pretty(:nodes => [:host => '127.0.0.1'])
  mode 0644
end
