alias install-unleashed := hedge-install-unleashed
alias setup-dawbox := hedge-setup-dawbox
alias config-kde-fonts := hedge-config-kde-fonts

# Set Atkinson Hyperlegible as the default font family in KDE
[group('hedgehogOS-config')]
hedge-config-kde-fonts:
    #!/usr/bin/bash
    set -euo pipefail

    kwriteconfig6 --group General --key font 'Atkinson Hyperlegible Next Light,10,-1,5,300,0,0,0,0,0,0,0,0,0,0,1,Regular'
    kwriteconfig6 --group General --key fixed 'Atkinson Hyperlegible Mono,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1'
    kwriteconfig6 --group General --key menuFont 'Atkinson Hyperlegible Next Light,10,-1,5,300,0,0,0,0,0,0,0,0,0,0,1,Regular'
    kwriteconfig6 --group General --key toolBarFont 'Atkinson Hyperlegible Next Light,9,-1,5,300,0,0,0,0,0,0,0,0,0,0,1,Regular'
    kwriteconfig6 --group General --key smallestReadableFont 'Atkinson Hyperlegible Next Light,8,-1,5,300,0,0,0,0,0,0,0,0,0,0,1,Regular'

    echo "KDE fonts applied!"

# Install all hedgehogOS apps
[group('hedgehogOS-apps')]
hedge-install-apps: hedge-install-flatpaks hedge-install-unleashed

# Install hedgehogOS Flatpaks from Flathub
[group('hedgehogOS-apps')]
hedge-install-flatpaks:
    #!/usr/bin/bash
    set -euo pipefail

    echo "Installing Flatpaks..."
    xargs -a <(curl --retry 3 -sL https://raw.githubusercontent.com/lotsospaghetti/hedgehogOS/main/repo_files/flatpaks) flatpak --system -y install
    echo "Flatpaks installed!"

    echo "Applying Flatpak overrides... (require sudo)"
    sudo flatpak override org.kde.skanlite --filesystem=home
    echo "Overrides applied!"

# Download and install Unleashed Recompiled (you'll need to provide game files yourself!) (https://github.com/hedge-dev/UnleashedRecomp)
[group('hedgehogOS-gaming')]
hedge-install-unleashed:
    #!/usr/bin/bash
    set -euo pipefail
    TEMP_DIR=$(mktemp -d)
    trap 'rm -rf "$TEMP_DIR"' EXIT

    echo "Getting and installing Unleashed Recompiled..."
    # get latest flatpak using this trick https://gist.github.com/steinwaywhw/a4cd19cda655b8249d908261a62687f8
    curl --retry 3 -s https://api.github.com/repos/hedge-dev/UnleashedRecomp/releases/latest \
    | grep "browser_download_url.*-Flatpak.zip" \
    | cut -d : -f 2,3 \
    | tr -d \" \
    | wget -P "$TEMP_DIR" -qi -

    if [ ! -f "$TEMP_DIR"/UnleashedRecomp-Flatpak.zip ]; then
      echo "Failed to download zip archive, check your internet connection."
      exit 1
    fi
    echo "Successfully downloaded zip archive..."

    unzip "$TEMP_DIR"/UnleashedRecomp-Flatpak.zip -d "$TEMP_DIR"
    sudo flatpak install -y "$TEMP_DIR"/io.github.hedge_dev.unleashedrecomp.flatpak

    if [ $(flatpak list | grep io.github.hedge_dev.unleashedrecomp >/dev/null; echo $?) ]; then
      echo "Failed to install flatpak..."
      exit 1
    fi
    echo "Successfully installed Unleashed Recompiled!"

# Set up or manage a Dawbox container (https://github.com/Messaiga/DAWbox)
[group ('hedgehogOS-audio')]
hedge-setup-dawbox:
    #!/usr/bin/sh
    TEMP_DIR=$(mktemp -d)
    trap 'rm -rf "$TEMP_DIR"' EXIT

    # pull dawbox script from upstream and execute it
    curl --retry 3 -sL https://raw.githubusercontent.com/Messaiga/DAWbox/refs/heads/main/install.sh -o "$TEMP_DIR/install.sh" \
    && chmod +x "$TEMP_DIR/install.sh" && /usr/bin/sh "$TEMP_DIR/install.sh"
