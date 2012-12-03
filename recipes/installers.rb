# Author:: Matt Ray <matt@opscode.com>
# Cookbook Name:: pxe_dust
# Recipe:: installers
#
# Copyright 2012 Opscode, Inc
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

include_recipe 'apache2'

#location of the full stack installers
directory "/var/www/opscode-full-stack" do
  mode '0755'
end

#loop over the other data bag items here
pxe_dust = data_bag('pxe_dust')
default = data_bag_item('pxe_dust', 'default')
pxe_dust.each do |id|
  image = data_bag_item('pxe_dust', id)
  interface = image['interface'] || default['interface'] || 'eth0'
  platform = image['platform'] || default['platform']
  arch = image['arch'] || default['arch']
  version = image['version'] || default['version']
  environment = image['environment'] || default['environment']
  run_list = image['run_list'] || default['run_list'] || ''
  rlist = run_list.split(',') #for supporting multiple items

  if image['bootstrap']
    http_proxy = image['bootstrap']['http_proxy']
    http_proxy_user = image['bootstrap']['http_proxy_user']
    http_proxy_pass = image['bootstrap']['http_proxy_pass']
    https_proxy = image['bootstrap']['https_proxy']
  elsif default['bootstrap']
    http_proxy = default['bootstrap']['http_proxy']
    http_proxy_user = default['bootstrap']['http_proxy_user']
    http_proxy_pass = default['bootstrap']['http_proxy_pass']
    https_proxy = default['bootstrap']['https_proxy']
  end

  # only get the full stack installers to use
  case version
  when '10.04', '10.10'
    rel_arch = "#{arch =~ /i386/ ? 'i686' : 'x86_64'}"
    release = "ubuntu-10.04-#{rel_arch}"
  when '11.04', '11.10', '12.04'
    rel_arch = "#{arch =~ /i386/ ? 'i686' : 'x86_64'}"
    release = "ubuntu-11.04-#{rel_arch}"
  when '6.0.4'
    version = '6'
    rel_arch = "#{arch =~ /i386/ ? 'i686' : 'x86_64'}"
    release = "debian-6.0.1-#{rel_arch}"
  end

  directory "/var/www/opscode-full-stack/#{release}" do
    mode '0755'
  end

  installer = ''
  location = ''

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
  remote_file "/var/www/opscode-full-stack/#{release}/#{installer}" do
    source location
    mode '0644'
    action :create_if_missing
  end

  #Chef bootstrap script run by new installs
  template "/var/www/#{id}-chef-bootstrap" do
    source 'chef-bootstrap.sh.erb'
    mode '0644'
    variables(
      :release => release,
      :installer => installer,
      :interface => interface,
      :http_proxy => http_proxy,
      :http_proxy_user => http_proxy_user,
      :http_proxy_pass => http_proxy_pass,
      :https_proxy => https_proxy,
      :environment => environment,
      :run_list => rlist
      )
  end

end

#link the validation_key where it can be downloaded
link '/var/www/validation.pem' do
  to Chef::Config[:validation_key]
end

