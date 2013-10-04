#
# Cookbook Name:: pxe_dust_test
# Recipe:: server
#
# Copyright 2013, Opscode, Inc.
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

node.default['pxe_dust']['default']['domain'] = 'testing.pxe'
node.default['dnsmasq']['enable_dhcp'] = true

node.default['dnsmasq']['dhcp'] = {
  'dhcp-range' => 'eth1,10.0.0.5,10.0.0.15,12h',
  'domain' => 'test.lab',
  'tftp-root' => '/var/lib/tftpboot'
}

node.default['dnsmasq']['dhcp_options'] = ['dhcp-host=01:23:ab:cd:01:02,larry,10.0.0.10']

include_recipe "pxe_dust::server"
