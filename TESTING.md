This cookbook includes support for running tests via Test Kitchen (1.4) and the Chef DK. This has some requirements.

1. You must be using the Git repository, rather than the downloaded cookbook from the Chef Supermarket.
1. You must have ChefDK installed.

Once the above requirements are met:

    chef exec kitchen list
    chef exec kitchen test

This cookbook has the following Test-Kitchen coverage:

| Test Coverage      | Ubuntu 12.04  | Ubuntu 14.04 | Debian 7.1 |
| ------------------ |:-------------:|:------------:|:----------:|
| common             | **Y**         | **Y**        | **N**      |
| server             | **Y**         | **Y**        | **N**      |
| installers         | **Y**         | **Y**        | **N**      |
| bootstrap_template | **Y**         | **Y**        | **N**      |
