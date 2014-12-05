use_inline_resources

def load_current_resource
end

action :enable do

  run_context.include_recipe 'postgresql::server'

  node.default[:postgresql][:config][:listen_addresses] = '*'
  node.default[:postgresql][:pg_hba] = node.default[:postgresql][:pg_hba].push(
    :type => 'host', :db => 'all', :user => 'all', :addr => '0.0.0.0/0', :method => 'md5'
  ).uniq

  if(new_resource.repmgr)
    run_context.include_recipe 'repmgr'
  end

  args = credentials_for(new_resource.name)

  bash "data store user(sql - #{args[:user]})" do
    command %(psql -c "create user #{args[:user]} with password '#{args[:password]}' login")
    user node[:fission][:data][:sql][:system_user]
    not_if %(sudo -u #{node[:fission][:data][:sql][:system_user]} psql -c "\du" | grep #{args[:user]})
  end

  bash "data store database(sql - #{args[:user]})" do
    command %(psql -c "create database #{args[:database] || args[:user]}")
    user node[:fission][:data][:sql][:system_user]
    action :nothing
    subscribes :run, "bash[data store user(sql - #{args[:user]})]", :immediately
  end

end

action :disable do
end
