site :opscode

metadata

cookbook "apt", "2.2.0"
cookbook "dnsmasq", git: "https://github.com/mattray/dnsmasq", branch: "0.2.0"

group :integration do
  cookbook "minitest-handler"
  cookbook "pxe_dust_test", :path => "./test/cookbooks/pxe_dust_test"
end
