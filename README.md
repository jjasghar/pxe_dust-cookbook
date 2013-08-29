Description
===========

This cookbook handles local bootstrapping and PXE booting life cycle with 3 recipes:

* **server**: Configures a tftpd server for serving Ubuntu and Debian installers over PXE.
* **installers**: Downloads the Chef full stack installers and writes out Chef bootstraps.
* **bootstrap_template**: Builds a template for use with `knife` to take advantage of the locally mirrored content.

Requirements
============

Requires Chef 10.12 or later since it now uses the full-chef installer.

## Platform:

Please refer to the [TESTING file](TESTING.md) to see the currently (and passing) tested platforms. The release was tested on:
* Ubuntu 10.04
* Ubuntu 12.04
* Ubuntu 13.04
* Debian 6.0-7.1 (have with manual testing)

## Cookbooks:

Required: apache2, tftp

Optional (recommended): apt (for `recipe[apt::cacher-ng]`).

DO NOT USE `chef-client::delete-validator` in conjunction with this cookbook, since it uses the validation.pem to help bootstrap new machines.

pxe_dust Data Bag
=================

In order to manage configuration of machines registering themselves with their Chef Server or Opscode Hosted Chef, we will use the `pxe_dust` data bag.

```
% knife data bag create pxe_dust
% knife data bag from file pxe_dust examples/default.json
```

Here is an example of the default.json:

```json
{
    "id": "default",
    "platform": "ubuntu",
    "arch": "amd64",
    "version": "12.04",
    "user": {
        "fullname": "Ubuntu",
        "username": "ubuntu",
        "crypted_password": "$6$Trby4Y5R$bi90k7uYY5ImXe5MWGFW9kel2BnMCcYO9EnwngTFIXKG2/nWcLKTJZ3verMFnpFbITI9.eHwZ.HR1UPeKbCAV1"
    }
}
```

Any settings provided by the data bag may be overridden by setting `['pxe_dust']['default']` attributes, for example:

    node['pxe_dust']['default']['environment'] = 'qa'

Here are currently supported options available for inclusion in the example `default.json`:

* `platform`: OS platform for the installer, (ie. 'ubuntu' or 'debian').
* `arch`: Architecture of the netboot.tar.gz to use as the source of pxeboot images, default is 'amd64'.
* `interface`: Which interface to install from, default is 'auto'.
* `version`: Ubuntu version of the netboot.tar.gz to use as the source of pxeboot images and full stack clients, default is '12.04'.
* `domain`: Default domain for nodes, default is none.
* `boot_volume_size`: Size of the LVM boot volume to create, default is '30GB'.
* `packages`: Additional operating system packages to add to the preseed file, default is none.
* `run_list`: Run list for nodes, this value is NOT set as a default and will be passed to all boot types unless explicitly overwritten.
* `environment`: Environment for nodes, this value is NOT set as a default and will be passed to all boot types unless explicitly overwritten.
* `netboot_url`: URL of the netboot image to use for OS installation.
* `bootstrap`: Optional additional bootstrapping configuration.
    `http_proxy`: HTTP proxy, default is none.
    `http_proxy_user`: HTTP proxy user, default is none.
    `http_proxy_pass`: HTTP proxy pass, default is none.
    `https_proxy`: HTTPS proxy, default is none.
* `chef`: Whether or not to bootstrap the node with Chef, default is 'true'.
* `halt`: Whether to wait for user input at end of bootstrap, default is 'false'.
* `user`:
    `crypted_password`: SHA512 password for the default user, default 'ubuntu'. This may be generated and added to the data bag.
    `fullname`: Full name of the default user, default 'Ubuntu'.
    `username`: Username of the default user, default 'ubuntu'.
* `root`:
    `crypted_password`: SHA512 password for the root user, default 'ubuntu'. This is used on Debian since Ubuntu does not have a root.
* `external_preseed`: Direct pxeboot clients to an existing (unmanaged by pxe_dust) preseed file.

