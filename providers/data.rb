use_inline_resources

def load_current_resource
end

action :enable do
  if new_resource.type == 'sql'
    fission_data_sql new_resource.name do
      repmgr new_resource.repmgr
    end
    elsif new_resource.type == 'riak'
      fission_data_riak new_resource.name do
      repmgr new_resource.repmgr
    end
  end
end

action :disable do
end
