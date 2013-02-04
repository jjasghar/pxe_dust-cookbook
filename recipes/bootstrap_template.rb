# Author:: Matt Ray <matt@opscode.com>
# Cookbook Name:: pxe_dust
# Recipe:: bootstrap_template
#
# Copyright 2012-2013, Opscode, Inc
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

require 'mixlib/shellout'

include_recipe "pxe_dust::installers"

#write out a new pxedust.erb template
remote_file "/var/www/chef-full.erb" do
  source "https://raw.github.com/opscode/chef/master/lib/chef/knife/bootstrap/chef-full.erb"
end

# change URL from
# url="http://www.opscode.com/chef/download?v=${version}&p=${platform}&pv=${platform_version}&m=${machine}"
# to
# url="http://hypnotoad/opscode-full-stack/${platform}-${platform_version}-${machine}/${filename}"
ruby_block "template url" do
  block do
    sed = "sed 's/opscode.com\\/chef\\//"
    sed += "#{node['ipaddress']}\\/opscode-full-stack\\/#{node['hostname']}-/'"
    sed += " /var/www/chef-full.erb"
    Chef::Log.debug sed
    cmd = Mixlib::ShellOut.new(sed)
    output = cmd.run_command
    Chef::Log.debug output.stdout
    nodetemplate = File.new("/var/www/#{node['hostname']}.erb", "w+")
    nodetemplate.puts output.stdout
    nodetemplate.chmod(0644)
  end
  action :nothing
  subscribes :create, resources("remote_file[/var/www/chef-full.erb]")
end

#write out a new install.sh
remote_file "/var/www/opscode-full-stack/original-install.sh" do
  source "http://opscode.com/chef/install.sh"
end

# change URL from
# url="http://www.opscode.com/chef/download?v=${version}&p=${platform}&pv=${platform_version}&m=${machine}"
# to
# url="http://hypnotoad/opscode-full-stack/${platform}-${platform_version}-${machine}/${filename}"
ruby_block "install.sh url" do
  block do
    sed = "sed 's/www.opscode.com\\/chef\\/download?v=${version}&p=${platform}&pv=${platform_version}&m=${machine}/"
    sed += "#{node['ipaddress']}\\/opscode-full-stack\\/${platform}-${platform_version}-${machine}\\/${filename}/'"
    sed += " /var/www/opscode-full-stack/original-install.sh"
    Chef::Log.debug sed
    cmd = Mixlib::ShellOut.new(sed)
    output = cmd.run_command
    Chef::Log.debug output.stdout
    nodeinstall = File.new("/var/www/opscode-full-stack/#{node['hostname']}-install.sh", "w+")
    nodeinstall.puts output.stdout
    nodeinstall.chmod(0644)
  end
  action :nothing
  subscribes :create, resources("remote_file[/var/www/opscode-full-stack/original-install.sh]")
end

#straighten up symlinks for downloading from install.sh
ruby_block "create symlinks that match up with the urls" do
  block do
    Dir.glob("/var/www/opscode-full-stack/*").each do |distro|
      if File.directory?(distro) && !File.symlink?(distro)
        packages = Dir.glob("#{distro}/chef_*")
        versions = []
        packages.each {|x| versions << x.split('/').last.split('-')[0].split('_')[1]}
        versions.uniq.each do |version|
          vpackages = Dir.glob("#{distro}/chef_#{version}-*").sort
          vpackages.each do |filename|
            if !File.symlink?(filename)
              lname = "#{distro}/chef_#{version}_#{filename.split('_').last}"
              fname = "#{filename}"
              ln = "ln -sf #{fname} #{lname}"
              Chef::Log.debug ln
              cmd = Mixlib::ShellOut.new(ln)
              output = cmd.run_command
              Chef::Log.debug output.stdout
            end
          end
        end
      end
    end
  end
end

#create ubuntu 12.04 links if 11.04 is present
link "/var/www/opscode-full-stack/ubuntu-12.04-i686" do
  to "/var/www/opscode-full-stack/ubuntu-11.04-i686"
  ignore_failure #no ubuntu?
end
link "/var/www/opscode-full-stack/ubuntu-12.04-x86_64" do
  to "/var/www/opscode-full-stack/ubuntu-11.04-x86_64"
  ignore_failure #no ubuntu?
end
