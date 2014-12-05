node[:fission][:data][:stores].each do |name, args|
  fission_data name do
    args.each do |attr_name, attr_value|
      self.send(attr_name, attr_value)
    end
  end
end
