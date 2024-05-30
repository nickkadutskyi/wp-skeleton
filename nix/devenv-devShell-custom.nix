{ config, pkgs }:
let
  lib = pkgs.lib;
  shellPrefix = shellName: if shellName == "default" then "" else "${shellName}-";
in
pkgs.writeScriptBin "devenv-custom" ''
  #!/usr/bin/env bash

  # we want subshells to fail the program
  set -e

  NIX_FLAGS="--show-trace --extra-experimental-features nix-command --extra-experimental-features flakes"

  command=$1
  if [[ ! -z $command ]]; then
    shift
  fi

  flakePath=$1
  if [[ $flakePath == "path:"* ]]; then
    shift
  else
    flakePath="."
  fi

  case $command in
    up)
      procfilescript=$(nix build $flakePath#'${shellPrefix (config._module.args.name or "default")}devenv-up' --no-link --print-out-paths --impure)
      if [ "$(cat $procfilescript|tail -n +2)" = "" ]; then
        echo "No 'processes' option defined: https://devenv.sh/processes/"
        exit 1
      else
        echo "Executing procfilescript: $procfilescript"
        exec $procfilescript "$@"
      fi
      ;;
    *)
      echo "This is a flake integration wrapper that comes with a subset of functionality from the flakeless devenv CLI."
      echo
      echo "Usage: devenv-custom command"
      echo
      echo "Commands:"
      echo
      echo "up              Starts processes in foreground. See http://devenv.sh/processes"
      echo
      exit 1
  esac
''
