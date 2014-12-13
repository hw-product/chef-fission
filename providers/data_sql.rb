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

  if node[:fission][:data][:sql][:backup] == true
    run_context.include_recipe 'build-essential'
    run_context.include_recipe 'backup'
    backup_creds = credentials_for(node[:fission][:data][:backup_credentials])
    backup_model :fission_db do
      description "Fission DB backup"

      definition <<-DEF

      database PostgreSQL do |db|
        db.name = '#{args[:database]}'
        db.username = '#{args[:user]}'
        db.password = '#{args[:password]}'
        db.host = '127.0.0.1'
      end

      compress_with Gzip

      store_with S3 do |s3|
        s3.access_key_id = '#{backup_creds[:access_key_id]}'
        s3.secret_access_key = '#{backup_creds[:secret_access_key]}'
        s3.bucket = '#{backup_creds[:bucket]}'
      end
      DEF

      schedule({
        :minute => node[:fission][:data][:sql][:backup_minute],
        :hour   => node[:fission][:data][:sql][:backup_hour]
      })
    end
  end
end

action :disable do
end
