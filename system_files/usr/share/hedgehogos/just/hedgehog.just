# Download and install Unleashed Recompiled as a Flatpak (you will need to provide your own game assets! see https://github.com/hedge-dev/UnleashedRecomp?tab=readme-ov-file#how-to-install)
[group('gaming')]
hedge-install-unleashed:
    #!/usr/bin/bash
    set -euo pipefail
    TEMP_DIR=$(mktemp -d)
    trap 'rm -rf "$TEMP_DIR"' EXIT

    echo "Getting and installing Unleashed Recompiled..."
    # get latest flatpak using this trick https://gist.github.com/steinwaywhw/a4cd19cda655b8249d908261a62687f8
    curl -s https://api.github.com/repos/hedge-dev/UnleashedRecomp/releases/latest \
    | grep "browser_download_url.*-Flatpak.zip" \
    | cut -d : -f 2,3 \
    | tr -d \" \
    | wget -qi -P "$TEMP_DIR" -

    if [ ! -f "$TEMP_DIR"/UnleashedRecomp-Flatpak.zip ]; then
      echo "Failed to download zip archive, check your internet connection."
      exit 1
    fi
    echo "Successfully downloaded zip archive..."

    unzip "$TEMP_DIR"/UnleashedRecomp-Flatpak.zip -d "$TEMP_DIR"
    sudo flatpak install -y flatpak install "$TEMP_DIR"/io.github.hedge_dev.unleashedrecomp.flatpak

    if [ $(flatpak list | grep io.github.hedge_dev.unleashedrecomp.flatpak >/dev/null; echo $?) ]; then
      echo "Failed to install flatpak..."
      exit 1
    fi
    echo "Successfully installed Unleashed Recompiled!"
