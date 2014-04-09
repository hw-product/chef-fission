use_inline_resources

def load_current_resource
end

action :enable do

  run_context.include_recipe 'postgresql::server'

  if(new_resource.repmgr)
    run_context.include_recipe 'repmgr'
  end

  credentials = data_bag(node[:fission][:data][:sql][:credentials_data_bag]).map do |item|
    Mash.new(
      Chef::EncryptedDataBagItem.new(
        item, Chef::EncryptedDataBagItem.load_secret
      ).to_hash
    )
  end

  credentials.each do |args|
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

end

action :disable do
end
