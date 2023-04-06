# WordPress + Symfony Skeleton
Project starter for WordPress site

- Symfony is used solely because of its [secrets management feature](https://symfony.com/doc/current/configuration/secrets.html)
- WordPress core files are always separate from wp-content and plugins and are managed by WP-CLI

## Development
```bash
# Install the project
composer install

# Install all submodules (if exist)
git submodule update --init --recursive

# Runs installation script (basically downloads WordPress core files of the version specified in wp-cli.yml)
scripts/install.sh

```

## Update
```bash
# 1. Updates to the latest version (provide any wp core update options to modify update process)
scripts/update.sh

# 2. If updated wp-cli.yml will be updated to with the newer version for install.sh script to consider.

# 3. Commit changes

```


## Production
This is approximately how to update the projecton on production.
It should already have produciton decryption key to extract all secrets from production vault
```bash
# Assuming that the project is already on production and you want to update it
git pull origin main

# Updating submodules
git submodule update --init --recursive

# Deleting local env extracted before because it might interfere with the further extraction
rm .env.prod.local

# Sets up environtment
export APP_ENV=prod

# Bring the project to the current state according to composer.lock
composer install --no-dev --optimize-autoloader

# Extracts secrets from production vault
APP_RUNTIME_ENV=prod php bin/console secrets:decrypt-to-local --force

# Converts env file to a single php file (.env.local.php) for performance
composer dump-env prod

# Clears Symfony cache (if you don't use anything from Symfony then don't need to do this)
APP_ENV=prod APP_DEBUG=0 php bin/console cache:clear

# Runs installation script (basically downloads WordPress corse file of the version specified in wp-cli.yml)
scripts/install.sh

# Sets symlink for the wp-content folder to be accessible from the web
ln -s /path/to/the/project/src/WordPressContent /path/to/the/project/public-wp/content

# Sets ownership to your user and to give access to server (www-data group), change if server group is different.
sudo chown -R your-user-here:www-data ./*

# Restarts apache, or change it to restart a different type of server
sudo service apache2 restart
````
