# Author:: Matt Ray <matt@opscode.com>
# Cookbook Name:: pxe_dust
# Recipe:: bootstrap_template
#
# Copyright 2012, Opscode, Inc
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

require 'chef/shell_out'

# download the install.sh from Opscode
remote_file "/var/www/opscode-full-stack/original-install.sh" do
  source "http://opscode.com/chef/install.sh"
end

# change URL from
# url="http://www.opscode.com/chef/download?v=${version}&p=${platform}&pv=${platform_version}&m=${machine}"
# to
# url="http://hypnotoad/opscode-full-stack/${platform}-${platform_version}-${machine}/${filename}"
ruby_block "capture sed output and pass to file" do
  block do
    sed = "sed 's/www.opscode.com\\/chef\\/download?v=${version}&p=${platform}&pv=${platform_version}&m=${machine}/"
    sed += "#{node['ipaddress']}\\/opscode-full-stack\\/${platform}-${platform_version}-${machine}\\/${filename}/'"
    sed += " /var/www/opscode-full-stack/original-install.sh"
    Chef::Log.info sed
    cmd = Chef::ShellOut.new(sed)
    output = cmd.run_command
    Chef::Log.info output.stdout
    nodeinstall = File.new("/var/www/opscode-full-stack/#{node['hostname']}-install.sh", "w+")
    nodeinstall.puts output.stdout
    nodeinstall.chmod(0644)
  end
  action :nothing
  subscribes :create, resources("remote_file[/var/www/opscode-full-stack/original-install.sh]")
end

#create an ubuntu 12.04 link

#create symlinks that match up with the urls
#if multiple files that start the same, sort and symlink last

#write out a new chef-full-local.erb template
#`http://NODE/pxedust.erb`
