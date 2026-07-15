{
  pkgs,
  rustPlatform,
  ...
}:
rustPlatform.buildRustPackage rec {
  pname = "nearcore";
  version = "2.13.1";

  src = pkgs.fetchFromGitHub {
    owner = "near";
    repo = "nearcore";
    tag = version;
    hash = "sha256-hXtOZb73V3NBQ5RLech/TCklNiScVegxdwLnBDhDk98=";
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
  ];

  nativeBuildInputs = [
    pkgs.pkg-config
    rustPlatform.bindgenHook
  ];

  meta = {
    description = "Reference client for NEAR Protocol";
    homepage = "https://github.com/near/nearcore";
    mainProgram = "neard";
  };
}
