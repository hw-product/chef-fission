use_inline_resources

include Chef::Mixin::ShellOut

def load_current_resource
end

action :init do
  node.set[:riak][:args]['-setcookie'] = generate_cookie
  run_context.include_recipe 'riak'
end

action :join do

  unless(joined?)
    timeout = new_resource.timeout
    cluster = search(:node, "riak_args_-setcookie:#{generate_cookie}")
    cluster.delete_if{|n| n.name == node.name}
    Chef::Log.debug "Data nodes found in cluster: #{cluster.inspect}"

    if(cluster.size > 1)
      to_join = cluster.shuffle.first

      execute "fission data <cluster join [#{node} -> #{to_join}]>" do
        command "riak-admin cluster join #{to_join[:riak][:args]['-name']}"
      end

      while(!ring_ready? && timeout > 0)
        timeout -= 1
        sleep 1
      end

      if(timeout < 1)
        Chef::Application.fatal! 'Failed to join data node into cluster!'
      end

      node.set[:fission][:data][:cluster] = 'joined'

    else

      node.set[:fission][:data][:cluster] = 'unjoined'

    end
  end
end

action :leave do

  execute "fission data <cluster leave [#{node}]>" do
    command 'riak-admin cluster leave'
    only_if{ joined? }
  end

end

def generate_cookie
  node[:fission][:core][:group].gsub(/[^\w]/, '')
end

def ring_ready?
  cmd = shell_out('riak-admin ringready')
  cmd.stdout.downcase.start_with?('true')
end

def joined?
  cmd = shell_out('riak-admin ringready')
  cmd.stdout.scan(/'([^']+)'/).flatten.count > 1
end
