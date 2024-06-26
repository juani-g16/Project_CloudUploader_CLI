#! /bin/bash

#---------------------------------SETUP AND SCRIPT USSAGE------------------------------------#
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
        echo "File '$1' exists"
    else
        echo "File '$1' doesn't exist."
        echo "Check for correct path/filename"
    fi
}
#-------------------------------END SETUP AND SCRIPT USSAGE-----------------------------------#

#----------------------------------------REGION SETUP-----------------------------------------#
# Print out 10 recommended regions
print_out_regions() {
    mapfile -t regions_array < <(az account list-locations --query "[?metadata.regionCategory=='Recommended'].{Name:name}" -o tsv | head -n 10)
    for i in "${regions_array[@]}"; do
        echo "$i"
    done
}

# Select a region
select_region() {
    local region_exists=false
    echo Please, select a region from the list.
    while [[ "$region_exists" = false ]]; do
        print_out_regions
        read -rp "Enter your region: " selected_region
        for j in "${regions_array[@]}"; do
            if [[ "$selected_region" == "$j" ]]; then
                region_exists=true
                echo "Region '$selected_region' correctly selected"
                break
            else
                continue
            fi
        done
    done
}

#-------------------------------------END REGION SETUP-----------------------------------------#

#---------------------------------RESOURCE GROUP SETUP-----------------------------------------#
#Print out all resource groups
print_out_rg() {
    mapfile -t rg_array < <(az group list --query "[].{Name:name}" -o tsv)
    for i in "${rg_array[@]}"; do
        echo "$i"
    done
}

# Select already existent resource group
check_rg_list() {
    local rg_exists=false
    while [[ "$rg_exists" = false ]]; do
        print_out_rg
        read -rp "Enter your resource group from the list: " resource_group
        for j in "${rg_array[@]}"; do
            if [[ "$resource_group" == "$j" ]]; then
                rg_exists=true
                echo "Resource group correctly selected."
                break
            else
                continue
            fi
        done
    done
}

# Check if resource group already exists.
check_rg_exists() {
    while true; do
        read -rp "Enter a name for your resource group: " resource_group
        if [ "$(az group exists --name "$resource_group")" = true ]; then
            echo "The group '$resource_group' already exists, please provide another name..."
        else
            echo "The group name '$resource_group' can be used."
            break
        fi
    done
}

# Create the resource group
create_rg() {
    echo "Creating resource group: '$resource_group' in '$selected_region'"
    az group create -g "$resource_group" -l "$selected_region" | grep provisioningState
}

#Create new resource group or select one from list
select_rg() {
    while true; do
        read -rp "Create new resource group? (yes|no): " rg_answer
        case $rg_answer in
        yes | YES | Yes | y)
            echo "You answered yes."
            check_rg_exists
            create_rg
            break
            ;;
        no | NO | No | n)
            echo "You answered no. Select resource group from list."
            check_rg_list
            break
            ;;
        *)
            echo "Invalid input. Only 'yes' or 'no' is accepted."
            ;;
        esac
    done
}

#-------------------------------------END RESOURCE GROUP SETUP-----------------------------------#

#--------------------------------------STORAGE ACCOUNT SETUP-------------------------------------#
#Print out all storage accounts
print_out_sa() {
    mapfile -t sa_array < <(az storage account list --query "[].{Name:name}" -o tsv)
    for i in "${sa_array[@]}"; do
        echo "$i"
    done
}

# Select storage account group
check_sa_list() {
    local sa_exists=false
    while [[ "$sa_exists" = false ]]; do
        print_out_sa
        read -rp "Enter storage account from the list: " storage_account
        for j in "${sa_array[@]}"; do
            if [[ "$storage_account" == "$j" ]]; then
                sa_exists=true
                echo "Storage account '$storage_account' correctly selected."
                break
            else
                continue
            fi
        done
    done
}

#Check if a storage account name is available to use.
check_sa_not_available() {
    while true; do
        read -rp "Enter a name for your storage account: " storage_account
        if [ "$(az storage account check-name --name "$storage_account" --query nameAvailable)" = false ]; then
            echo "The storage account '$storage_account' already exists and it's not available, please provide another name..."
        else
            echo "The selected storage account '$storage_account' is available to use"
            break
        fi
    done
}

#Create new storage account (default values)
create_sa() {
    echo "asas"
}

#Create new storage account or select one from list
select_sa() {
    while true; do
        read -rp "Create new storage account? (yes|no): " sa_answer
        case $sa_answer in
        yes | YES | Yes | y)
            echo "You answered yes."
            check_sa_not_available
            create_sa
            break
            ;;
        no | NO | No | n)
            echo "You answered no. Select storage account from list."
            check_sa_list
            break
            ;;
        *)
            echo "Invalid input. Only 'yes' or 'no' is accepted."
            ;;
        esac
    done
}

#-----------------------------------END STORAGE ACCOUNT SETUP-------------------------------------#

#setup
#check_file_exists $1
select_region
select_rg
select_sa
