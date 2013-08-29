# Author:: Matt Ray <matt@opscode.com>
# Cookbook Name:: pxe_dust
# Recipe:: server
#
# Copyright 2011-2013 Opscode, Inc
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

include_recipe 'tftp::server'
include_recipe 'pxe_dust::common'

#search for any apt-cacher-ng caching proxies
if Chef::Config[:solo]
  Chef::Log.warn('This recipe uses search. Chef Solo does not support search.')
  proxy = '#d-i mirror/http/proxy string url'
else
  query = "apt_caching_server:true"
  query += " AND chef_environment:#{node.chef_environment}" if node['apt']['cacher-client']['restrict_environment']
  Chef::Log.debug("pxe_dust::server searching for '#{query}'")
  servers = search(:node, query) || []
  if servers.length > 0
    proxy = "d-i mirror/http/proxy string http://#{servers[0].ipaddress}:#{servers[0]['apt']['cacher_port']}"
  else
    proxy = '#d-i mirror/http/proxy string url'
  end
end

directory "#{node['tftp']['directory']}/pxelinux.cfg" do
  mode 0755
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
  image_dir = "#{node['tftp']['directory']}/#{id}"
  # override the defaults with the image values, then override those with node values
  image = default.merge(data_bag_item('pxe_dust', id)).merge(node['pxe_dust']['default'])

  platform = image['platform']
  arch = image['arch']
  version = image['version']

  unless arch.eql?('ppc') #ppc is dealt with in yaboot.rb
    if image['user']
      user_fullname = image['user']['fullname']
      user_username = image['user']['username']
      user_crypted_password = image['user']['crypted_password']
    end
    if image['root']
      root_crypted_password = image['root']['crypted_password']
    end

    directory image_dir do
      mode 0755
    end

    #local mirror for netboots
    remote_file "#{node['pxe_dust']['dir']}/isos/#{platform}-#{version}-#{arch}-netboot.tar.gz" do
      source image['netboot_url']
      action :create_if_missing
    end

    #populate the netboot contents
    execute "tar -xzf #{node['pxe_dust']['dir']}/isos/#{platform}-#{version}-#{arch}-netboot.tar.gz" do
      cwd image_dir
      not_if { Dir.entries(image_dir).length > 2 }
    end

    link "#{node['tftp']['directory']}/pxe-#{id}.0" do
      to "#{id}/pxelinux.0"
    end

    if image['addresses']
      image['addresses'].keys.each do |mac_address|
        mac = mac_address.gsub(/:/, '-')
        mac.downcase!
        template "#{node['tftp']['directory']}/pxelinux.cfg/01-#{mac}" do
          source 'pxelinux.cfg.erb'
          mode 0644
          variables(
            :platform => platform,
            :id => id,
            :interface => image['interface'] || 'eth0',
            :arch => arch || 'amd64',
            :domain => image['domain'],
            :hostname => image['addresses'][mac_address],
            :preseed => image['external_preseed'].nil? ? "#{id}-preseed.cfg" : image['external_preseed']
            )
        end
      end
    end

    template "#{node['pxe_dust']['dir']}/#{id}-preseed.cfg" do
      only_if { image['external_preseed'].nil? }
      source "#{platform}-preseed.cfg.erb"
      mode 0644
      variables(
        :id => id,
        :proxy => proxy,
        :boot_volume_size => image['boot_volume_size'] || '30GB',
        :packages => image['packages'] || '',
        :user_fullname => user_fullname,
        :user_username => user_username,
        :user_crypted_password => user_crypted_password,
        :root_crypted_password => root_crypted_password,
        :halt => image['halt'] || false,
        :bootstrap => image['chef'] || true
        )
    end

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
    :platform => default['platform'] || '12.04',
    :id => 'default',
    :interface => default['interface'] || 'auto',
    :arch => default['arch'] || 'amd64',
    :domain => default['domain'],
    :hostname => 'unknown',
    :preseed => default['external_preseed'] || 'default-preseed.cfg'
    )
end

#generate local mirror of installers
include_recipe "pxe_dust::installers"
#generate local mirror install.sh and bootstrap templates
include_recipe "pxe_dust::bootstrap_template"
