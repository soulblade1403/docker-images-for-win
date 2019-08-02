#!/bin/sh
echo "Initializing setup..."

cd /var/www/html

echo "grant permission of magento root"
chown -R web:apache *

if [ -f ./app/etc/env.php ]; then
  echo "It appears Magento is already installed (app/etc/config.php or app/etc/env.php exist). Exiting setup..."
  exit
fi

echo "Update media & var & Change permission"
if [ -d /mnt/var ]; then
  rm -rf var && ln -s /mnt/var var
fi
if [ -d /mnt/media ]; then
  rm -rf pub/media && ln -s /mnt/media pub/media
fi
if [ -d /mnt/var ] || [ -d /mnt/media ]; then
  find /mnt/media /mnt/var -type d -exec chmod 777 {} \;
fi

echo "Create robots.txt"
cat <<EOF >> robots.txt
User-agent: *
Disallow: /
EOF

ln -s /var/www/.composer /root/.composer
rm -f ./var/composer_home; ln -s /var/www/.composer ./var/composer_home
chmod +x ./bin/magento


/usr/bin/php /usr/bin/composer install

if [ "$M2SETUP_USE_SAMPLE_DATA" == "true" ]; then
  M2SETUP_USE_SAMPLE_DATA_STRING="--use-sample-data"
else
  M2SETUP_USE_SAMPLE_DATA_STRING=""
fi

echo -n "Waiting for db"
touch database_not_ready
while [ -e database_not_ready ]; do
    mysql --host=$M2SETUP_DB_HOST --user=$M2SETUP_DB_USER --password=$M2SETUP_DB_PASSWORD \
          --execute="show tables" $M2SETUP_DB_NAME >/dev/null 2>&1 && rm database_not_ready
    sleep 2s
    echo -n "."
done
echo

echo "Running Magento 2 setup script..."
/usr/bin/php ./bin/magento setup:install \
  --base-url=$M2SETUP_BASE_URL \
  --backend-frontname=$M2SETUP_BACKEND_FRONTNAME \
  --db-host=$M2SETUP_DB_HOST \
  --db-name=$M2SETUP_DB_NAME \
  --db-user=$M2SETUP_DB_USER \
  --db-password=$M2SETUP_DB_PASSWORD \
  --admin-firstname=$M2SETUP_ADMIN_FIRSTNAME \
  --admin-lastname=$M2SETUP_ADMIN_LASTNAME \
  --admin-email=$M2SETUP_ADMIN_EMAIL \
  --admin-user=$M2SETUP_ADMIN_USER \
  --admin-password=$M2SETUP_ADMIN_PASSWORD \
  --language=$M2SETUP_LANGUAGE \
  --currency=$M2SETUP_CURRENCY \
  --timezone=$M2SETUP_TIMEZONE \
  --use-rewrites=$M2SETUP_USE_REWRITES \
  --use-secure=$M2SETUP_USE_SECURE \
  --use-secure-admin=$M2SETUP_USE_SECURE_ADMIN \
  --base-url-secure=$M2SETUP_BASE_URL_SECURE \
  $M2SETUP_USE_SAMPLE_DATA_STRING

echo "grant permission of magento root"
chown -R web:apache *

echo "Turning on developer mode.."
/usr/bin/php ./bin/magento deploy:mode:set developer

echo "The setup script has completed execution."
echo "
===================== 🚀 Done 🚀 ===================
      Magento 2 Installed successfully!
      🌎 Admin: "$M2SETUP_BASE_URL"admin
      👤 User: "$M2SETUP_ADMIN_USER"
      🔑 Password: "$M2SETUP_ADMIN_PASSWORD"
===================== 🚀 Done 🚀 ==================="
