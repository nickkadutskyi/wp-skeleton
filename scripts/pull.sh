#!/bin/bash
# TODO set a path to your project root
cd /var/www/project-name

#CURRENT_COMMIT_HASH=$(git rev-parse HEAD)

git pull origin main
git submodule update --init --recursive
rm .env.prod.local
export APP_ENV=prod
composer install --no-dev --optimize-autoloader
APP_RUNTIME_ENV=prod php bin/console secrets:decrypt-to-local --force
composer dump-env prod
APP_ENV=prod APP_DEBUG=0 php bin/console cache:clear
#php bin/console doctrine:migrations:migrate -n

#LAST_COMMIT_HASH=$(git rev-parse HEAD)
#CHANGED_ASSETS=$(git diff --name-only "$CURRENT_COMMIT_HASH" "$LAST_COMMIT_HASH" | grep 'assets/\|\.env\|webpack.config.js\|pnpm-lock.yaml\|babel\|postcss.config.js\|package.json\|tailwind.config.js\|tsconfig.json\|templates/')

#if [ -z "$CHANGED_ASSETS" ]
#then
#  echo "No changes in Assets"
#else
#  pnpm install
#  pnpm build
#fi

# Download current version of WP core
scripts/wp-install.sh
sudo chown -R nick:www-data ./*
sudo service apache2 restart
