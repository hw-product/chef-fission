
node.default[:fission][:data_store][:riak][:nodes] = search(:node, "recipes:riak AND fission_core_group:#{node.fission.core.group.gsub(':', '\:')}")

=begin
discovery_all(
  "recipes:riak AND fission_core_group:#{node.fission.core.group.gsub(':', '\:')}",
  :raw_search => true,
  :empty_ok => true,
  :minimum_response_time_sec => false
)
=end

directory '/etc/fission' do
  recursive true
end

file '/etc/fission/riak.json' do
  content(
    Chef::JSONCompat.to_json_pretty(
      :nodes => node[:fission][:data_store][:riak][:nodes].map{|n|
        [:host => n.ipaddress]
      }
    )
  )
  mode 0644
end
