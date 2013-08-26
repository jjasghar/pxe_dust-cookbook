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

include_recipe 'pxe_dust::common'

#location of the full stack installers
directory "#{node['pxe_dust']['dir']}/opscode-full-stack" do
  mode '0755'
end

#loop over the other data bag items here
begin
  default = node['pxe_dust']['default']
  pxe_dust = data_bag('pxe_dust')
  default = data_bag_item('pxe_dust', 'default').merge(default)
rescue
  Chef::Log.warn("No 'pxe_dust' data bag found.")
  pxe_dust = []
end
pxe_dust.each do |id|
  image = default.merge(data_bag_item('pxe_dust', id)).merge(node['pxe_dust']['default'])

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
    Net::HTTP.start('www.opscode.com') do |http|
      Chef::Log.debug("/chef/download?v=#{node['pxe_dust']['chefversion']}&p=#{platform}&pv=#{version}&m=#{rel_arch}")
      response = http.get("/chef/download?v=#{node['pxe_dust']['chefversion']}&p=#{platform}&pv=#{version}&m=#{rel_arch}")
      Chef::Log.debug("Code = #{response.code}")
      location = response['location']
      Chef::Log.info("Omnitruck URL: #{location}")
      installer = location.split('/').last
      Chef::Log.debug("Omnitruck installer: #{installer}")
    end

    #download the full stack installer
    remote_file "#{node['pxe_dust']['dir']}/opscode-full-stack/#{release}/#{installer}" do
      source location
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
