#
# Cookbook Name:: pxe_dust_test
# Recipe:: common_test.rb
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

describe "pxe_dust_test::common" do
  include Helpers::PxeDustTest

  it 'runs the apache and tftpd-hpa services' do
    service("apache2").must_be_running
  end

  it 'creates the pxe_dust directory' do
    directory(node['pxe_dust']['dir']).must_exist.with(:owner, "root")
  end
end
