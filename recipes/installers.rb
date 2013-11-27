# Author:: Matt Ray <matt@opscode.com>
# Cookbook Name:: pxe_dust
# Recipe:: installers
#
# Copyright 2012-2013 Opscode, Inc
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'net/http'

class ::Chef::Recipe
  include ::PxeDust::Helper
end

include_recipe 'pxe_dust::common'

#location of the full stack installers
directory "#{node['pxe_dust']['dir']}/opscode-full-stack" do
  mode '0755'
end

#loop over the other data bag items here
default = pxe_default_model
pxe_dust = pxe_models

pxe_dust.each do |id|
  image = pxe_model_merged(id)
  platform = image['platform']
  arch = image['arch']
  version = image['version']

  if image['bootstrap']
    http_proxy = image['bootstrap']['http_proxy']
    http_proxy_user = image['bootstrap']['http_proxy_user']
    http_proxy_pass = image['bootstrap']['http_proxy_pass']
    https_proxy = image['bootstrap']['https_proxy']
  end

  # only get the full stack installers to use
  rel_arch = case arch
             when 'ppc' then 'powerpc'
             when 'i386' then 'i686'
             else 'x86_64'
             end
  case version
  when /^10\./
    release = "ubuntu-10.04-#{rel_arch}"
  when /^11\./
    release = "ubuntu-11.04-#{rel_arch}"
  when /^12\./
    release = "ubuntu-12.04-#{rel_arch}"
  when /^13\./
    release = "ubuntu-13.04-#{rel_arch}"
  when /^6\.|^7\./
    version = '6'
    release = "debian-6.0.1-#{rel_arch}"
  end

  directory "#{node['pxe_dust']['dir']}/opscode-full-stack/#{release}" do
    mode 0755
  end

  installer = ''
  location = ''

  if arch.eql?('ppc')
    # must install by hand currently chef_11.6.0-1.ubuntu.12.04_amd64.deb
    installer = "chef_#{node['pxe_dust']['chefversion']}-0.#{platform}.#{version}_#{rel_arch}.deb"
  else
    #for getting latest version of full stack installers
     remote_path = OmnibusTrucker.build_url(
        :version => node['pxe_dust']['chefversion'],
        :platform => platform,
        :plateform_version => version,
        :machine => arch
      )

    #download the full stack installer
    remote_file "#{node['pxe_dust']['dir']}/opscode-full-stack/#{release}/#{installer}" do
      source remote_path
      mode 0644
      action :create_if_missing
    end

  end

  run_list = (image['run_list'] || '').split(',') #for supporting multiple items

  #Chef bootstrap script run by new installs
  template "#{node['pxe_dust']['dir']}/#{id}-chef-bootstrap" do
    source 'chef-bootstrap.sh.erb'
    mode 0644
    variables(
      :release => release,
      :installer => installer,
      :interface => image['interface'] || 'eth0',
      :http_proxy => http_proxy,
      :http_proxy_user => http_proxy_user,
      :http_proxy_pass => http_proxy_pass,
      :https_proxy => https_proxy,
      :environment => image['environment'],
      :run_list => run_list
      )
  end

end

#link the validation_key where it can be downloaded
link "#{node['pxe_dust']['dir']}/validation.pem" do
  to Chef::Config[:validation_key]
end
