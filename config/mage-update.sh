#!/bin/sh
echo "Initializing update..."

cd /var/www/html

if [ ! -f ./app/etc/env.php ]; then
  echo "It appears Magento is not install (app/etc/config.php or app/etc/env.php exist). Please setup now..."
  exit
fi

echo "Update media & var"
if [ -d /mnt/var ]; then
  rm -rf var && ln -s /mnt/var var
fi
if [ -d /mnt/media ]; then
  rm -rf pub/media && ln -s /mnt/media pub/media
fi
if [ -d /mnt/var ] || [ -d /mnt/media ]; then
  find /mnt/media /mnt/var -type d -exec chmod 777 {} \;
fi

ln -s /var/www/.composer /root/.composer
rm -f ./var/composer_home; ln -s /var/www/.composer ./var/composer_home
chmod +x ./bin/magento

echo "grant permission of magento root"
chown -R web:apache *
#find . -type d -exec chmod 775 {} \;
#find . -type f -exec chmod 664 {} \;

echo "Create robots.txt"
cat <<EOF >> robots.txt
User-agent: *
Disallow: /
EOF

echo "Clear cache"
rm -rf var/cache var/page_cache var/generation var/di var/view_preprocessed

echo "Enable modules"
/usr/bin/php /usr/bin/composer install

echo -n "Waiting connect db"
while [ -e database_not_ready ]; do
    mysql --host=$M2SETUP_DB_HOST --user=$M2SETUP_DB_USER --password=$M2SETUP_DB_PASSWORD \
          --execute="show tables" $M2SETUP_DB_NAME >/dev/null 2>&1 && rm database_not_ready
    sleep 2s
    echo -n "."
done
echo

echo "Run setup scripts"
/usr/bin/php bin/magento admin:user:create \
       --admin-firstname=$M2SETUP_ADMIN_FIRSTNAME \
       --admin-lastname=$M2SETUP_ADMIN_LASTNAME \
       --admin-email=$M2SETUP_ADMIN_EMAIL \
       --admin-user=$M2SETUP_ADMIN_USER \
       --admin-password=$M2SETUP_ADMIN_PASSWORD
/usr/bin/php bin/magento setup:store-config:set \
        --use-secure=$M2SETUP_USE_SECURE \
        --use-secure-admin=$M2SETUP_USE_SECURE_ADMIN \
        --base-url-secure=$M2SETUP_BASE_URL_SECURE
/usr/bin/php bin/magento setup:config:set --backend-frontname=$M2SETUP_BACKEND_FRONTNAME
/usr/bin/php bin/magento setup:upgrade
/usr/bin/php bin/magento setup:di:compile
/usr/bin/php bin/magento cache:clean

echo "grant permission of magento root"
chown -R web:apache *

echo "Turning on developer mode.."
/usr/bin/php bin/magento deploy:mode:set developer

echo "The setup script has completed execution."
echo "
===================== 🚀 Done 🚀 ===================
      Magento 2 Installed successfully!
      🌎 Admin: "$M2SETUP_BASE_URL"admin
      👤 User: "$M2SETUP_ADMIN_USER"
      🔑 Password: "$M2SETUP_ADMIN_PASSWORD"
===================== 🚀 Done 🚀 ==================="