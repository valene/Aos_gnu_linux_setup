#!/bin/bash


usage () {
	echo "Usage : ${0} [OPTIONS]"
	echo "-h,--help		= display help "
	echo "-d,--dir	/path/to/directory     "
	echo "-i,--noninteractive = autokernel config"
	echo "-l,--linuxconfig /path/to/kernelconfigfile"
	echo "-a,--arch = cpu arch; defaul i586"
	exit 0
}

error2exit () {
	echo "Error code : $1"
	exit 1
}

[[ -z $1 ]] || [[ "$1" = "-h" ]] || [[ "$1" = "--help" ]] && usage ;
while [ "$#" -gt "0" ] ; do
    case "$1" in 
	-d|--dir)
		wdir=$2 && shift 2
		;;
	-i|--noninteractive)
		echo "Default settings" && shift 
		;;
	-l|--linuxconfig)
		kfile=$2 && shift 2
		;;
	-a|--arch)
		arch=$2 && shift 2
		;;
	*)
		echo "Unknown flag $@" && exit 0
		;;
    esac
done	

#[[ -z "$wdir" ]] && wdir=`pwd`
echo "Installing Directory: ${wdir:=`pwd`}"
echo "Kernel config : ${kfile:="default.config"}"
echo "cpu architect : ${arch:="i586"}"
echo "userid : ${defuser:=`whoami`-aos}"
passargs=("-s" "-a" "$arch")
[[ "$(id -u)" != "0" ]] && [[ ! -z "sudo -v | grep 'Sorry'" ]] && nochroot="y" 
[[ "$nochroot" = "y" ]] && echo "Installing base files, sudo or root is needed for chroot"
dspace=$(df -kh `pwd` | perl -lane '$F[3] =~ /(\d+)\D/  && print $1')
[[ "$dspace" -lt "10" ]] && echo " Need 10G , but only ""$dspace""G available" && exit 0

CHROOT_DIR="$wdir/root"
CHROOT="chroot $CHROOT_DIR"

cd $wdir && mkdir root || error2exit "$?"
[[ -e "buildaos.sh" ]] || wget -c http://aos.ion.nu/files/buildaos.sh
chmod 755 buildaos.sh
[[ -e "$kfile" ]] && passargs=("${passargs[@]}" "-l" "$kfile") || passargs=("${passargs[@]}" "-i")
bash -i buildaos.sh "${passargs[@]}"
#Avoid source or ./ to prevent overlapping var
echo "base build finished"
chown -R 0.0 root/
cp /etc/resolv.conf root/etc/
echo "$(hostname)-aos" >> root/etc/hostname
[[ "$nochroot" = "y" ]] && echo "Need root access to chroot " && exit 0

#PART 2 - Of installation Begins.

install_pkg () {
	local pkgaddr="$1"
	local taropt="$2"
	local confopt="$3"
	local olddir=`pwd`
	eval "wget -c $pkgaddr"
	tar "$taropt" $(eval "ls -t | head -1") && cd $(eval "ls -dt */ | head -1") || return 1
	$confopt && make && make install
	cd $olddir && return 0
}

pass_install_perl () {
	install_pkg "http://www.cpan.org/src/5.0/perl-5.20.1.tar.gz" "-xvzf" './Configure -d -e -Dprefix="/usr" -Duseshrplib'
	[[ $? -eq 0 ]] && echo "perl installed" || echo "Error with extraction or wget"
	return 0
}	

pass_install_openssl () {
	local olddir=`pwd`
	wget -c http://www.openssl.org/source/openssl-1.0.1h.tar.gz
	tar -xzf $(eval "ls -t | head -1") && cd $(eval "ls -dt */ | head -1") || return 1
	./config shared --prefix="/usr" --openssldir="/etc/ssl"
	echo MANDIR=/usr/share/man >> Makefile
	make && make install
	cd $olddir && return 0
}

