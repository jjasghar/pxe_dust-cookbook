# Author:: JJ Asghar <jj@chef.io>
# Cookbook Name:: pxe_dust
# Recipe:: dhcpd
#
# Copyright 2016 Chef Software, Inc
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

package 'isc-dhcp-server' do
  action :install
end

template '/etc/default/isc-default-server' do
  source 'isc-default-server.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

template '/etc/dhcp/dhcpd.conf' do
  source 'dhcpd.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
  notifies :restart, 'service[isc-dhcp-server]', :delayed
end

service 'isc-dhcp-server' do
  supports status: true, restart: true, truereload: true
  action [:enable, :start]
end
