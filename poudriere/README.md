poudriere
=========

What is poudriere?
------------------

poudriere is a tool designed to test package production on FreeBSD. However,
most people will find it useful to bulk build ports for FreeBSD.

https://github.com/freebsd/poudriere/wiki


Setup
-----

Edit the poudriere.conf, example:

    > grep -Ev '(^#|^$)' poudriere.conf
    ZPOOL=tank
    ZROOTFS=/poudriere
    FREEBSD_HOST=https://download.FreeBSD.org
    RESOLV_CONF=/etc/resolv.conf
    BASEFS=/usr/local/poudriere
    POUDRIERE_DATA=${BASEFS}/data
    USE_PORTLINT=no
    USE_TMPFS=yes
    DISTFILES_CACHE=/usr/ports/distfiles
    CHECK_CHANGED_OPTIONS=verbose
    CHECK_CHANGED_DEPS=yes
    PKG_REPO_SIGNING_KEY=/usr/local/etc/ssl/keys/pkg.key
    CCACHE_DIR=/var/cache/ccache
    NOLINUX=yes
    URL_BASE=http://poudriere.affe.network


Create the key (public/private)

    # mkdir -p /usr/local/etc/ssl/keys /usr/local/etc/ssl/certs
    # chmod 600 /usr/local/etc/ssl/keys
    # openssl genrsa -out /usr/local/etc/ssl/keys/pkg.key 4096
    # openssl rsa -in /usr/local/etc/ssl/keys/pkg.key -pubout > /usr/local/etc/ssl/certs/pkg.cert

Be sure to copy the pkg.cert file to your client systems


First create a ports tree to be used by poudriere

    poudriere ports -c


Create the jail and version you want to build packages for:

    poudriere jail -c -j 11amd64 -v 11.0-RELEASE -a amd64

Current Releases:
ftp://ftp.freebsd.org/pub/FreeBSD/releases/

Create a pkglist

    > cat /usr/local/etc/poudriere.d/11amd64.pkglist
    www/nginx

Build the port with custom options:

     poudriere options -cf /usr/local/etc/poudriere.d/11amd64.pkglist -j 11amd64

Build the packages:

    poudriere bulk -f /usr/local/etc/poudriere.d/11amd64.pkglist -j 11amd64

Update the ports:

    poudriere ports -u
    poudriere bulk -f /usr/local/etc/poudriere.d/11amd64.pkglist -j 11amd64


Daily usage
-----------

Adding a package to the list and setting options for the port and it’s dependencies.

    echo "sysutils/freecolor" >> /usr/local/etc/poudriere.d/11amd64.pkglist
    poudriere options -cj 11amd64 sysutils/freecolor
    poudriere bulk -f /usr/local/etc/poudriere.d/11amd64.pkglist -j 11amd64


On the client to update the packages use:

    pkg upgrade


Rebuild port
------------

Using the -C option instead of -c rebuilds only the ports listed in the file
specified by the -f option or given on the command line. For example this would
forcibly rebuild the www/nginx package and no other package:

    poudriere bulk -Ctr -j 11amd64 www/nginx
    # -t Test the specified ports for leafovers
    # -r recursively test all dependecies as well


Client setup
------------

To setup the clients (machines using your packages with ``pkg install your_package``)

This will disable this repository the default 'FreeBSD repository':

    mkdir -p /usr/local/etc/pkg/repos
    echo "FreeBSD: { enabled: no }" > /usr/local/etc/pkg/repos/FreeBSD.conf

To activate the repository on the client create the file ``poudriere.conf``:

    cat > /usr/local/etc/pkg/repos/poudriere.conf
    poudriere: {
      url: "http://10.1.1.1/packages/11amd64-default"
      mirror_type: "http",
      signature_type: "pubkey",
      pubkey: "/usr/local/etc/ssl/certs/pkg.cert",
      enabled: yes
      priority: 1
    }

> You can use any name for this file, providing that it has the .conf suffix

For this to work you need to put the packages available via web. If using nginx
this is the basic conf:

    server {
        listen 80 default_server;
        server_name _;
        root /usr/local/share/poudriere/html;
        index index.html index.html;
        autoindex on;

        location /data {
            alias /usr/local/poudriere/data/logs/bulk;
            autoindex on;
        }

        location /packages {
            root /usr/local/poudriere/data;
            autoindex on;
        }
    }

make.conf
=========

Custom make.conf (``/usr/local/etc/poudriere.d/make.conf``):

    NO_X=true
    WITHOUT="X11"
    OPTIONS_UNSET=X11 GUI CUPS DOCS EXAMPLES


loop
====

IF pkg start behaving like in a loop, try:

    pkg install -r poudriere pkg

where poudriere is one of the servers/Repositories listed on the output of ``pkg -vv``


Custom ports
=============

Create a ports tree with the name "custom":

    poudriere ports -c -p custom

Buld custom package:

    poudriere bulk -j 11amd64 -p custom sysutils/epazote
