require 'spec_helper'

describe 'pxe_dust::common' do
  # Serverspec examples can be found at
  # http://serverspec.org/resource_types.html

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

  describe file('/var/www/pxe_dust/isos') do
    it { should exist }
    it { should be_directory }
  end

  describe file('/etc/apache2/sites-available/pxe_dust.conf') do
    it { should exist }
    its(:content) { should match /DocumentRoot \/var\/www\/pxe_dust/ }
  end




end
