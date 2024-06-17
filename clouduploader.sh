#! /bin/bash

setup() {
    # Install az cli if it's not already installed
    if ! command -v az >/dev/null 2>&1
    then
        echo "Azure CLI could not be found"
        echo "Installing Azure CLI"
        curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
    else
        echo "Azure CLI already installed" 
        #Check whether there's an user logged in or proceed to log in otherwise
        if az ad signed-in-user show 2>&1 | grep -q "ERROR"; then 
            echo "Logged off, please log in"
            az login --use-device-code
            echo "You're now logged in"
        else
            echo "Already logged in"
        fi
    fi
    # Login
    
}

setup