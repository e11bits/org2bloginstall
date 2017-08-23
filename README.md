# org2bloginstall
Small script to help with the installation of org2blog

# This script will try to do the following things:

 1) Checkout the latest version of org2blog, metaweblog and xml-rpc-el into $EMACSDIR
 2) Patch xml-rpc.el using org2blog.patch so that Unicode characters work in blog posts
 3) Add credentials of your Wordpress blog to $AUTHCFG
 4) Add necessary configurations for org2blog to $EMACSCFG
