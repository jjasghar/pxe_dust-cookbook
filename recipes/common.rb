# Author:: Matt Ray <matt@chef.io>
# Author:: JJ Asghar <jj@chef.io>
# Cookbook Name:: pxe_dust
# Recipe:: common
#
# Copyright 2013-2016 Chef Software, Inc
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

template "/etc/apache2/sites-available/pxe_dust.conf" do
  source "pxe_dust.conf.erb"
  owner "root"
  group "root"
  mode "0644"
  notifies :restart, 'service[apache2]', :delayed
end

apache_site 'pxe_dust.conf'

service "apache2" do
  supports :status => true, :restart => true, :truereload => true
  action [ :enable, :start ]
end
