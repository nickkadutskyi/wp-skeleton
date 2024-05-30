{pkgs, config, vhostVars, isSslEnabled}:
let
socket = config.languages.php.fpm.pools.${vhostVars.ServerName}.socket;
in
pkgs.writeText (vhostVars.ServerName + ".conf") ''
<VirtualHost ${if isSslEnabled then ''*:443'' else ''*:80''}>
    DocumentRoot ${vhostVars.DocumentRoot}
    ServerName ${vhostVars.ServerName}
    ServerAlias ${vhostVars.ServerName}* www.${vhostVars.ServerName}
    ErrorLog "/private/var/log/apache2/${vhostVars.ServerName}-error_log"
    CustomLog "/private/var/log/apache2/${vhostVars.ServerName}-access_log" common
    SetEnvIfNoCase ^Authorization$ "(.+)" HTTP_AUTHORIZATION=$1

    ${if isSslEnabled then ''# SSL Configuration
    SSLEngine on
    SSLCertificateFile ${config.env.DEVENV_STATE}/mkcert/${vhostVars.ServerName}.pem
    SSLCertificateKeyFile ${config.env.DEVENV_STATE}/mkcert/${vhostVars.ServerName}-key.pem
    SSLCertificateChainFile ${config.env.DEVENV_STATE}/mkcert/rootCA.pem''
    else ''# SSL is enabled in ${vhostVars.ServerName}-ssl.conf file''}

    <FilesMatch "\.php$">
      # SetHandler "proxy:unix:${config.env.DEVENV_STATE}/php-fpm/${vhostVars.ServerName}.sock|fcgi://localhost/"
      SetHandler "proxy:fcgi://127.0.0.1:3005"
    </FilesMatch>

    <Directory "${vhostVars.DocumentRoot}">
      # Options Indexes FollowSymLinks
      # AllowOverride All
      Options Indexes Includes FollowSymLinks SymLinksIfOwnerMatch
      AllowOverride All

      <IfModule authz_host_module>
            Require all granted
      </IfModule>

      Options Indexes FollowSymLinks
      AllowOverride All
    </Directory>

</VirtualHost>

${if !isSslEnabled then ''
# Enable 'status' and 'ping' pages for monitoring php-fpm
<LocationMatch "/(ping|status)">
    SetHandler "proxy:fcgi://127.0.0.1:3005"
</LocationMatch>
''
else ''# /ping and /status are enabled in ${vhostVars.ServerName}.conf file''}
''
