script to have a simple Aos linux set up for chrooting
requires root rights for chrooting. 

setsup a small linux (AOS) for chrooted needs.

First part of the script can be run without root access.
It relies of buildaos script of alicia@ion.nu

Second part of the script requires root is still under  testing
It is advisable to run the code as individual codes inside
the chrooted shell.

Install the following:
-vim, perl, zlib, openssl, openssh

Issues + TODO:
-gcc options change when host and compiled arch are different.
-test subshell for the passing other gcc arch option. 
i.e, i386 on a X86_64 host machine. 
-test irssi install.
-include editing grub + fstab.
-mount + rsync to a seperate partition.
-try to trim the the userland .
