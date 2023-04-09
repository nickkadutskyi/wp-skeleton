#!/bin/bash
WP_DIR="./public-wp"
CONTENT_DIR="./src/WordPressContent"
WP_DEFAULT_PREFIX="wp-default-"
if [ ! -d "$WP_DIR" ]; then
  echo "Not in project root"
  exit 1
fi
if [ ! -e vendor/bin/wp ]; then
  echo "WP-CLI is not present at vendor/bin/wp"
  exit 1
fi
CURRENT_VERSION=$(vendor/bin/wp core version)
UPDATE_RESULT=$(vendor/bin/wp core update "$@" 2> /dev/null)
UPDATE_DB_RESULT=$(vendor/bin/wp core update-db 2> /dev/null)
NEW_VERSION=$(vendor/bin/wp core version)
for d in public-wp/wp-content/themes/*/ ; do
    THEME_NAME=$(basename "$d")
    THEME_DEST="$CONTENT_DIR/themes/$WP_DEFAULT_PREFIX$THEME_NAME"
    if [ -d "$THEME_DEST" ]; then
      rm -rf "$THEME_DEST"
    fi
    mv "$d" "$THEME_DEST"
done
for d in public-wp/wp-content/plugins/*/ ; do
    PLUGIN_NAME=$(basename "$d")
    PLUGIN_DEST="$CONTENT_DIR/plugins/$WP_DEFAULT_PREFIX$PLUGIN_NAME"
    if [ -d "$PLUGIN_DEST" ]; then
      rm -rf "$PLUGIN_DEST"
    fi
    mv "$d" "$PLUGIN_DEST"
done
mv "$WP_DIR/wp-content/plugins/hello.php" "$CONTENT_DIR/plugins/${WP_DEFAULT_PREFIX}hello.php"
echo "$CURRENT_VERSION to $NEW_VERSION"
echo "$UPDATE_RESULT"
echo "$UPDATE_DB_RESULT"

if [ "$NEW_VERSION" != "$CURRENT_VERSION" ]; then
    echo "UPDATED"
    sed -i'.original' -e "s/$CURRENT_VERSION/$NEW_VERSION/g" ./wp-cli.yml
    rm ./*.original
else
    echo "NOT UPDATED"
fi
