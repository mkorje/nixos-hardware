{
  lib,
  pkgs,
  stdenv,
  ...
}:
let
  # See https://github.com/kholia/OSX-KVM/blob/master/fetch-macOS-v2.py
  # macOS Monterey or later!
  mlb = "00000000000000000";
  boardId = "Mac-4B682C642B45593E";
  osType = "latest";
  version = "13.6.6";
  name = "ventura";

  # from t2linux firmware.sh script, which is based on the wifi, bluetooth and core files in
  # https://github.com/AsahiLinux/asahi-installer/tree/main/asahi_firmware
  get-firmware = pkgs.writers.writePython3Bin "get-firmware" { } (builtins.readFile ./get_firmware.py);
in
  stdenv.mkDerivation {
    name = "brcm-firmware";

    src = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/acidanthera/OpenCorePkg/master/Utilities/macrecovery/macrecovery.py";
      name = "macOS-image-${version}";
      hash = "sha256-wZvRL1yxZRuHt00E8Cpjbadi6ka4HH68nyBfoql21Zk=";
      postFetch = ''
        set -euo pipefail
        ${pkgs.python3.interpreter} $downloadedFile -o . -n BaseSystem -b ${boardId} -m ${mlb} -os ${osType} download
        mv BaseSystem.dmg $out
      '';
      downloadToTemp = true;
    };

    dontUnpack = true;

    nativeBuildInputs = [ pkgs.dmg2img pkgs.p7zip get-firmware ];
    buildPhase = ''
      set -euo pipefail
      dmg2img -s $src fw.img
      7z x fw.img "macOS Base System/usr/share/firmware"
      get-firmware "macOS Base System/usr/share/firmware" firmware.tar
      mv firmware.tar $out
    '';

    installPhase = ''
      mkdir -p $out/lib/firmware/brcm
      tar -xf firmware.tar -C $out/lib/firmware/brcm
    '';
  }
