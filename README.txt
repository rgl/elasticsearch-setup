Download the binaries from:

  http://ruilopes.com/elasticsearch-setup/

------

This directory contains the files needed to create the elasticsearch setup
program for Windows.

You first need to install Unicode Inno Setup from:

    http://www.jrsoftware.org/isdl.php#stable

NB Get the isetup-5.5.4-unicode.exe file.

And then, only, msys from MinGW by following the guide at:

    http://blog.ruilopes.com/post/2143557964/sane-shell-environment-on-windows

And then install the TDM64 bundle from:

    http://tdm-gcc.tdragon.net/

And add everything into your PATH.

You should now be ready to build the setup with:

    make

It should create two files with the name pattern:

  elasticsearch-VERSION-setup-NN-bit.exe

These are the only files that need to be redistributed.

NB If the above step complains about a missing unzip.exe or wget.exe, you
   can install them with:

        mingw-get install msys-unzip
        mingw-get install msys-wget


The setup will do the following when installing the application:

 * install all files into Program Files (the user can change the
   actual location)

 * create the elasticsearch Windows account (with Logon as service
   privilege)

 * install a Windows Service to automatically start elasticsearch
   (run as the elasticsearch account) at boot (but has to be manually
   started after install...).

 * grant the elasticsearch account:
     * read permissions to the "config" directory.
     * full permissions to the "data" and "logs" directories.

 * create a bunch of Start Menu entries (link to home page, guide, etc).


The setup uses SetACL.exe to grant NTFS file permissions to the
elasticsearch account. SetACL can be download from:

    http://helgeklein.com/setacl/

The setup uses procrun.exe to launch elasticsearch as a Windows service.
procrun is included in the Apache Commons Daemon project available at:

    http://commons.apache.org/daemon/

