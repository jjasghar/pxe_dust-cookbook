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

  it 'runs the apache and tftpd-hpa services' do
    service("tftpd-hpa").must_be_running
  end

  it 'creates the tftp and pxe_dust directories' do
    assert_directory node['tftp']['directory'], "root", "root", "755"
    assert_directory "#{node['tftp']['directory']}/pxelinux.cfg", "root", "root", "755"
  end

  it 'creates a default pxelinux.cfg' do
    file("#{node['tftp']['directory']}/pxelinux.cfg/default").must_include "append auto=true priority=critical interface=auto vga16fb.modeset=0 initrd=default/12.04-installer/amd64/initrd.gz netcfg/disabledhcp=false locale=en_US console-setup/ask_detect=false console-setup/layoutcode=us netcfg/get_hostname=unknown netcfg/get_domain=testing.pxe netcfg/chooseinterface=auto url=http://<%= node['ipaddress'] %>/default-preseed.cfg DEBCONF_INTERFACE=noninteractive DEBCONF_DEBUG=5"
  end
end
