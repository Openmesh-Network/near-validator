{
  rustPlatform,
  lib,
  fetchFromGitHub,
  fetchurl,
  pkgs,
}:
rustPlatform.buildRustPackage rec {
  pname = "nearcore";
  version = "2.6.1";

  src = fetchFromGitHub {
    owner = "near";
    repo = "nearcore";
    tag = version;
    hash = "sha256-wkpt0Iz9egx9VXqPdT4uzmbLQPjucqITFw7x4M1FEwQ=";
  };

  cargoLock = {
    lockFile = "${src}/Cargo.lock";
    outputHashes = {
      "bolero-0.10.0" = "sha256-758bPz+qMRLk+Pw51cJWM8GCo1cvsEOT+cRM3pMX7ZI=";
      "protobuf-3.0.2" = "sha256-HVNlMXZRNa9F8hr6sj75uuCvppR6mVOSumSLnye/F3Y=";
    };
  };

  patches = [
    ./disable-test-contracts-build.patch
  ];

  NEAR_RELEASE_BUILD = "release";
  OPENSSL_NO_VENDOR = 1; # we want to link to OpenSSL provided by Nix

  buildAndTestSubdir = "neard";
  doCheck = false; # needs network

  buildInputs = with pkgs; [
    zlib
    openssl
    llvm
    clang
  ];

  nativeBuildInputs = [
    pkgs.pkg-config
    pkgs.protobuf
    rustPlatform.bindgenHook
  ];

  meta = with lib; {
    description = "Reference client for NEAR Protocol";
    homepage = "https://github.com/near/nearcore";
    mainProgram = "neard";
  };
}
