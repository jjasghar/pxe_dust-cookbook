#
# Cookbook Name:: pxe_dust_test
# Recipe:: bootstrap_template_test.rb
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

describe "pxe_dust_test::bootstrap_template" do
  include Helpers::PxeDustTest
  it 'creates the chef-full.erb and original-install.sh' do
    file("#{node['pxe_dust']['dir']}/chef-full.erb").must_exist
    file("#{node['pxe_dust']['dir']}/original-install.sh").must_exist
  end

end
