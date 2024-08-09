<?php
// Load your custom and third party mu-plugins here if they are in subdirectories
if (file_exists(WPMU_PLUGIN_DIR.'/my-plugin/my-plugin.php')) {
    require WPMU_PLUGIN_DIR.'/my-plugin/my-plugin.php';
}
