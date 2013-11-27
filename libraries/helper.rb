module PxeDust
  module Helper

    def pxe_models
      begin
        ret = data_bag('pxe_dust')
      rescue
        Chef::Log.warn("No 'pxe_dust' data bag found.")
        ret = node['pxe_dust']['models'].keys
      end
      ret ||= []
      Chef::Log.debug("pxe_models = #{ret}")
      return ret
    end

    def pxe_default_model
      attr_default = node['pxe_dust']['default']
      model_default = pxe_model(node['pxe_dust']['default_model'])
      ret = model_default.merge(attr_default)
      Chef::Log.debug("pxe_default_model = #{ret}")
      return ret
    end

    def pxe_model_merged(id)
      db_model = pxe_model(id)
      return pxe_default_model.merge(db_model).merge(node['pxe_dust']['default'])
    end

    def pxe_model(id)
      begin
        ret = data_bag_item('pxe_dust',id)
      rescue
        ret = node['pxe_dust']['models'][id]
      end
      return ret
    end
  end
end
