ruby_block 'data-discovery(riak)' do
  block do
    search_query = [
      "recipes:fission\\:\\:data",
      "fission_core_group:#{node[:fission][:core][:group].gsub(':', '*')}",
      'fission_data_cluster:joined'
    ]
    node.run_state[:fission_riak_nodes] = search(:node, search_query.join(' AND ')).map do |r_node|
      address = node[:fission][:data][:riak][:address_attribute].split('.').inject(r_node) do |memo, key|
        if(memo && val = memo.send(key))
          val
        else
          break
        end
      end
      Mash.new(:host => address)
    end
  end
  only_if do
    node[:fission][:data][:discovery].include?('riak')
  end
end

ruby_block 'data-discovery(sql)' do
  block do
    search_query = [
      "recipes:fission\\:\\:data",
      "fission_core_group:#{node[:fission][:core][:group].gsub(':', '*')}",
      'postgresql:*'
    ]
    addrs = node.run_state[:fission_riak_nodes] = search(:node, search_query.join(' AND ')).map do |r_node|
      address = node[:fission][:data][:sql][:address_attribute].split('.').inject(r_node) do |memo, key|
        if(memo && val = memo.send(key))
          val
        else
          break
        end
      end
    end
    begin
      credentials = Mash.new(
        Chef::EncryptedDataBagItem.load(
          node[:fission][:data][:sql][:credentials_data_bag], 'fission'
        ).to_hash
      )
      node.run_state[:fission_sql_nodes] = Mash.new(:host => addrs.first).merge(credentials)
    rescue Net::HTTPServerException
      Chef::Log.warn "Fission data discovery found no credentials for SQL store"
    end
  end
  only_if do
    node[:fission][:data][:discovery].include?('sql')
  end
end

directory '/etc/fission' do
  recursive true
end

file '/etc/fission/riak.json' do
  content lazy{
    Chef::JSONCompat.to_json_pretty(
      :nodes => node.run_state[:fission_riak_nodes]
    )
  }
  mode 0644
  action :nothing
  subscribes :create, 'ruby_block[data-discovery(riak)]', :immediately
  only_if{ node.run_state[:fission_riak_nodes] }
end

file '/etc/fission/sql.json' do
  content lazy{
    Chef::JSONCompat.to_json_pretty(
      Mash.new(:adapter => :postgres).merge(
        node.run_state[:fission_sql_nodes]
      )
    )
  }
  mode 0644
  action :nothing
  subscribes :create, 'ruby_block[data-discovery(sql)]', :immediately
  only_if{ node.run_state[:fission_sql_nodes] }
end


=begin
discovery_all(
  "recipes:riak AND fission_core_group:#{node.fission.core.group.gsub(':', '\:')}",
  :raw_search => true,
  :empty_ok => true,
  :minimum_response_time_sec => false
)
=end
