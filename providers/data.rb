use_inline_resources

def load_current_resource
end

action :enable do

  send("fission_data_#{new_resource.type}", new_resource.name) do
    new_resource.proxy_attributes.each do |attr_name, attr_value|
      self.send(attr_name, attr_value)
    end
  end

end

action :disable do
end
