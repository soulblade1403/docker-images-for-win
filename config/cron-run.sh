#!/bin/sh
BASE_DIR=/var/www
SRC_DIR=$BASE_DIR/html

if [ -d $BASE_DIR/.composer ]; then
  rm -rf $SRC_DIR/var/composer_home
  su -c "ln -s $BASE_DIR/.composer $SRC_DIR/var/composer_home" -s /bin/sh apache
fi

(crontab -l ; echo "*/5 * * * * su -c \"/usr/bin/php $SRC_DIR/update/cron.php\" -s /bin/sh apache > /proc/1/fd/2 2>&1") | crontab - \
  && (crontab -l ; echo "*/5 * * * * su -c \"/usr/bin/php $SRC_DIR/bin/magento-php cron:run\" -s /bin/sh apache > /proc/1/fd/2 2>&1") | crontab - \
  && (crontab -l ; echo "*/5 * * * * su -c \"/usr/bin/php $SRC_DIR/bin/magento-php setup:cron:run\" -s /bin/sh apache > /proc/1/fd/2 2>&1") | crontab -

# Start the cron service
/usr/sbin/crond
