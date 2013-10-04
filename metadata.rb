name             "pxe_dust"
maintainer       "Opscode, Inc."
maintainer_email "cookbooks@opscode.com"
license          "Apache 2.0"
description      "Configures local bootstrapping and installing operating systems via PXE booting."
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "2.0.0"
depends          "apache2", ">= 1.6"
depends          "dnsmasq", ">= 0.2"
recommends       "apt", ">= 2.2"

%w{ ubuntu debian }.each do |os|
  supports os
end
