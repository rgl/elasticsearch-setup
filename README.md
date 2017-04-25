# Elasticsearch Setup

This is a setup application for installing [Elasticsearch](https://www.elastic.co/products/elasticsearch)
on a Windows machine.

The setup will:

 * install all files into `Program Files` (the user can change the
   actual location)

 * create the `elasticsearch` Windows account (with
   `Logon as service privilege`)

 * install a Windows Service to automatically start `elasticsearch`
   (run as the `elasticsearch` account) at boot (but has to be manually
   started after install...).

 * grant the `elasticsearch` account:
     * read permissions to the `config` directory.
     * full permissions to the `data` and `logs` directories.

 * create a bunch of Start Menu entries (link to home page, guide, etc).


If you need to modify any service related setting (e.g. the maximum
memory used by the JVM) edit the file:

    lib\elasticsearchw-update.cmd

And then run it in a Administrator Command Prompt.

## Silent installation

You can do a silent install with the `/VERYSILENT /SUPPRESSMSGBOXES` command
line arguments. For more information see the `install elasticsearch` section
inside the [Vagrantfile-provision.ps1](Vagrantfile-provision.ps1) file.

# Development

The setup is created inside a Vagrant environment. To create the
environment install:

 * [Vagrant](https://www.vagrantup.com/)
 * [VirtualBox](https://www.virtualbox.org/)
 * [Windows Base Box](https://github.com/rgl/windows-2016-vagrant)

Then run `vagrant up`. The setup executable should appear on the
same directory as this README file.
