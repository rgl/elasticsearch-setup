This directory contains the files needed to create the elasticsearch setup
program for Windows.

You first need to install Unicode Inno Setup (the QuickStart Pack) from:

    http://www.jrsoftware.org/isdl.php#qsp

NB Get the ispack-5.4.0-unicode.exe file.

And then MinGW and msys by following the guide at:

    http://blog.ruilopes.com/post/2143557964/sane-shell-environment-on-windows

You should now be ready to build the setup with:

    make

It should create two files with the name pattern:

  elasticsearch-VERSION-setup-NN-bit.exe

These are the only files that need to be redistributed.

NB If the above step complains about a missing unzip.exe or wget.exe, you
   can install them with:

        mingw-get install msys-unzip
        mingw-get install msys-wget

The setup uses SetACL.exe to grant NTFS file permissions to the
elasticsearch account. SetACL can be download from:

    http://helgeklein.com/setacl/

The setup uses procrun.exe to launch elasticsearch as a Windows service.
procrun is included in the Apache Commons Daemon project available at:

    http://commons.apache.org/daemon/
