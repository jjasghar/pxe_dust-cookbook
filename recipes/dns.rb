# Author:: Matt Ray <matt@opscode.com>
# Cookbook Name:: pxe_dust
# Recipe:: dns
#
# Copyright 2013 Opscode, Inc
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

require 'ipaddr'

# get any mac address and hostname pairs from the data bag
begin
  default = node['pxe_dust']['default']
  pxe_dust = data_bag('pxe_dust')
  default = data_bag_item('pxe_dust', 'default').merge(default)
rescue
  Chef::Log.warn("No 'pxe_dust' data bag found.")
  pxe_dust = []
end
pxe_dust.each do |id|
  # override the defaults with the image values, then override those with node values
  image = default.merge(data_bag_item('pxe_dust', id)).merge(node['pxe_dust']['default'])
  if image['addresses']
    image['addresses'].each do |mac_address, hostname|
      mac = mac_address.downcase
      host = hostname.downcase
      node.override['dnsmasq']['dhcp_options'] = node['dnsmasq']['dhcp_options'].to_a << "dhcp-host=#{mac},#{host}"
    end
  end
end

# add the external hosts file to dns
node.override['dnsmasq']['dhcp_options'] = node['dnsmasq']['dhcp_options'].to_a << "addn-hosts=#{node['pxe_dust']['hosts_file']}"

# pull out the DHCP range and write out a supplemental pxe_dust hosts file for it
hosts_file = "# Generated file managed by Chef\n\n"
if node['dnsmasq']['dhcp']['dhcp-range']
  range = node['dnsmasq']['dhcp']['dhcp-range'].split(',')
  range.each_index do |i|
    if range[i] =~ /^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$/
      start = IPAddr.new(range[i])
      stop = IPAddr.new(range[i+1])
      (start .. stop).each do |ipaddress|
        ip = ipaddress.to_s
        # remove any allocated IPs from the hosts file
        unless node['dnsmasq']['dhcp_options'].find_index {|m| m.end_with?(ip)}
          host_name = "pxe-"+ip.gsub(/\./, '-')
          hosts_file += "#{ip} #{host_name} #{host_name}.#{default['domain']}\n"
        end
      end
      break
    end
  end
end

# write out the external hosts file
file node['pxe_dust']['hosts_file'] do
  content hosts_file
  mode 0644
  notifies :restart, resources(:service => 'dnsmasq')
end
