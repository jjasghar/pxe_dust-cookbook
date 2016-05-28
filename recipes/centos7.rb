# Author:: JJ Asghar <jj@chef.io>
# Cookbook Name:: pxe_dust
# Recipe:: centos7
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

centos7 = Chef::Config[:file_cache_path] + '/CentOS-7-x86_64-Minimal-1511.iso'

package 'nfs-kernel-server' do
  action :install
end

directory "/srv/install" do
  owner "root"
  group "root"
  mode "0755"
  action :create
end

template "/etc/exports" do
  source "exports.erb"
  owner "root"
  group "root"
  mode "0644"
  notifies :restart, 'service[nfs-kernel-server]', :immediately
end

service "nfs-kernel-server" do
  supports :status => true, :restart => true, :truereload => true
  action [ :enable, :start ]
end

remote_file centos7 do
  owner "root"
  group "root"
  mode "0644"
  source "#{node['pxe_dust']['centos7']['iso_mirror']}"
  action :create
end

directory "/mnt/centosloop" do
  owner "root"
  group "root"
  mode "0755"
  action :create
end

directory "/srv/install" do
  owner "root"
  group "root"
  mode "0755"
  action :create
end

directory "/srv/install/centos7" do
  owner "root"
  group "root"
  mode "0755"
  action :create
end

directory "#{node['tftp']['directory']}/centos7" do
  mode 0755
end

bash "mount and copy off files" do
  user "root"
  cwd "/tmp"
  creates "maybe"
  code <<-EOH
    STATUS=0
    mount -o loop -t iso9660 #{centos7} /mnt/centosloop || STATUS=1
    cp /mnt/centosloop/images/pxeboot/vmlinuz #{node['tftp']['directory']}/centos7/  || STATUS=1
    cp /mnt/centosloop/images/pxeboot/upgrade.img #{node['tftp']['directory']}/centos7/  || STATUS=1
    cp /mnt/centosloop/images/pxeboot/initrd.img #{node['tftp']['directory']}/centos7/  || STATUS=1
    cp -R /mnt/centosloop/* /srv/install/centos7/ || STATUS=1
    mkdir /var/www/pxe_dust/centos7
    cp -R /mnt/centosloop/* /var/www/pxe_dust/centos7/ || STATUS=1
    umount /mnt/centosloop || STATUS=1
    exit $STATUS
  EOH
end

template "#{node['pxe_dust']['dir']}/centos7-ks.cfg" do
  source "centos7-ks.cfg.erb"
  owner "root"
  group "root"
  mode "0644"
end
