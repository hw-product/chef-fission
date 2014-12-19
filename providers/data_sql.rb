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
  database = (args[:database] || args[:user])
  backup_base_dir = node[:fission][:data][:sql][:backup][:directory]
  backup_path = ::File.join(backup_base_dir, database)
  latest_symlink_path = ::File.join(backup_path, 'latest')
  restore_dir = ::File.join(backup_base_dir, 'restore')
  backup_tar = ::File.join(restore_dir, 'latest.tar')
  backup_creds = credentials_for(node[:fission][:data][:backup_credentials])

  execute "data store user(sql - #{args[:user]})" do
    command "psql -c \"create user #{args[:user]} with password '#{args[:password]}' login\""
    user node[:fission][:data][:sql][:system_user]
    not_if "su #{node[:fission][:data][:sql][:system_user]} -lc \"psql -tAc 'select * from pg_roles'\" | grep #{args[:user]}"
  end

  [backup_base_dir, restore_dir].each do |dir|
    directory dir do
      action :create
      recursive true
      owner node[:fission][:data][:sql][:system_user]
      group node[:fission][:data][:sql][:system_user]
      mode '0755'
    end
  end

  require 'digest/sha2'
  require 'chef/digester'

  import_guard_cmd = "su #{node[:fission][:data][:sql][:system_user]} -lc 'psql -ltA' | grep #{database}"

  sk_s3_file ::File.join(restore_dir, 's3_download') do
    remote_path "/backups/#{database}/latest.tar"
    bucket backup_creds[:bucket]
    aws_access_key_id backup_creds[:access_key_id]
    aws_secret_access_key backup_creds[:secret_access_key]
    owner node[:fission][:data][:sql][:system_user]
    group node[:fission][:data][:sql][:system_user]
    mode "0644"
    ignore_failure true
    notifies :run, "ruby_block[rename s3 download]", :immediately
  end

  ruby_block "rename s3 download" do
    block do
      FileUtils.mv(::File.join(restore_dir, 's3_download'),
                   ::File.join(restore_dir, 'latest.tar'))
    end
    action :nothing
  end

  ruby_block "restore backup data" do
    block {}
    action :run
    not_if import_guard_cmd
    only_if "test -f #{::File.join(restore_dir, 'latest.tar')}"
  end

  execute "untar #{database} backup" do
    action :nothing
    subscribes :run, "ruby_block[restore backup data]", :immediately
    command "tar -xf #{backup_tar} -C #{restore_dir}"
    user node[:fission][:data][:sql][:system_user]
    not_if import_guard_cmd
  end

  execute "unzip #{database} sql" do
    action :nothing
    subscribes :run, "ruby_block[restore backup data]", :immediately
    command "gunzip #{::File.join(restore_dir, database, 'databases', 'PostgreSQL.sql.gz')}"
    user node[:fission][:data][:sql][:system_user]
    not_if import_guard_cmd
  end

  execute "restore database(sql - #{database})" do
    action :nothing
    subscribes :run, "ruby_block[restore backup data]", :immediately
    command "createdb #{database} -O #{args[:user]}; psql -d #{database} < #{::File.join(restore_dir, database, 'databases', 'PostgreSQL.sql')}"
    user node[:fission][:data][:sql][:system_user]
    not_if import_guard_cmd
  end

  execute "data store database(sql - #{database})" do
    command "createdb #{database} -O #{args[:user]}"
    user node[:fission][:data][:sql][:system_user]
    not_if "su #{node[:fission][:data][:sql][:system_user]} -lc 'psql -ltA' | grep #{database}"
  end


  if node[:fission][:data][:sql][:backup][:enabled] == true

    run_context.include_recipe 'build-essential'
    run_context.include_recipe 'backup'

    backup_model database.to_sym do
      description "#{database} backup"

      definition <<-DEF

      database PostgreSQL do |db|
        db.name = '#{database}'
        db.username = '#{args[:user]}'
        db.password = '#{args[:password]}'
        db.host = '127.0.0.1'
      end

      compress_with Gzip

      store_with Local do |local|
        local.path = '#{backup_base_dir}'
      end

      sync_with Cloud::S3 do |s3|
        s3.access_key_id = '#{backup_creds[:access_key_id]}'
        s3.secret_access_key = '#{backup_creds[:secret_access_key]}'
        s3.bucket = '#{backup_creds[:bucket]}'
        s3.mirror = false
        s3.directories do |directory|
          directory.add '#{backup_path}'
        end
      end

      after do |exit_status|

        latest = Dir["#{::File.join(backup_path, '*')}"].sort_by{|f|::File.mtime(f)}.last
        if latest
          FileUtils.cp(::File.join(latest, 'fission.tar'), ::File.join('#{backup_path}', 'latest.tar'))
          connection = Fog::Storage.new({
            :provider                 => 'AWS',
            :aws_access_key_id        => '#{backup_creds[:access_key_id]}',
            :aws_secret_access_key    => '#{backup_creds[:secret_access_key]}'
          })
          bucket = connection.directories.get('#{backup_creds[:bucket]}')
          bucket.files.create(
            :key => 'backups/#{database}/latest.tar',
            :body => ::File.open(::File.join('#{backup_path}', 'latest.tar')))
        end
      end

      notify_by Slack do |slack|
        slack.on_success = #{node[:fission][:data][:sql][:backup][:slack][:on_success]}
        slack.on_warning = #{node[:fission][:data][:sql][:backup][:slack][:on_warning]}
        slack.on_failure = #{node[:fission][:data][:sql][:backup][:slack][:on_failure]}

        slack.team = "#{node[:fission][:data][:sql][:backup][:slack][:team]}"
        slack.token = "#{node[:fission][:data][:sql][:backup][:slack][:token]}"
      end

      DEF

      schedule({
        :minute => node[:fission][:data][:sql][:backup][:minute],
        :hour   => node[:fission][:data][:sql][:backup][:hour]
      })
      cron_options({
        path: '/opt/chef/embedded/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
      })

    end
  end
end

action :disable do
end
