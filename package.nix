{
  pkgs,
  ...
}:
pkgs.rustPlatform.buildRustPackage rec {
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
  OPENSSL_NO_VENDOR = 1; # we want to link to OpenSSL provided by Nix
  
  # Tell rocksdb-sys to use the system jemalloc instead of trying to build its own inside the sandbox
  ROCKSDB_LIB_DIR = "${pkgs.rocksdb}/lib";
  ROCKSDB_INCLUDE_DIR = "${pkgs.rocksdb}/include";
  JEMALLOC_OVERRIDE = "1";

  # Ensure the C++ compiler links against the standard library properly during cc-rs execution
  NIX_LDFLAGS = "-lstdc++";

  buildAndTestSubdir = "neard";
  doCheck = false; # needs network

  buildInputs = with pkgs; [
    openssl
    jemalloc
    rocksdb
    zlib
    zstd
    lz4
    snappy
  ];

  nativeBuildInputs = [
    pkgs.pkg-config
    pkgs.rustPlatform.bindgenHook
    pkgs.cmake # rocksdb-sys / jemalloc-sys often require cmake to configure internal bindings
  ];

  meta = {
    description = "Reference client for NEAR Protocol";
    homepage = "https://github.com/near/nearcore";
    mainProgram = "neard";
  };
}
