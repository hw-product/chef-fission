# Setup configuration files for event handling

file '/etc/chef-server/jackal-client.rb' do
  content [
    'chef_server_url "https://127.0.0.1"',
    'node_name "admin"',
    'client_key "/etc/chef-server/admin.pem"',
    'ssl_verify_mode :verify_none'
  ].join("\n") << "\n"
end