pass_install_zlib () {
	install_pkg "http://downloads.sourceforge.net/project/libpng/zlib/1.2.8/zlib-1.2.8.tar.gz" "-xzf" './configure --prefix="/usr"'
	[[ $? -eq 0 ]] && echo "zlib installed" || echo "Error with extraction or wget"
	return 0
}

pass_install_openssh () {
	local oldidr=`pwd`
	wget -c http://ftp.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-6.7p1.tar.gz
	tar -xzf $(eval "ls -t | head -1") && cd $(eval "ls -dt */ | head -1") || return 1
	mkdir -p build && cd build
	../configure --prefix="/usr" --sysconfdir="/etc" --with-xauth="/usr/bin/xauth"
	make 
	useradd -M -r -s /sbin/nologin sshd
	make install 
	cd $olddir && return 0
	}

pass_install_vim () {
	install_pkg "http://ftp.vim.org/pub/vim/unix/vim-7.4.tar.bz2" "-jxf" './configure --prefix="/usr" --enable-multibyte'
	[[ $? -eq 0 ]] && echo "vim installed" || echo "Error with extraction"
	return 0
	}



install_perl () {
	wget -c http://www.cpan.org/src/5.0/perl-5.20.1.tar.gz
	tar -xzf perl-5.20.1.tar.gz && cd perl-5.20.1 || return 1
	./Configure -d -e -Dprefix="/usr" -Duseshrplib
	make && make install
}

install_openssl () { #make not of gcc arch
	wget -c http://www.openssl.org/source/openssl-1.0.1h.tar.gz
	tar -xvzf openssl-1.0.1h.tar.gz && cd openssl-5.20.1 || return 1
	./config shared --prefix="/usr" --openssldir="/etc/ssl"
	echo MANDIR=/usr/share/man >> Makefile
	make && make install
}

install_zlib () {
	wget -c http://downloads.sourceforge.net/project/libpng/zlib/1.2.8/zlib-1.2.8.tar.gz
	tar -zvxf zlib-1.2.8.tar.gz && cd zlib-1.2.8 || return 1
	./configure --prefix="/usr"
	make && make install
}

install_openssh () { #make note on useradd
	wget -c http://ftp.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-6.7p1.tar.gz
	tar -xzf openssh-6.7p1.tar.gz && cd openssh-6.71p1 || return 1
	mkdir -p build && cd build 
	../configure --prefix="/usr" --sysconfdir="/etc" --with-xauth="/usr/bin/xauth"
	make 
	useradd -M -r -s /sbin/nologin sshd
	make install
}

install_vim () {
	wget -c http://ftp.vim.org/pub/vim/unix/vim-7.4.tar.bz2
	tar -xjf vim-7.4.tar.bz2 && cd vim74 || return 1
	./configure --prefix="/usr" --enable-multibyte
	make && make install
	echo 'set enc=utf-8' >> /usr/share/vim/vimrc
}

export -f install_pkg pass_install_perl pass_install_openssl pass_install_zlib pass_install_vim pass_install_openssh

genpw () {
	< /dev/urandom tr 'a-zA-Z0-9' | head -c ${1:-8}
}


cd $CHROOT_DIR
mount -t proc /proc proc
mount --rbind /sys sys
mount --rbind /dev /dev

psw=`genpw`
chroot \bin\bash -c "echo 'PATH=$PATH:/bin:/sbin:/usr/sbin:/usr/bin' >> /etc/profile"
chroot \bin\bash -c 'useradd -p "$psw" -m "$defuser" '
chroot \bin\bash -c "pass_install_perl ; pass_install_openssl ; pass_install_zlib "
chroot \bin\bash -c "pass_install_vim ; pass_install_openssh"
chroot \bin\bash -c "umount -f /proc"
chroot \bin\bash -c "umount -f /sys"
chroot \bin\bash -c "umount -f /dev"
echo "access of $defuser with password $psw" 

