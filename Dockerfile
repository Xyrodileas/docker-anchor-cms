#
# Dockerfile to run the PHP backend of Anchor CMS
# The database backend is intended to be ran on a separate container
# The WebServer in use is NGinx
#
# Author: Etienne LAFARGE <etienne.lafarge_at_gmail.com>
# License: GPLv3
#

FROM ubuntu:16.04
MAINTAINER Xyrodileas

# Let's get rid of apt-get's interactive mode
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

# Let's be up to date
RUN apt-get update
RUN apt-get install -y software-properties-common

# Let's install the PHP modules required by Anchor
RUN apt-get install -y php-fpm
RUN apt-get install -y php-gd
RUN apt-get install -y php-mysql
RUN apt-get install -y php-curl
RUN apt-get install -y php-mcrypt
run apt-get install -y php-mbstring

# And finally let's install NGinx
RUN apt-get install -y nginx
RUN update-rc.d -f nginx remove

## Ok let's download and extract the source code of Anchor CMS
RUN apt-get install -y curl
RUN apt-get install -y unzip
RUN curl -L https://github.com/anchorcms/anchor-cms/releases/download/0.12.7/anchor-cms-0.12.7-bundled.zip -o anchorcms.zip
RUN unzip anchorcms.zip -d /var/www/ \
    && mv /var/www/anchor-* /var/www/anchor \
    && rm anchorcms.zip && chown -R www-data:www-data /var/www/anchor

# Let's forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log
RUN ln -sf /dev/stderr /var/log/nginx/error.log

# Let's configure PHP-FPM
RUN echo "cgi.fix_pathinfo = 0;" >> /etc/php/7.0/fpm/php.ini

# Let's setup our nginx "Virtual Host"
COPY ./volumes/nginx/sites-available/anchor /etc/nginx/sites-available/anchor
RUN rm -rf /etc/nginx/sites-enabled/*
RUN ln -sf /etc/nginx/sites-available/anchor /etc/nginx/sites-enabled/anchor

# Let's expose the configuration so that it can be modified later (by chef,
# during deployments for instance). It includes the Anchor app config as well
# as the NGinx host configuration
VOLUME /var/www/anchor/content
VOLUME /var/www/anchor/themes
VOLUME /var/www/anchor/anchor/config
VOLUME /etc/nginx/sites-available

# And let's forward the HTTP and HTTPs ports to the host
EXPOSE 80 443

# We can now start our server
COPY start_server.sh /start_server.sh
RUN chmod +x /start_server.sh
ENTRYPOINT ["/start_server.sh"]
CMD nginx -g 'daemon off;'
