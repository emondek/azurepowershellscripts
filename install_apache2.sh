#!/bin/bash
apt-get -y update

# install Apache2
apt-get -y install apache2 

# write some HTML
echo \<center\>\<h1\>Default2\</h1\>\<br/\>\</center\> > /var/www/html/default.html
echo \<center\>\<h1\>SVC Root\</h1\>\<br/\>\</center\> > /var/www/html/svc.html
echo \<center\>\<h1\>Healthy2\</h1\>\<br/\>\</center\> > /var/www/html/healthcheck.html
mkdir /var/www/html/svc
echo \<center\>\<h1\>SVC Subfolder\</h1\>\<br/\>\</center\> > /var/www/html/svc/default.html
echo \<center\>\<h1\>SVC Healthy\</h1\>\<br/\>\</center\> > /var/www/html/svc/healthcheck.html


# restart Apache
apachectl restart