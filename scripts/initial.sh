# Generates cryptographic keys for Symfony Vault for prod
APP_RUNTIME_ENV=prod php bin/console secrets:generate-keys

function store_in_vault() {
  KEY_VALUE="$(cat wp-config.php | sed -n "s/^.*'${1}', '\(.*\)'.*$/\1/p")" 
  APP_RUNTIME_ENV=prod php bin/console secrets:set ${1} <<< ${KEY_VALUE}
}

function store_in_env() {
  KEY_VALUE="$(cat wp-config.php | sed -n "s/^.*'${1}', '\(.*\)'.*$/\1/p")"
  ESCAPED_KEY_VALUE=$(printf '%s\n' "$KEY_VALUE" | sed -e 's/[\/&~]/\\&/g');
  sed -i '' "s/${1}=.*/${1}='${ESCAPED_KEY_VALUE}'/" ${2}
}

KEYS=("AUTH_KEY" "SECURE_AUTH_KEY" "LOGGED_IN_KEY" "NONCE_KEY" "AUTH_SALT" "SECURE_AUTH_SALT" "LOGGED_IN_SALT" "NONCE_SALT")

# Store WP salts to prod
vendor/bin/wp config shuffle-salts
for KEY in ${KEYS[@]}; do
  store_in_vault $KEY
done

# Store WP salts to local
if [ ! -f .env.local ]; then
  cp .env .env.local
fi
vendor/bin/wp config shuffle-salts
for KEY in ${KEYS[@]}; do
  store_in_env $KEY .env.local
done

# Restore wp-config.php
for KEY in ${KEYS[@]}; do
  sed -i '' "s/define('${KEY}', '.*')/define('${KEY}', \$_ENV['${KEY}'])/" wp-config.php
done