Additional data bag items may be used to support booting multiple operating systems. Examples of various Ubuntu and Debian installations are included in the `examples` directory. Important to note is the use of the `addresses` option to support tftp booting by MAC address (this is currently required for not using the default) and the explicit need for a `run_list` and/or an `environment` if one is to be provided.

Templates
=========

pxelinux.cfg.erb
-----------

Sets the URL to the preseed file, architecture, the domain and which interfaces to use.

preseed.cfg.erb
---------------

The preseed file is full of opinions mostly exposed via attributes, you will want to update this. If there is a node providing an apt-cacher-ng caching proxy via `recipe[apt::cacher-ng]`, it is provided in the preseed.cfg. The initial user and password is configured and any additional required packages may be added to the `pxe_dust` data bag items. The preseed finishes by calling the `chef-bootstrap` script.

chef-bootstrap.sh.erb
---------------------

This is the `preseed/late_command` that bootstraps the node with Chef via the full stack installer.

Recipes
=======

default
-------

The default recipe includes recipe `pxe_dust::server`.

server
------

`recipe[pxe_dust::server]` includes the `apache2`, `tftp::server` and `pxe_dust::bootstrap_template` recipes.

The recipe does the following:

1. Downloads the proper netboot.tar.gzs to boot from.
2. Untars them to the `['tftp']['directory']` directory.
3. Instructs the installer prompt to automatically install.
4. Passes the URL of the preseed.cfgs to the installer.
5. Uses the preseed.cfg template to pass in any `apt-cacher-ng` caching proxies or other additional settings.

installers
----------

Downloads the full stack installers listed in the `pxe_dust` data bag and writes out the Chef bootstrap templates for the initial chef-client run connecting to the Chef server.

bootstrap_template
------------------

This recipe creates a bootstrap template that uses a local `install.sh` that uses the cached full stack installers from the `installers` recipe. It may then be downloaded from `http://NODE/NODE.erb` and put in your `.chef/bootstrap/` directory for use with `knife`. You may also use the `http://NODE/NODE-install.sh` if you want a local `install.sh`, perhaps for use with [https://github.com/schisamo/vagrant-omnibus](vagrant-omnibus)'s `OMNIBUS_INSTALL_URL` setting.

Usage
=====

Add `recipe[pxe_dust::server]` to a node's or role's run list. Create the `pxe_dust` data bag and update the `defaults.json` item before adding it.

On an Ubuntu system, the password can be generated by installing the `mkpasswd` package and running:

    mkpasswd -m sha-512

The default is the hash of the password `ubuntu`, if you'd like to test. This must be set in the `pxe_dust` data bag to a valid sha-512 hash of the password or you will not be able to log in.

This cookbook does not provide DHCP or bootp to listen for PXE boot requests, this URL will have to be provided by another cookbook or manually. The author had to do this manually on a DD-WRT router.

Side note, for DD-WRT bootp support [this forum post was followed](http://www.dd-wrt.com/phpBB2/viewtopic.php?t=4662). The key syntax was

    dhcp-boot=pxelinux.0,,192.168.1.147

in the section `Additional DNSMasq Options` where the IP address is that of the tftpd server we're configuring here and pxelinux.0 is from the netboot tarball.

If you do not need PXE booting, you may still want to use the `pxe_dust::installers` and `pxe_dust::bootstrap_template` for bootstrapping nodes (like with LXC or Vagrant).

Attributes
==========

`node['pxe_dust']['chefversion']` the Chef version that pxe_dust should provide, unset by default which downloads latest
`node['pxe_dust']['dir']` the location where apache will serve pxe_dust content, default is '/var/www/pxe_dust'
`node['pxe_dust']['default']` attributes that may be used to override any settings provided by the `pxe_dust` data bag items

License and Author
==================

|                      |                                        |
|:---------------------|:---------------------------------------|
| **Author**           | Matt Ray (<matt@opscode.com>)          |
| **Author**           | Joshua Timberman <joshua@opscode.com>  |
|                      |                                        |
| **Copyright**        | Copyright (c) 2011-2013, Opscode, Inc. |

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
