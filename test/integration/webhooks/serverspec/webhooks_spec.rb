require 'spec_helper'

# nellie rest-api available
describe port(8000) do
  it { should be_listening }
end

# nellie loaded webhook worker
describe file( '/var/log/nellie/current' ) do
  it { should be_file }
  its(:content) { should match /Adding callback class \(Fission\:\:Callbacks\:\:Webhook\) under supervision/ }
end

# fire webhook via api and test recorded data of this type:
# data => Event IO  ( building -> built -> failed )

