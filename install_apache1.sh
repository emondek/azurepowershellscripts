#!/bin/bash
apt-get -y update

# install Apache2
apt-get -y install apache2 

# write some HTML
echo \<center\>\<h1\>Default1\</h1\>\<br/\>\</center\> > /var/www/html/default.html
echo \<center\>\<h1\>OMS Root\</h1\>\<br/\>\</center\> > /var/www/html/oms.html
echo \<center\>\<h1\>Healthy1\</h1\>\<br/\>\</center\> > /var/www/html/healthcheck.html
mkdir /var/www/html/oms
echo \<center\>\<h1\>OMS Subfolder\</h1\>\<br/\>\</center\> > /var/www/html/oms/default.html
echo \<center\>\<h1\>OMS Healthy\</h1\>\<br/\>\</center\> > /var/www/html/oms/healthcheck.html


# restart Apache
apachectl restart