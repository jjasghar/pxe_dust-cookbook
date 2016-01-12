require 'spec_helper'

describe 'minecraft-basic::default' do
  # Serverspec examples can be found at
  # http://serverspec.org/resource_types.html

  describe file('/usr/share/minecraft/minecraft_server.jar') do
    it { should exist }
  end

  describe file('/usr/share/minecraft/eula.txt') do
    its(:content) { should match /true/ }
    it { should exist }
  end

  describe file('/usr/share/minecraft/server.properties') do
    its(:content) { should match /Chef/ }
    it { should exist }
  end

  describe process('java') do
    its(:user) { should eq 'root' }
    it { should be_running }
  end

  describe port(25_565) do
    it { should be_listening }
  end

  if os[:family] == 'redhat'
    describe file('/usr/lib/systemd/system/minecraft.service') do
      its(:content) { should match /minecraft/ }
      it { should exist }
    end

  elsif %w(debian ubuntu).include?(os[:family])
    describe file('/etc/init/minecraft-server.conf') do
      its(:content) { should match /minecraft/ }
      it { should exist }
    end
  end
end
