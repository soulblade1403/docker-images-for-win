FROM centos

MAINTAINER Soulblade "phuocvu@builtwithdigital.com"

RUN yum -y --setopt=tsflags=nodocs install httpd wget mysql vi crontabs unzip sudo net-tools glibc-common \
 && yum install -y http://dl.iuscommunity.org/pub/ius/stable/CentOS/7/x86_64/ius-release-1.0-15.ius.centos7.noarch.rpm \
 && yum -y install php71u php71u-pdo php71u-mysqlnd php71u-opcache php71u-xml php71u-mcrypt php71u-gd \
        php71u-intl php71u-mbstring php71u-bcmath php71u-json php71u-iconv php71u-soap  php71u-cli \
        php71u-pecl-imagick php71u-pecl-redis php71u-devel \
# Clean CentOS 7
 && yum clean all && rm -rf /var/cache/yum/* \

# Install composer
 && wget https://getcomposer.org/composer.phar && chmod +x composer.phar && mv composer.phar /usr/bin/composer \
# Config PHP
 && sed -i 's/memory_limit = 128M/memory_limit = 1024M/g' /etc/php.ini \
 && sed -i 's/post_max_size = 8M/post_max_size = 128M/g' /etc/php.ini \
 && sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 128M/g' /etc/php.ini \
 && sed -i 's/short_open_tag = Off/short_open_tag = On/g' /etc/php.ini

# Config apache
COPY config/httpd.conf /etc/httpd/conf/httpd.conf
RUN sed -i 's/LoadModule authn_anon_module/#LoadModule authn_anon_module/g' /etc/httpd/conf.modules.d/00-base.conf \
 && sed -i 's/LoadModule authn_dbm_module/#LoadModule authn_dbm_module/g' /etc/httpd/conf.modules.d/00-base.conf \
 && sed -i 's/LoadModule authz_dbm_module/#LoadModule authz_dbm_module/g' /etc/httpd/conf.modules.d/00-base.conf \
 && sed -i 's/LoadModule authz_groupfile_module/#LoadModule authz_groupfile_module/g' /etc/httpd/conf.modules.d/00-base.conf \
 && sed -i 's/LoadModule authz_owner_module/#LoadModule authz_owner_module/g' /etc/httpd/conf.modules.d/00-base.conf \
 && sed -i 's/LoadModule cache_module/#LoadModule cache_module/g' /etc/httpd/conf.modules.d/00-base.conf \
 && sed -i 's/LoadModule cache_disk_module/#LoadModule cache_disk_module/g' /etc/httpd/conf.modules.d/00-base.conf \
 && sed -i 's/LoadModule ext_filter_module/#LoadModule ext_filter_module/g' /etc/httpd/conf.modules.d/00-base.conf \
 && sed -i 's/LoadModule include_module/#LoadModule include_module/g' /etc/httpd/conf.modules.d/00-base.conf \
 && sed -i 's/LoadModule info_module/#LoadModule info_module/g' /etc/httpd/conf.modules.d/00-base.conf \
 && sed -i 's/LoadModule logio_module/#LoadModule logio_module/g' /etc/httpd/conf.modules.d/00-base.conf \
 && sed -i 's/LoadModule status_module/#LoadModule status_module/g' /etc/httpd/conf.modules.d/00-base.conf \
 && sed -i 's/LoadModule substitute_module/#LoadModule substitute_module/g' /etc/httpd/conf.modules.d/00-base.conf \
 && sed -i 's/LoadModule userdir_module/#LoadModule userdir_module/g' /etc/httpd/conf.modules.d/00-base.conf \
 && sed -i 's/LoadModule vhost_alias_module/#LoadModule vhost_alias_module/g' /etc/httpd/conf.modules.d/00-base.conf \
 && sed -i 's/LoadModule proxy_ajp_module/#LoadModule proxy_ajp_module/g' /etc/httpd/conf.modules.d/00-proxy.conf \
 && sed -i 's/LoadModule proxy_balancer_module/#LoadModule proxy_balancer_module/g' /etc/httpd/conf.modules.d/00-proxy.conf \
 && sed -i 's/LoadModule proxy_connect_module/#LoadModule proxy_connect_module/g' /etc/httpd/conf.modules.d/00-proxy.conf \
 && sed -i 's/LoadModule proxy_ftp_module/#LoadModule proxy_ftp_module/g' /etc/httpd/conf.modules.d/00-proxy.conf \
 && sed -i 's/LoadModule proxy_http_module/#LoadModule proxy_http_module/g' /etc/httpd/conf.modules.d/00-proxy.conf \
# Create sudo user
 && groupadd -g 1001 web \
 && adduser -r -u 1001 -g web web \
 && usermod -aG root web && usermod -aG apache web \
 && echo "web      ALL=(ALL)       ALL" >> /etc/sudoers

#EXPOSE 80 443

VOLUME ["/var/www/html"]
WORKDIR /var/www/html

# Simple startup script to avoid some issues observed with container restart
ADD config/httpd-run.sh /httpd-run.sh
ADD config/cron-run.sh /cron-run.sh
ADD config/mage-setup.sh /usr/bin/mage-setup.sh
ADD config/mage-update.sh /usr/bin/mage-update.sh
RUN chmod -v +x /httpd-run.sh /cron-run.sh \
 && chmod -v +x /usr/bin/mage-setup.sh /usr/bin/mage-update.sh

# Setup user
USER web

CMD ["/httpd-run.sh", "/cron-run.sh"]
