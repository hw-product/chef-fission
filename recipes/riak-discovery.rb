
riak_nodes = discovery_all(
  "recipes:riak AND fission_core_group:#{node.fission.core.group.gsub(':', '\:')}",
  :raw_search => true,
  :empty_ok => true,
  :minimum_response_time => false
)

directory '/etc/fission' do
  recursive true
end

file '/etc/fission/riak.json' do
  content Chef::JSONCompat.to_json_pretty(:nodes => riak_nodes.map{|n| [:host => n.ipaddress]})
  mode 0644
end
