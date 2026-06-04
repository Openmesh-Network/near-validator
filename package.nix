{
  pkgs,
  ...
}:
let
  # Override rustPlatform's internal stdenv to use the pre-built gcc14Stdenv
  rustPlatformWithGcc14 = pkgs.rustPlatform.overrideScope (final: prev: {
    stdenv = pkgs.gcc14Stdenv;
  });
in
# Tell the builder to use our modified rustPlatform and gcc14Stdenv base
(rustPlatformWithGcc14.buildRustPackage.override { 
  stdenv = pkgs.gcc14Stdenv; 
}) rec {
  pname = "nearcore";
  version = "2.12.0";

  src = pkgs.fetchFromGitHub {
    owner = "near";
    repo = "nearcore";
    tag = version;
    hash = "sha256-oZkIE1dWh7HLlmIzQwc/LFVNB38hJkNDf3fGZwkxiFo=";
  };

  cargoLock = {
    lockFile = "${src}/Cargo.lock";
    outputHashes = {
      "bolero-0.10.0" = "sha256-758bPz+qMRLk+Pw51cJWM8GCo1cvsEOT+cRM3pMX7ZI=";
      "okapi-0.7.0" = "sha256-j/MqvHYfW8GzyQPrbg17O61JuYlQCKbFEwOz1hWxuSA=";
      "protobuf-3.0.2" = "sha256-HVNlMXZRNa9F8hr6sj75uuCvppR6mVOSumSLnye/F3Y=";
    };
  };

  patches = [
    ./disable-test-contracts-build.patch
  ];

  NEAR_RELEASE_BUILD = "release";
  OPENSSL_NO_VENDOR = 1;

  buildAndTestSubdir = "neard";
  doCheck = false;

  buildInputs = with pkgs; [
    openssl
    zlib
    zstd
    lz4
    snappy
  ];

  nativeBuildInputs = [
    pkgs.pkg-config
    # Make sure we use the bindgenHook from our modified scope!
    rustPlatformWithGcc14.bindgenHook
    pkgs.cmake
    pkgs.bzip2
    pkgs.gnumake
  ];

  meta = {
    description = "Reference client for NEAR Protocol";
    homepage = "https://github.com/near/nearcore";
    mainProgram = "neard";
  };
}
