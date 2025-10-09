alias install-unleashed := hedge-install-unleashed
alias setup-dawbox := hedge-setup-dawbox

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
    sudo flatpak install -y flatpak install "$TEMP_DIR"/io.github.hedge_dev.unleashedrecomp.flatpak

    if [ $(flatpak list | grep io.github.hedge_dev.unleashedrecomp.flatpak >/dev/null; echo $?) ]; then
      echo "Failed to install flatpak..."
      exit 1
    fi
    echo "Successfully installed Unleashed Recompiled!"

# Set up or manage a Dawbox container (https://github.com/Messaiga/DAWbox)
[group ('hedgehogOS-audio')]
hedge-setup-dawbox ACTION="":
    #!/usr/bin/bash
    set -euo pipefail
    TEMP_DIR=$(mktemp -d)
    trap 'rm -rf "$TEMP_DIR"' EXIT

    # import ujust library as well as dawbox functions from upstream install script
    import /usr/lib/ujust/ujust.sh
    curl --retry 3 -sL https://raw.githubusercontent.com/Messaiga/DAWbox/refs/heads/main/install.sh -o "$TEMP_DIR/install.sh" \
    && chmod +x "$TEMP_DIR/install.sh" && import "$TEMP_DIR/install.sh"

    STATUS="$(dawbox_check >/dev/null | echo $?)"
    if [[ $STATUS == "0" ]]; then
      DAWBOX_STATE="${green}${b}installed${n}"
    else
      DAWBOX_STATE="${red}${b}not installed${n}"
    fi

    OPTION={{ ACTION }}
    if [ "$OPTION" == "help" ]; then
      echo "Usage: ujust hedge-setup-dawbox <option>"
      echo "  <option>: Specify the quick option to skip the prompt"
      echo "  Use 'install' to install dawbox"
      echo "  Use 'uninstall' to remove dawbox"
      echo "  Use 'update' to update dawbox (or install if not already present)"
      echo "  Use 'fontcache' to update fontcache inside dawbox"
      exit 0
    elif [ "$OPTION" == "" ]; then
      echo "${bold}dawbox status${normal}"
      echo "dawbox is $DAWBOX_STATE"
      OPTION=$(Choose "Install dawbox" "Uninstall dawbox" "Update dawbox" "Configure dawbox" "Run fontcache")
    fi
    if [[ "${OPTION,,}" =~ ^install ]]; then
      if [[ "${DAWBOX_STATE,,}" =~ "^install" ]]; then
        echo "${red} dawbox has already been installed!"
        exit 0
      fi
      dawbox_install
    elif [[ "${OPTION,,}" =~ "^(uninstall|remove)" ]]; then
      if [[ "${DAWBOX_STATE,,}" =~ "^not" ]]; then
        echo "${red} dawbox is already not installed!"
        exit 0
      fi
      dawbox_rm
    elif [[ "${OPTION,,}" =~ "^update" ]]; then
      if [[ "${DAWBOX_STATE,,}" =~ "^not" ]]; then
        echo "${yellow} dawbox is not present, executing install instead of updating..."
        dawbox_install
        exit 0
      fi
      dawbox_update
    elif [[ "${OPTION,,}" =~ "^font" ]]; then
      if [[ "${DAWBOX_STATE,,}" =~ "^not" ]]; then
        echo "${red} dawbox is not installed!"
        exit 0
      fi
      distrobox-enter dawbox -- sudo fc-cache -Ers
    fi

