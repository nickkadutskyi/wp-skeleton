{
  inputs = {
    nixpkgs.url = "github:cachix/devenv-nixpkgs/rolling";
    systems.url = "github:nix-systems/default";
    devenv.url = "github:cachix/devenv/latest";
    devenv.inputs.nixpkgs.follows = "nixpkgs";
  };

  inputs.phps.url = "github:fossar/nix-phps";
  inputs.phps.inputs = { nixpkgs.follows = "nixpkgs"; };


  # Adds the Cachix cache to the Nix configuration
  nixConfig = {
    extra-trusted-public-keys = "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
    extra-substituters = "https://devenv.cachix.org";
  };

  outputs = { self, nixpkgs, devenv, systems, phps, ... } @ inputs:
    let
      forEachSystem = nixpkgs.lib.genAttrs (import systems);
    in
    {
      packages = forEachSystem (system: {
        devenv-up = self.devShells.${system}.default.config.procfileScript;
      });

      devShells = forEachSystem
        (system:
          let
            config = self.devShells.${system}.default.config;
            mkDevShellPackage = config: pkgs: import ./devenv-devShell-custom.nix { inherit config pkgs; };
            pkgs = nixpkgs.legacyPackages.${system};
            devenvRoot = self.devShells.${system}.default.config.env.DEVENV_ROOT;
            # VirtualHost Configuration
            vhostVars = {
              DocumentRoot = config.env.VHOST_DOCUMENT_ROOT or (devenvRoot + "/public-wp");
              ServerName = (config.env.VHOST_SERVER_NAME or "wpskeleton.test");
              Root = config.env.VHOST_ROOT or "/etc/apache2/other";
            };
            # TODO make it dynamic
            ServerName = "wpskeleton.test";
            mkVhostFile = isSslEnabled: import ./vhost.nix { inherit pkgs config vhostVars isSslEnabled; };
            vhostConfig = mkVhostFile false;
            vhostConfigSSL = mkVhostFile true;
          in
          {
            default = devenv.lib.mkShell {
              inherit inputs pkgs;
              modules = [
                {
                  dotenv.enable = true;
                  # https://devenv.sh/reference/options/
                  packages = with pkgs; [
                    php83Packages.php-cs-fixer
                  ];

                  enterShell = ''
                    if [[ ! -d "${config.env.DEVENV_STATE}/php" ]] then
                      mkdir "${config.env.DEVENV_STATE}/php"
                    fi
                    echo "run 'devenv-custom up path:nix' to configure and start server."
                  '';
                  process.process-compose = {
                    version = "0.5";
                    unix-socket = "${config.devenv.runtime}/pc.sock";
                    tui = false;
                  };

                  # MySQL Configuration
                  services.mysql.enable = true;
                  # The default is MariaDB. To use MySQL instead:
                  # services.mysql.package = pkgs.mysql80;
                  services.mysql.initialDatabases = [{ name = config.env.DB_NAME or "wp_skeleton"; }];

                  # PHP Configuration
                  languages.php = {
                    enable = true;
                    version = "8.1";
                    extensions = [ "xdebug" ];

                    disableExtensions = [ "opcache" ];
                    ini = ''
                      memory_limit=256M
                      log_errors_max_len=0
                      error_log=${config.env.DEVENV_STATE}/php/php-${vhostVars.ServerName}-error.log
                      log_errors=true
                      error_reporting=E_ALL | E_STRICT
                      display_errors=false
                      date.timezone=America/Los_Angeles
                      xdebug.remote_enable=1
                      xdebug.max_nesting_level=512
                    '';
                    fpm = {
                      settings = {
                        "error_log" = config.env.DEVENV_STATE + "/php-fpm/php-fpm-error.log";
                        "log_level" = "alert";
                      };
                      pools.${vhostVars.ServerName} = {
                        listen = "127.0.0.1:3005";
                        settings = {
                          "listen.allowed_clients" = "127.0.0.1";
                          "listen.mode" = "0660";
                          "pm" = "dynamic";
                          "pm.max_children" = 50;
                          "pm.start_servers" = 2;
                          "pm.min_spare_servers" = 1;
                          "pm.max_spare_servers" = 5;
                          "pm.process_idle_timeout" = 30;
                          "pm.max_requests" = 500;
                          "pm.status_path" = "/status";
                          "ping.path" = "/ping";
                          "ping.response" = "pong";
                          "request_terminate_timeout" = 0;
                          "slowlog" = config.env.DEVENV_STATE + "/php-fpm/php-fpm-slow.log";
                          "security.limit_extensions" = ".php .php5";
                          "access.log" = config.env.DEVENV_STATE + "/php-fpm/php-fpm-${vhostVars.ServerName}-access.log";
                          "catch_workers_output" = "yes";
                        };
                      };
                    };
                  };

                  # SSL Certificate for vhost
                  certificates = [
                    ServerName
                  ];

                  # Adds vhost to built-in Apache server
                  process.before = ''
                    if [ "$(readlink -- "${vhostVars.Root}/${vhostVars.ServerName}.conf")" = "${vhostConfig}" ]; then
                      echo "Vhost is already configured"
                    else
                      echo "Configuring Vhost"
                      sudo ln -sf ${vhostConfig} ${vhostVars.Root}/${vhostVars.ServerName}.conf
                    fi
                    if [ "$(readlink -- "${vhostVars.Root}/${vhostVars.ServerName}-ssl.conf")" = "${vhostConfigSSL}" ]; then
                      echo "SSL Vhost is already configured"
                    else
                      echo "Configuring SSL Vhost"
                      sudo ln -sf ${vhostConfigSSL} ${vhostVars.Root}/${vhostVars.ServerName}-ssl.conf
                    fi
                     sudo apachectl restart
                  '';
                  process.after = ''
                    if [ "$(readlink -- "${vhostVars.Root}/${vhostVars.ServerName}.conf")" = "${vhostConfig}" ]; then
                      echo "Clearing Vhost configuration"
                      sudo rm ${vhostVars.Root}/${vhostVars.ServerName}.conf
                    fi
                    if [ "$(readlink -- "${vhostVars.Root}/${vhostVars.ServerName}-ssl.conf")" = "${vhostConfigSSL}" ]; then
                      echo "Clearing SSL Vhost configuration"
                      sudo rm ${vhostVars.Root}/${vhostVars.ServerName}-ssl.conf
                    fi
                     sudo apachectl restart
                  '';

                  # Adds Apache log tracker process
                  processes.apache-access-logs.exec = ''
                    if [ ! -f "/var/log/apache2/${vhostVars.ServerName}-access_log" ]; then
                      sudo touch "/var/log/apache2/${vhostVars.ServerName}-access_log"
                    fi
                    tail -f -n0 "/var/log/apache2/${vhostVars.ServerName}-access_log"
                  '';
                  processes.apache-error-logs.exec = ''
                    if [ ! -f "/var/log/apache2/${vhostVars.ServerName}-error_log" ]; then
                      sudo touch "/var/log/apache2/${vhostVars.ServerName}-error_log"
                    fi
                    tail -f -n0 "/var/log/apache2/${vhostVars.ServerName}-error_log"
                  '';
                  # Adds PHP log tracker process
                  processes.php-error-logs.exec = ''
                    if [ ! -f "${config.env.DEVENV_STATE}/php/php-${vhostVars.ServerName}-error.log" ]; then
                      touch "${config.env.DEVENV_STATE}/php/php-${vhostVars.ServerName}-error.log"
                    fi
                    tail -f -n0 "${config.env.DEVENV_STATE}/php/php-${vhostVars.ServerName}-error.log"
                  '';
                }
                # Creates custom devenv script to handle nix store bloat issue
                ({ config, ... }: {
                  packages = [
                    (mkDevShellPackage config pkgs)
                  ];
                })
              ];
            };
          });
    };
}
