{
  buildPecl,
  lib,
  fetchFromGitHub,
  libmcrypt,
  pkg-config,
}:

let
   version = "0.0.0";
   revision = "c37265eacdd0186cb3b0bfeb0e0104c8563807ef";
in
buildPecl {
  inherit version;

  pname = "mcrypt";

  src = fetchFromGitHub {
    owner = "php";
    repo = "php-src";
    rev = revision;
    sha256 = "sha256-aDiGbOqy2L8Qqd6IliEN19Oa8JO1uDSEju6uUN4b0XI=";
  } + "/ext/mcrypt";

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ libmcrypt ];

  configureFlags = [ "--with-mcrypt=${libmcrypt.outPath}" ];

  doCheck = true;
  checkTarget = "test";

  meta = {
    changelog = "https://github.com/php/php-src/commit/${revision}";
    description = "Mcrypt from 5.6.4";
  };
}
