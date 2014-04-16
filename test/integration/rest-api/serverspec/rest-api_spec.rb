require 'spec_helper'

# nellie rest-api available
describe port(8000) do
  it { should be_listening }
end
