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

class ::Chef::Recipe
  include ::Apt
end

include_recipe "dnsmasq::default"
include_recipe 'pxe_dust::common'

#search for any apt-cacher-ng caching proxies
if Chef::Config[:solo]
  Chef::Log.warn('This recipe uses search. Chef Solo does not support search.')
  proxy = '#d-i mirror/http/proxy string url'
else
  query = "apt_caching_server:true"
  if node['apt']['cacher-client'] && node['apt']['cacher-client']['restrict_environment']
    query += " AND chef_environment:#{node.chef_environment}"
  end
  Chef::Log.debug("pxe_dust::server searching for '#{query}'")
  servers = search(:node, query) || []
  if servers.length > 0
    if servers[0]['apt']['cacher_interface']
      cacher_ipaddress = interface_ipaddress(servers[0], node['apt']['cacher_interface'])
    else
      cacher_ipaddress = servers[0].ipaddress
    end
    proxy = "d-i mirror/http/proxy string http://#{cacher_ipaddress}:#{servers[0]['apt']['cacher_port']}"
  else
    proxy = '#d-i mirror/http/proxy string url'
  end
end

directory "#{node['dnsmasq']['dhcp']['tftp-root']}/pxelinux.cfg" do
  owner node['dnsmasq']['user']
  mode 0755
end

if node['pxe_dust']['interface']
  server_ipaddress = interface_ipaddress(node, node['pxe_dust']['interface'])
else
  server_ipaddress = node.ipaddress
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
  image_dir = "#{node['dnsmasq']['dhcp']['tftp-root']}/#{id}"
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
      owner node['dnsmasq']['user']
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
      user node['dnsmasq']['user']
      not_if { Dir.entries(image_dir).length > 2 }
    end

    link "#{node['dnsmasq']['dhcp']['tftp-root']}/pxe-#{id}.0" do
      to "#{id}/pxelinux.0"
      owner node['dnsmasq']['user']
    end

    if image['addresses']
      image['addresses'].each do |mac_address, hostname|
        mac = mac_address.downcase.gsub(/:/, '-')
        template "#{node['dnsmasq']['dhcp']['tftp-root']}/pxelinux.cfg/01-#{mac}" do
          source 'pxelinux.cfg.erb'
          owner node['dnsmasq']['user']
          mode 0644
          variables(
            :server_ipaddress => server_ipaddress,
            :platform => platform,
            :id => id,
            :interface => image['interface'] || 'eth0',
            :arch => arch || 'amd64',
            :domain => image['domain'],
            :hostname => hostname.downcase,
            :preseed => image['external_preseed'].nil? ? "#{id}-preseed.cfg" : image['external_preseed']
            )
        end
      end
    end

    # preseed file
    template "#{node['pxe_dust']['dir']}/#{id}-preseed.cfg" do
      only_if { image['external_preseed'].nil? }
      source "#{platform}-preseed.cfg.erb"
      mode 0644
      variables(
        :server_ipaddress => server_ipaddress,
        :id => id,
        :proxy => proxy,
        :boot_volume_size => image['boot_volume_size'] || '30GB',
        :packages => image['packages'] || '',
        :user_fullname => user_fullname,
        :user_username => user_username,
        :user_crypted_password => user_crypted_password,
        :root_crypted_password => root_crypted_password,
        :pause => image['pause'] || false,
        :halt => image['halt'] || false,
        :poweroff => image['poweroff'] || false,
        :bootstrap => image['chef'] || true
        )
    end

    # /etc/network/interfaces
    template "#{node['pxe_dust']['dir']}/#{id}-interfaces" do
      source "interfaces.erb"
      mode 0644
      variables(
        :content => image['interfaces']
        )
      only_if { image['interfaces'] }
    end

    # /etc/udev/rules.d/70-persistent-net.rules
    template "#{node['pxe_dust']['dir']}/#{id}-persistent-net.rules" do
      source "persistent-net.rules.erb"
      mode 0644
      variables(
        :interface => image['interface'] || 'eth0',
        )
      only_if { image['interfaces'] }
    end

  end
end

#configure the defaults
link "#{node['dnsmasq']['dhcp']['tftp-root']}/pxelinux.0" do
  to 'default/pxelinux.0'
  owner node['dnsmasq']['user']
end

template "#{node['dnsmasq']['dhcp']['tftp-root']}/pxelinux.cfg/default"  do
  source 'pxelinux.cfg.erb'
  owner node['dnsmasq']['user']
  mode 0644
  variables(
    :server_ipaddress => server_ipaddress,
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
include_recipe "pxe_dust::dns"
