{
  rustPlatform,
  lib,
  fetchFromGitHub,
  fetchurl,
  pkgs,
}:
rustPlatform.buildRustPackage rec {
  pname = "nearcore";
  version = "2.5.1";

  src = fetchFromGitHub {
    owner = "near";
    repo = "nearcore";
    tag = version;
    hash = "sha256-GFMC+paKlTcV1j5txtxL6tr+5Z7NMEBQdHDdlTNegWQ=";
  };
  cargoLock = {
    lockFile = "${src}/Cargo.lock";
    allowBuiltinFetchGit = true;
  };

  NEAR_RELEASE_BUILD = "release";

  OPENSSL_NO_VENDOR = 1; # we want to link to OpenSSL provided by Nix

  buildAndTestSubdir = "neard";
  doCheck = false; # needs network

  buildInputs = with pkgs; [
    zlib
    openssl
    llvm
    clang
    git
  ];

  nativeBuildInputs = [
    pkgs.pkg-config
    pkgs.protobuf
    rustPlatform.bindgenHook
  ];

  meta = with lib; {
    description = "Reference client for NEAR Protocol";
    homepage = "https://github.com/near/nearcore";
    license = licenses.gpl3;
    mainProgram = "neard";
  };
}
