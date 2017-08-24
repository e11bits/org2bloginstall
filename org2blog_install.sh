#!/bin/bash
LAUNCHDATE="170824"
BESTBEFORE=365 # days
GIT=git
SED=sed
PATCH=patch
EMACSCFG="$HOME/.emacs"
EMACSDIR="$HOME/.emacs.d"
AUTHCFG="$HOME/.netrc"
O2BDIR="$EMACSDIR/org2blog"
O2BREPO="http://github.com/punchagan/org2blog.git"
O2BWEB="https://github.com/org2blog/org2blog"
O2BPATCH="org2blog.patch"
XMLRPCDIR="$EMACSDIR/xml-rpc-el"
XMLRPCREPO="https://github.com/hexmode/xml-rpc-el.git"
METAWEBLOGDIR="$EMACSDIR/metaweblog"
METAWEBLOGREPO="https://github.com/org2blog/metaweblog.git"
CFGSECSTART=";; org2blog config start"
CFGSECEND=";; org2blog config end"

function tooOld {
    ageInDays=$(( ($(date +%s) - $(date --date=$LAUNCHDATE +%s)) / (60 * 60 * 24) ))
    return $(( $ageInDays < 365 ))
}

function confirmDo {
    if $1; then
	echo "$2"
	select yn in "Yes" "No"; do
	    case $yn in
		Yes ) $3; break;;
		No ) exit 1;;
	    esac
	done
    fi
}  

function addEmacsCfg {
    echo $1 >> $EMACSCFG
}

cat <<EOF

This script will try to do the following things:

 1) Checkout the latest version of org2blog, metaweblog and xml-rpc-el into $EMACSDIR
 2) Patch xml-rpc.el using $O2BPATCH so that Unicode characters work in blog posts
 3) Add credentials of your Wordpress blog to $AUTHCFG
 4) Add necessary configurations for org2blog to $EMACSCFG

Detailed installation information can be found at $O2BWEB

EOF

confirmDo true "Continue?" ""

confirmDo tooOld "This script is probably too old to still work properly. Continue anyway?" "echo You have been warned!"

which $GIT > /dev/null || ( echo "Can't find $GIT executable!" && exit 1 )
which $SED > /dev/null || ( echo "Can't find $SED executable!" && exit 1 )
which $PATCH > /dev/null || ( echo "Can't find $PATCH executable!" && exit 1 )

confirmDo "[ ! -d $EMACSDIR ]" "$EMACSDIR does not exist! Create it?" "mkdir $EMACSDIR"
confirmDo "[ -d $O2BDIR ]" "$O2BDIR does already exist! Remove it?" "rm -rf $O2BDIR"
confirmDo "[ -d $XMLRPCDIR ]" "$XMLRPCDIR does already exist! Remove it?" "rm -rf $XMLRPCDIR"
confirmDo "[ -d $METAWEBLOGDIR ]" "$METAWEBLOGDIR does already exist! Remove it?" "rm -rf $METAWEBLOGDIR"

$GIT clone $O2BREPO $O2BDIR
$GIT clone $METAWEBLOGREPO $METAWEBLOGDIR
$GIT clone $XMLRPCREPO $XMLRPCDIR

$PATCH --directory=$XMLRPCDIR --strip=1 --forward < $O2BPATCH

default="wordpress"
echo -n "Name of blog [$default]: "
read blogname
blogname=${blogname:-$default}
default="https://username.wordpress.com"
echo -n "URL of blog [$default]: "
read blogurl
blogurl=${blogurl:-$default}/xmlrpc.php
default="$USER"
echo -n "Username for blog [$default]: "
read blogusername
blogusername=${blogusername:-$default}
default="editlater"

echo -n "Password for blog [$default]: "
read blogpassword
blogpassword=${blogpassword:-$default}

cat >> $AUTHCFG <<EOF
machine $blogname login $blogusername password $blogpassword
EOF

confirmDo "[ ! -f $EMACSCFG ]" "$EMACSCFG does not exist! Create it?" "touch $EMACSCFG"
sed -i "/$CFGSECSTART/,/$CFGSECEND/d" $EMACSCFG
addEmacsCfg "$CFGSECSTART"
addEmacsCfg "(setq load-path (cons \"$XMLRPCDIR\" load-path))"
addEmacsCfg "(setq load-path (cons \"$METAWEBLOGDIR\" load-path))"
addEmacsCfg "(setq load-path (cons \"$O2BDIR\" load-path))"
addEmacsCfg "(require 'org2blog-autoloads)"
addEmacsCfg "(require 'auth-source) ;; or nothing if already in the load-path"
cat >> $EMACSCFG <<EOF
(let (credentials)
  ;; only required if your auth file is not already in the list of auth-sources
  (add-to-list 'auth-sources "~/.netrc")
  (setq credentials (auth-source-user-and-password "$blogname"))
  (setq org2blog/wp-blog-alist
        \`(("$blogname"
           :url "$blogurl"
           :username ,(car credentials)
           :password ,(cadr credentials)
	   :default-title "Hello World"
	   :default-categories ("org2blog" "emacs")
	   :tags-as-categories nil))))
EOF
addEmacsCfg "$CFGSECEND"

cat <<EOF

Now (re)start emacs and check the installation by using

    	      M-x org2blog/wp-login

Detailed usage information can be found at $O2BWEB

EOF
exit 0
