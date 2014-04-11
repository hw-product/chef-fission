
node[:fission][:data][:stores].each do |name, args|
  fission_data_riak name do
    args.each do |attr_name, attr_value|
      self.send(attr_name, attr_value)
    end
  end
end
