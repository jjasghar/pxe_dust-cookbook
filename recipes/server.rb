# Author:: Matt Ray <matt@opscode.com>
# Cookbook Name:: pxe_dust
# Recipe:: server
#
# Copyright 2011-2012 Opscode, Inc
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
include_recipe 'tftp::server'

#search for any apt-cacher-ng caching proxies
if Chef::Config[:solo]
  Chef::Log.warn('This recipe uses search. Chef Solo does not support search.')
  proxy = '#d-i mirror/http/proxy string url'
else
  servers = search(:node, 'recipes:apt\:\:cacher-ng') || []
  if servers.length > 0
    proxy = "d-i mirror/http/proxy string http://#{servers[0].ipaddress}:3142"
  else
    proxy = '#d-i mirror/http/proxy string url'
  end
end

directory "#{node['tftp']['directory']}/pxelinux.cfg" do
  mode '0755'
end

#location of the full stack installers
directory "/var/www/opscode-full-stack" do
  mode '0755'
end

#loop over the other data bag items here
pxe_dust = data_bag('pxe_dust')
default = data_bag_item('pxe_dust', 'default')
pxe_dust.each do |id|
  image = data_bag_item('pxe_dust', id)
  image_dir = "#{node['tftp']['directory']}/#{id}"
  interface = image['interface'] || default['interface'] || 'eth0'
  arch = image['arch'] || default['arch']
  domain = image['domain'] || default['domain']
  version = image['version'] || default['version']
  netboot_url = image['netboot_url'] || default['netboot_url']
  packages = image['packages'] || default['packages'] || ''
  run_list = image['run_list'] || default['run_list'] || ''
  rlist = run_list.split(',') #for supporting multiple items
  environment = image['environment'] || default['environment']
  external_preseed = image['external_preseed'] || nil
  preseed = external_preseed.nil? ? "#{id}-preseed.cfg" : external_preseed

  if image['user']
    user_fullname = image['user']['fullname']
    user_username = image['user']['username']
    user_crypted_password = image['user']['crypted_password']
  elsif default['user']
    user_fullname = default['user']['fullname']
    user_username = default['user']['username']
    user_crypted_password = default['user']['crypted_password']
  end
  if image['root']
    root_crypted_password = image['root']['crypted_password']
  elsif default['root']
    root_crypted_password = default['root']['crypted_password']
  end
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

  directory image_dir do
    mode '0755'
  end

  #local mirror for netboots
  remote_file "/var/www/#{id}-netboot.tar.gz" do
    source netboot_url
    action :create_if_missing
  end

  #populate the netboot contents
  execute "tar -xzf /var/www/#{id}-netboot.tar.gz" do
    cwd image_dir
    not_if { Dir.entries(image_dir).length > 2 }
  end

  link "#{node['tftp']['directory']}/pxe-#{id}.0" do
    to "#{id}/pxelinux.0"
  end

  if image['addresses']
    mac_addresses = image['addresses'].keys
  else
    mac_addresses = []
  end

  # only get the full stack installers in use
  case version
  when '10.04', '10.10'
    platform = 'ubuntu'
    rel_arch = "#{arch =~ /i386/ ? 'i686' : 'x86_64'}"
    release = "ubuntu-10.04-#{rel_arch}"
  when '11.04', '11.10', '12.04'
    platform = 'ubuntu'
    rel_arch = "#{arch =~ /i386/ ? 'i686' : 'x86_64'}"
    release = "ubuntu-11.04-#{rel_arch}"
  when '6.0.4'
    platform = 'debian'
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

  mac_addresses.each do |mac_address|
    mac = mac_address.gsub(/:/, '-')
    mac.downcase!
    template "#{node['tftp']['directory']}/pxelinux.cfg/01-#{mac}" do
      source 'pxelinux.cfg.erb'
      mode '0644'
      variables(
        :platform => platform,
        :id => id,
        :interface => interface,
        :arch => arch,
        :domain => domain,
        :hostname => image['addresses'][mac_address],
        :preseed => preseed
        )
    end
  end

  template "/var/www/#{id}-preseed.cfg" do
    only_if { external_preseed.nil? }
    source "#{platform}-preseed.cfg.erb"
    mode '0644'
    variables(
      :id => id,
      :proxy => proxy,
      :packages => packages,
      :user_fullname => user_fullname,
      :user_username => user_username,
      :user_crypted_password => user_crypted_password,
      :root_crypted_password => root_crypted_password
      )
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

#generate local mirror install.sh and bootstrap templates
include_recipe "pxe_dust::bootstrap_template"

#configure the defaults
link "#{node['tftp']['directory']}/pxelinux.0" do
  to 'default/pxelinux.0'
end

template "#{node['tftp']['directory']}/pxelinux.cfg/default"  do
  source 'pxelinux.cfg.erb'
  mode '0644'
  variables(
    :platform => default['platform'],
    :id => 'default',
    :interface => default['interface'] || 'auto',
    :arch => default['arch'],
    :domain => default['domain'],
    :hostname => 'unknown',
    :preseed => default['external_preseed'] || 'default-preseed.cfg'
    )
end

#link the validation_key where it can be downloaded
link '/var/www/validation.pem' do
  to Chef::Config[:validation_key]
end
