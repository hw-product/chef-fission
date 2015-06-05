if(platform_family?('debian'))
  include_recipe 'apt'
end

token = credentials_for(:github)[:token]
if(token)
  chef_gem 'octokit'
  require 'uri'
  require 'octokit'
  client = Octokit::Client.new(:access_token => token)
  fission_app = client.releases('hw-product/fission-packaging').sort_by(&:created_at).last.assets.detect do |asset|
    asset.name.end_with?('.deb')
  end.url
  fission_app = URI.parse(fission_app)
  fission_app.userinfo = token
  node.run_state[:fission_pkg_url] = fission_app.to_s
  fission_web_app = client.releases('hw-product/fission-app').sort_by(&:created_at).last.assets.detect do |asset|
    asset.name.end_with?('.deb')
  end.url
  fission_web_app = URI.parse(fission_web_app)
  fission_web_app.userinfo = token
  node.run_state[:fission_web_pkg_url] = fission_web_app.to_s
end
