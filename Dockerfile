FROM phusion/baseimage:0.9.15

# Ensure UTF-8
RUN locale-gen en_US.UTF-8
ENV LANG       en_US.UTF-8
ENV LC_ALL     en_US.UTF-8

ENV HOME /root

RUN /etc/my_init.d/00_regen_ssh_host_keys.sh

CMD ["/sbin/my_init"]

# Nginx-PHP Installation
RUN apt-get update
RUN DEBIAN_FRONTEND="noninteractive" apt-get install -y vim curl wget build-essential python-software-properties git
RUN add-apt-repository -y ppa:ondrej/php-7.0
RUN add-apt-repository -y ppa:nginx/stable
RUN apt-get update
RUN DEBIAN_FRONTEND="noninteractive" apt-get install -y --force-yes php7.0 php7.0-dev php7.0-common php7.0-cgi php7.0-fpm php7.0-mysql php7.0-opcache php7.0-intl php7.0-gd php7.0-curl php7.0-mcrypt php7.0-imap php7.0-ldap php7.0-json

#Install php-redis extension for php7
RUN git clone https://github.com/phpredis/phpredis.git
RUN cd phpredis && git checkout php7 && phpize && ./configure && make && make install && cd .. && rm -rf phpredis
RUN echo "extension=redis.so" > /etc/php/mods-available/redis.ini
RUN ln -sf /etc/php/mods-available/redis.ini /etc/php/7.0/fpm/conf.d/20-redis.ini
RUN ln -sf /etc/php/mods-available/redis.ini /etc/php/7.0/cli/conf.d/20-redis.ini

# Install php-memcached extension for php7
RUN apt-get install gcc make autoconf libc-dev pkg-config zlib1g-dev libmemcached-dev
RUN git clone https://github.com/php-memcached-dev/php-memcached
RUN cd php-memcached && git checkout php7 && phpize && ./configure && make && make install
RUN echo "extension=memcached.so" > /etc/php/mods-available/memcached.ini
RUN ln -sf /etc/php/mods-available/memcached.ini /etc/php/7.0/fpm/conf.d/20-memcached.ini
RUN ln -sf /etc/php/mods-available/memcached.ini /etc/php/7.0/cli/conf.d/20-memcached.ini

# Update default config for php
RUN sed -i "s/;date.timezone =.*/date.timezone = UTC/" /etc/php/7.0/fpm/php.ini
RUN sed -i 's/memory_limit\ =\ 128M/memory_limit\ =\ 2G/g' /etc/php/7.0/fpm/php.ini
RUN sed -i 's/\;date\.timezone\ =/date\.timezone\ =\ Asia\/Ho_Chi_Minh/g' /etc/php/7.0/fpm/php.ini
RUN sed -i 's/upload_max_filesize\ =\ 2M/upload_max_filesize\ =\ 200M/g' /etc/php/7.0/fpm/php.ini
RUN sed -i 's/post_max_size\ =\ 8M/post_max_size\ =\ 200M/g' /etc/php/7.0/fpm/php.ini
RUN sed -i 's/max_execution_time\ =\ 30/max_execution_time\ =\ 3600/g' /etc/php/7.0/fpm/php.ini

RUN DEBIAN_FRONTEND="noninteractive" apt-get install -y nginx

RUN echo "daemon off;" >> /etc/nginx/nginx.conf
RUN sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php/7.0/fpm/php-fpm.conf
RUN sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php/7.0/fpm/php.ini


RUN mkdir -p        /var/www
ADD build/default   /etc/nginx/sites-available/default
RUN mkdir           /etc/service/nginx
ADD build/nginx.sh  /etc/service/nginx/run
RUN chmod +x        /etc/service/nginx/run
RUN mkdir           /etc/service/phpfpm
ADD build/phpfpm.sh /etc/service/phpfpm/run
RUN chmod +x        /etc/service/phpfpm/run

EXPOSE 80
# End Nginx-PHP

# Copy source directory to default nginx root directory
ADD www             /var/www

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
