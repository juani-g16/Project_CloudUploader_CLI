#! /bin/bash

setup() {
    # Install az cli if it's not already installed
    if ! command -v az >/dev/null 2>&1; then
        echo "Azure CLI could not be found"
        echo "Installing Azure CLI"
        curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
    fi
    echo "Azure CLI already installed"
    #Check whether there's an user logged in or proceed to log in otherwise
    if az ad signed-in-user show 2>&1 | grep -q "ERROR"; then
        echo "Logged off, please log in"
        az login --use-device-code
        echo "You're now logged in"
    else
        echo "Already logged in"
    fi
    # Login
}

check_file_exists() {
    if [ "$#" -eq 0 ]; then
        echo "Wrong use of script. Should be ./clouduploader.sh /path/to/file"
        exit 1
    fi

    if [ -f "$1" ]; then
        echo "File $1 exists"
    else
        echo "File $1 doesn't exist."
        echo "Check for correct path/filename"
    fi
}

# Print out 5 recommended regions
print_out_regions() {
    regions_array=($(az account list-locations --query "[?metadata.regionCategory=='Recommended'].{Name:name}" -o tsv | head -n 5))
    for i in "${regions_array[@]}"; do
        echo "$i"
    done
}

# Select a region
check_region() {
    local region_exists=false
    while [[ "$region_exists" = false ]]; do
        print_out_regions
        read -rp "Enter your region: " selected_region
        for j in "${regions_array[@]}"; do
            if [[ "$selected_region" == "$j" ]]; then
                region_exists=true
                echo "Selected region exists"
                break
            else
                continue
            fi
        done
    done
}

select_resource_group() {
    echo "Current resource group list"
    list_resource_groups
    while true; do
        read -rp "Create new resource group? (yes|no): " rg_answer
        case $rg_answer in
        yes | YES | Yes | y)
            echo "You answered yes."
            check_resource_group_exists
            break
            ;;
        no | NO | No | n)
            echo "You answered no. Select resource group from list."
            check_resource_group_not_exists
            break
            ;;
        *)
            echo "Invalid input. Only 'yes' or 'no' is accepted."
            ;;
        esac
    done

}

# Check if resource group already exists.
check_resource_group_exists() {
    while true; do
        read -rp "Enter a name for you resource group: " resource_group
        if [ "$(az group exists --name "$resource_group")" = true ]; then
            echo "The group $resource_group exists in $selected_region, please provide another name..."
        else
            break
        fi
    done
}

check_resource_group_not_exists() {
    while true; do
        read -rp "Enter a name for you resource group: " resource_group
        if [ "$(az group exists --name "$resource_group")" = false ]; then
            echo "The group $resource_group doesn't exists in $selected_region, please select one from the list..."
        else
            break
        fi
    done
}

# Create the resource group
create_resource_group() {
    echo "Creating resource group: $resource_group in $selected_region"
    az group create -g $resource_group -l $selected_region | grep provisioningState
}

#List all resource groups
list_resource_groups() {
    az group list -o table
    echo
}

setup

#check_file_exists $1

#check_region
# list_resource_groups
# check_resource_group
# create_resource_group
# list_resource_groups

select_resource_group
