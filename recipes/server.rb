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

#loop over the other data bag items here
pxe_dust = data_bag('pxe_dust')
default = data_bag_item('pxe_dust', 'default')
pxe_dust.each do |id|
  image = data_bag_item('pxe_dust', id)
  image_dir = "#{node['tftp']['directory']}/#{id}"
  interface = image['interface'] || default['interface'] || 'eth0'
  platform = image['platform'] || default['platform']
  arch = image['arch'] || default['arch']
  domain = image['domain'] || default['domain']
  netboot_url = image['netboot_url'] || default['netboot_url']
  boot_volume_size = image['boot_volume_size'] || default ['boot_volume_size'] || '30GB'
  packages = image['packages'] || default['packages'] || ''
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
      :boot_volume_size => boot_volume_size,
      :packages => packages,
      :user_fullname => user_fullname,
      :user_username => user_username,
      :user_crypted_password => user_crypted_password,
      :root_crypted_password => root_crypted_password
      )
  end

end

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

#generate local mirror of installers
include_recipe "pxe_dust::installers"
#generate local mirror install.sh and bootstrap templates
include_recipe "pxe_dust::bootstrap_template"
