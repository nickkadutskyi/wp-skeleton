<?php

/**
 * The base configuration for WordPress
 *
 * The wp-config.php creation script uses this file during the installation.
 * You don't have to use the web site, you can copy this file to "wp-config.php"
 * and fill in the values.
 *
 * This file contains the following configurations:
 *
 * * Database settings
 * * Secret keys
 * * Database table prefix
 * * ABSPATH
 *
 * @link https://wordpress.org/documentation/article/editing-wp-config-php/
 *
 * @package WordPress
 */


use Symfony\Component\Dotenv\Dotenv;


require_once __DIR__ . '/vendor/autoload.php';

$dotenv = new Dotenv();

$dotenv->bootEnv(__DIR__ . '/.env');

// Sets WP's environment
define('WP_ENVIRONMENT_TYPE', $_ENV['WP_ENVIRONMENT_TYPE']);
// Points to a proper content dir and URL
const WP_CONTENT_DIR = __DIR__ . '/src/WordPressContent';
// TODO for this to work create a symlink public-wp/content that points to src/WordPressContent
define('WP_CONTENT_URL', $_ENV['WP_SITEURL'] . '/content');
// Points to uploads in public-wp
const UPLOADS = 'uploads';
// Site URL is coming from ENV
define('WP_SITEURL', $_ENV['WP_SITEURL']);
// When on production prevent certain actions
define('DISALLOW_FILE_EDIT', $_ENV['DISALLOW_FILE_EDIT']);
define('DISALLOW_FILE_MODS', $_ENV['DISALLOW_FILE_MODS']);
define('AUTOMATIC_UPDATER_DISABLED', $_ENV['AUTOMATIC_UPDATER_DISABLED']);
// Control auto update setting via ENV
define('WP_AUTO_UPDATE_CORE', $_ENV['WP_AUTO_UPDATE_CORE']);

// ** Database settings - You can get this info from your web host ** //

/** The name of the database for WordPress */
define('DB_NAME', $_ENV['DB_NAME']);

/** Database username */
define('DB_USER', $_ENV['DB_USER']);

/** Database password */
define('DB_PASSWORD', $_ENV['DB_PASSWORD']);

/** Database hostname */
define('DB_HOST', $_ENV['DB_HOST']);

/** Database charset to use in creating database tables. */
define('DB_CHARSET', $_ENV['DB_CHARSET']);

/** The database collate type. Don't change this if in doubt. */
define('DB_COLLATE', $_ENV['DB_COLLATE']);

/**#@+
 * Authentication unique keys and salts.
 *
 * Change these to different unique phrases! You can generate these using
 * the {@link https://api.wordpress.org/secret-key/1.1/salt/ WordPress.org secret-key service}.
 *
 * You can change these at any point in time to invalidate all existing cookies.
 * This will force all users to have to log in again.
 *
 * @since 2.6.0
 */

define('AUTH_KEY', $_ENV['AUTH_KEY']);
define('SECURE_AUTH_KEY', $_ENV['SECURE_AUTH_KEY']);
define('LOGGED_IN_KEY', $_ENV['LOGGED_IN_KEY']);
define('NONCE_KEY', $_ENV['NONCE_KEY']);
define('AUTH_SALT', $_ENV['AUTH_SALT']);
define('SECURE_AUTH_SALT', $_ENV['SECURE_AUTH_SALT']);
define('LOGGED_IN_SALT', $_ENV['LOGGED_IN_SALT']);
define('NONCE_SALT', $_ENV['NONCE_SALT']);


/**#@-*/


/**
 * WordPress database table prefix.
 *
 * You can have multiple installations in one database if you give each
 * a unique prefix. Only numbers, letters, and underscores please!
 */

$table_prefix = $_ENV['TABLE_PREFIX'];


/**
 * For developers: WordPress debugging mode.
 *
 * Change this to true to enable the display of notices during development.
 * It is strongly recommended that plugin and theme developers use WP_DEBUG
 * in their development environments.
 *
 * For information on other constants that can be used for debugging,
 * visit the documentation.
 *
 * @link https://wordpress.org/documentation/article/debugging-in-wordpress/
 */

define('WP_DEBUG', $_ENV['APP_ENV'] === "dev");


/* Add any custom values between this line and the "stop editing" line. */


/* That's all, stop editing! Happy publishing. */


/** Absolute path to the WordPress directory. */

if (!defined('ABSPATH')) {

    define('ABSPATH', __DIR__ . '/');

}

/** Sets up WordPress vars and included files. */

require_once ABSPATH . 'wp-settings.php';

