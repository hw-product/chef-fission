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

  execute "data store user(sql - #{args[:user]})" do
    command "psql -c \"create user #{args[:user]} with password '#{args[:password]}' login\""
    user node[:fission][:data][:sql][:system_user]
    not_if "su #{node[:fission][:data][:sql][:system_user]} -lc \"psql -tAc 'select * from pg_roles'\" | grep #{args[:user]}"
  end

  execute "data store database(sql - #{args[:database] || args[:user]})" do
    command "createdb #{args[:database] || args[:user]} -O #{args[:user]}"
    user node[:fission][:data][:sql][:system_user]
    not_if "su #{node[:fission][:data][:sql][:system_user]} -lc 'psql -ltA' | grep #{args[:database] || args[:user]}"
  end

end

action :disable do
end
