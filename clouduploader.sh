#! /bin/bash

setup() {
    # Install az cli
    if ! $(command -v az) >/dev/null 2>&1
    then
        echo "Azure CLI could not be found"
        echo "Installing Azure CLI"
        curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
    else
        echo "Azure CLI found, proceeding to log in"
        az login --use-device-code
        echo "You're logged in."
    fi
    # Login
    
}

setup