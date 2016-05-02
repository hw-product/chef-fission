node.override[:postgresql][:enable_pgdg_apt] = false
include_recipe 'postgresql::server'

node.default[:postgresql][:config][:listen_addresses] = '*'
node.default[:postgresql][:pg_hba] = node.default[:postgresql][:pg_hba].push(
  :type => 'host', :db => 'all', :user => 'all', :addr => '0.0.0.0/0', :method => 'md5'
).uniq

execute 'create-fission-user' do
  command "psql -c \"create user #{node[:fission][:data][:username]} with password '#{node[:fission][:data][:password]}' login\""
  not_if "psql -c \"select * from pg_roles where rolname = '#{node[:fission][:data][:username]}'\" | grep #{node[:fission][:data][:username]}"
  user 'postgres'
end

execute 'create-fission-database' do
  command "createdb #{node[:fission][:data][:name]} -O #{node[:fission][:data][:username]}"
  not_if "psql -c '\\d' fission"
  user 'postgres'
end

execute 'fetch-fission-database-backup' do
  command "aws s3 cp s3://#{node[:fission][:data][:bucket]}/fission-database/latest.tgz /tmp/latest.tgz"
  not_if do
    File.exists?('/opt/fission-data.install')
  end
  only_if "aws s3 ls s3://#{node[:fission][:data][:bucket]}/fission-database/latest.tgz"
  creates '/tmp/latest.tgz'
end

execute 'unpack-fission-databse-backup' do
  command 'tar --directory /tmp -xzf /tmp/latest.tgz'
  creates '/tmp/latest.dump'
  only_if do
    !File.exists?('/opt/fission-data.install') &&
      File.exists?('/tmp/latest.tgz')
  end
end

execute 'restore-fission-database-backup' do
  command "psql --dbname #{node[:fission][:data][:name]} < /tmp/latest.dump"
  only_if do
    !File.exists?('/opt/fission-data.install') &&
      File.exists?('/tmp/latest.dump')
  end
  user 'postgres'
end

file '/opt/fission-data.install' do
  owner 0600
end

file '/tmp/latest.dump' do
  action :delete
end

file '/tmp/latest.tgz' do
  action :delete
end

template '/usr/local/bin/fission-database-backup' do
  source 'fission-database-backup.erb'
  mode 0755
end

cron 'fission-database-backup' do
  time :hourly
  command '/usr/local/bin/fission-database-backup'
end
