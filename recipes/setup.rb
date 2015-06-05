if(platform_family?('debian'))
  include_recipe 'apt'
end

token = credentials_for(:github)[:token]
if(token)
  chef_gem 'octokit'
  require 'octokit'
  client = Octokit::Client.new(:access_token => token)
  node.set[:fission][:pkg_url] = client.releases('hw-product/fission-packaging').sort_by(&:created_at).last.assets.detect do |asset|
    asset.name.end_with?('.deb')
  end.url
  node.set[:fission][:web][:pkg_url] = client.releases('hw-product/fission-app').sort_by(&:created_at).last.assets.detect do |asset|
    asset.name.end_with?('.deb')
  end.url
end
