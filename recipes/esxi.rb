# coding: utf-8
# Author:: JJ Asghar <jj@chef.io>
# Cookbook Name:: pxe_dust
# Recipe:: esxi
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

include_recipe 'pxe_dust::server'

esxi = "/tmp/#{node['pxe_dust']['esxi_iso']}"

directory '/mnt/loop' do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

directory '/srv/install/esxi' do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

directory "#{node['tftp']['directory']}/esxi" do
  mode 0755
end

bash 'mount and copy off files' do
  user 'root'
  cwd '/tmp'
  creates '/var/lib/tftpboot/esxi/a.b00'
  code <<-EOH
    STATUS=0
    mount -o loop -t iso9660 #{esxi} /mnt/loop || STATUS=1
    cp -R /mnt/loop/* #{node['tftp']['directory']}/esxi/ || STATUS=1
    umount /mnt/loop || STATUS=1
    exit $STATUS
  EOH
end

template "#{node['pxe_dust']['dir']}/esxi-ks.cfg" do
  source 'esxi-ks.cfg.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

template "#{node['tftp']['directory']}/esxi/boot.cfg" do
  source 'esxi-boot.cfg.erb'
  owner 'root'
  group 'root'
  mode '0644'
end
