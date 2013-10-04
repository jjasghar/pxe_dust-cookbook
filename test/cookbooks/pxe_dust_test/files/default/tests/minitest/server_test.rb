#
# Cookbook Name:: pxe_dust_test
# Recipe:: server_test.rb
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

require File.expand_path('../support/helpers', __FILE__)

describe "pxe_dust_test::server" do
  include Helpers::PxeDustTest

  it 'runs the dnsmasq service' do
    service("dnsmasq").must_be_running
  end

  it 'creates the tftp and pxe_dust directories' do
    directory(node['dnsmasq']['dhcp']['tftp-root']).must_exist.with(:owner, node['dnsmasq']['user'])
    directory("#{node['dnsmasq']['dhcp']['tftp-root']}/pxelinux.cfg").must_exist.with(:owner, node['dnsmasq']['user'])
  end

  it 'creates a default pxelinux.cfg' do
    file("#{node['dnsmasq']['dhcp']['tftp-root']}/pxelinux.cfg/default").must_include node['pxe_dust']['default']['domain']
  end

  #dns stuff
  it 'should have the pxe_hosts_file' do
    file(node['pxe_dust']['hosts_file']).must_have(:mode, '644')
    file(node['pxe_dust']['hosts_file']).must_match /^10.0.0.5 pxe-10-0-0-5 pxe-10-0-0-5.testing.pxe$/
    file(node['pxe_dust']['hosts_file']).wont_match /^10.0.0.10 pxe-10-0-0-10 pxe-10-0-0-10.test.pxe$/
  end

end
