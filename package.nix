{
  pkgs,
  ...
}:
(pkgs.rustPlatform.buildRustPackage.override { stdenv = pkgs.gcc14Stdenv; }) rec {
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

  # Note: Since we didn't specify JEMALLOC_OVERRIDE, tikv-jemalloc-sys will build 
  # from source using GCC 14, but we need to feed it bzip2/gnumake.
  buildInputs = with pkgs; [
    openssl
    zlib
    zstd
    lz4
    snappy
  ];

  nativeBuildInputs = [
    pkgs.pkg-config
    pkgs.rustPlatform.bindgenHook
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
