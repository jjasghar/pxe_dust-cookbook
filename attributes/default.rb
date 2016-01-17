#
# Author:: Matt Ray <matt@chef.io>
# Cookbook Name:: pxe_dust
# Attributes:: default
#
# Copyright 2011-2016 Chef Software, Inc
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

default['pxe_dust']['chefversion'] = nil
default['pxe_dust']['dir'] = '/var/www/pxe_dust'
default['pxe_dust']['default'] = {}

default['pxe_dust']['server_name'] = node['hostname']
default['pxe_dust']['server_aliases'] = node['fqdn']
default['pxe_dust']['directory_options'] = 'Indexes FollowSymLinks'
default['pxe_dust']['docroot'] = node['pxe_dust']['dir']

default['pxe_dust']['dhcpd_server'] = true
default['pxe_dust']['dhcpd_interface'] = 'eth1'
default['pxe_dust']['dhcpd_subnet'] = '192.168.10.0'
default['pxe_dust']['dhcpd_netmask'] = '255.255.255.0'
default['pxe_dust']['dhcpd_range'] = '192.168.10.20 192.168.10.100'
default['pxe_dust']['dhcpd_dns'] = '192.168.1.1, 8.8.8.8'
default['pxe_dust']['dhcpd_domain'] = 'example.com'
default['pxe_dust']['dhcpd_gateway'] = '192.168.10.1'
default['pxe_dust']['dhcpd_broadcast'] = '192.168.10.255'
default['pxe_dust']['dhcpd_lease_time'] = '600'
default['pxe_dust']['dhcpd_max_lease_time'] = '7200'
default['pxe_dust']['dhcpd_next_server'] = '192.168.10.1'

default['pxe_dust']['esxi_iso'] = 'VMware-VMvisor-Installer-6.0.0.update01-3029758.x86_64.iso'
