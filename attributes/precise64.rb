default['pxe_dust']['models']['ubuntu-precise-amd64'] =
{
    "id" => "ubuntu-precise-amd64",
    "arch" => "amd64",
    "packages" => "bridge-utils lxc",
    "platform" => "ubuntu",
    "version" => "12.04",
    "netboot_url" => "http://archive.ubuntu.com/ubuntu/dists/precise/main/installer-amd64/current/images/netboot/netboot.tar.gz",
    "run_list" => "role[base]",
    "addresses" => {
    }
}
