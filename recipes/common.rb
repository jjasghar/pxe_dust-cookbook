# Author:: Matt Ray <matt@opscode.com>
# Cookbook Name:: pxe_dust
# Recipe:: common
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

include_recipe 'apache2'

directory node['pxe_dust']['dir'] do
  mode 0755
end

directory "#{node['pxe_dust']['dir']}/isos" do
  mode 0755
end

web_app 'pxe_dust' do
  cookbook 'apache2'
  server_name node['hostname']
  server_aliases [node['fqdn']]
  directory_options ['Indexes', 'FollowSymLinks']
  docroot node['pxe_dust']['dir']
end
