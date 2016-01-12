require 'spec_helper'

describe 'pxe_dust::server' do
  # Serverspec examples can be found at
  # http://serverspec.org/resource_types.html

  describe file('/var/lib/tftpboot/pxelinux.cfg') do
    it { should exist }
  end

  describe file('/var/lib/tftpboot/default') do
    it { should exist }
    it { should be_directory }
  end

  describe process('in.tftpd') do
    its(:user) { should eq 'root' }
    it { should be_running }
  end

  describe process('isc-dhcp-server') do
    its(:user) { should eq 'root' }
    it { should be_running }
  end

  describe process('apache2') do
    its(:user) { should eq 'root' }
    it { should be_running }
  end

  describe port(80) do
    it { should be_listening }
  end

  describe file('/var/www/pxe_dust') do
    it { should exist }
    it { should be_directory }
  end

  describe file('/etc/dhcp/') do
    it { should exist }
    it { should be_directory }
  end

  describe file('/etc/dhcp/dhcpd.conf') do
    it { should exist }
  end

  describe file('/var/www/pxe_dust/isos') do
    it { should exist }
    it { should be_directory }
  end

  describe file('/var/www/pxe_dust/chef-full.erb') do
    it { should exist }
  end

  describe file('/etc/apache2/sites-available/pxe_dust.conf') do
    it { should exist }
    its(:content) { should match /DocumentRoot \/var\/www\/pxe_dust/ }
  end
end
