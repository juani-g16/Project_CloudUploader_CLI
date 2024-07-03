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
                echo
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
select_rg_from_list() {
    local rg_exists=false
    while [[ "$rg_exists" = false ]]; do
        read -rp "Select resource group from list: " resource_group
        for j in "${rg_array[@]}"; do
            if [[ "$resource_group" == "$j" ]]; then
                rg_exists=true
                echo "Resource group correctly selected."
                echo
                break
            else
                continue
            fi
        done
    done
}

# Check if resource group already exists.
check_rg_name_available() {
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
    echo
}

#Create new resource group or select one from list
rg_setup() {
    echo List of currently available resource groups.
    print_out_rg
    if [ ${#rg_array[@]} -eq 0 ]; then
        echo "There is no resource group on the list. Please create one."
        check_rg_name_available
        create_rg
    else
        while true; do
            read -rp "Create new resource group? (yes|no): " rg_answer
            case $rg_answer in
            yes | YES | Yes | y | Y)
                echo "You answered yes."
                check_rg_name_available
                create_rg
                break
                ;;
            no | NO | No | n | N)
                echo "You answered no."
                select_rg_from_list
                break
                ;;
            *)
                echo "Invalid input. Only 'yes' or 'no' is accepted."
                ;;
            esac
        done
    fi
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
        read -rp "Select storage account from list: " storage_account
        for j in "${sa_array[@]}"; do
            if [[ "$storage_account" == "$j" ]]; then
                sa_exists=true
                echo "Storage account '$storage_account' correctly selected."
                echo
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
    echo "Creating storage account with name '$storage_account'"
    az storage account create -n "$storage_account" -g "$resource_group" -l "$selected_region" --sku Standard_LRS | grep provisioningState
    echo
}

#Create new storage account or select one from list
sa_setup() {
    echo List of currently available storage accounts.
    print_out_sa
    if [ ${#sa_array[@]} -eq 0 ]; then
        echo "There is no storage account on the list. Please create one."
        check_sa_not_available
        create_sa
    else
        while true; do
            read -rp "Create new storage account? (yes|no): " sa_answer
            case $sa_answer in
            yes | YES | Yes | y | Y)
                echo "You answered yes."
                check_sa_not_available
                create_sa
                break
                ;;
            no | NO | No | n | N)
                echo "You answered no."
                check_sa_list
                break
                ;;
            *)
                echo "Invalid input. Only 'yes' or 'no' is accepted."
                ;;
            esac
        done
    fi
}
#-----------------------------------END STORAGE ACCOUNT SETUP-------------------------------------#

#------------------------------------------CONTAINER SETUP----------------------------------------#
#Rettrieve storage account keys list
retrieve_sa_keys() {
    mapfile -t keys_array < <(az storage account keys list -n "$storage_account" --query "[].{Value:value}" -o tsv)
}

#Print out all containers (only first key is used)
print_out_containers() {
    retrieve_sa_keys
    mapfile -t containers_array < <(az storage container list --account-name "$storage_account" --account-key "${keys_array[0]}" --query "[].{Name:name}" -o tsv)
    for i in "${containers_array[@]}"; do
        echo "$i"
    done
}

# Select container from storage account
check_containers_list() {
    local container_exists=false
    while [[ "$container_exists" = false ]]; do
        read -rp "Select container from list: " container
        for j in "${containers_array[@]}"; do
            if [[ "$container" == "$j" ]]; then
                container_exists=true
                echo "Container '$container' correctly selected."
                echo
                break
            else
                continue
            fi
        done
    done
}

#Check if a container name is available to use.
check_container_not_available() {
    while true; do
        read -rp "Enter a name for your container: " container
        if [ "$(az storage container exists --account-name "$storage_account" --account-key "${keys_array[0]}" --name "$container")" = false ]; then
            echo "The container name '$container' already exists and it's not available, please provide another name..."
        else
            echo "The selected container name '$container' is available to use"
            break
        fi
    done
}

create_container() {
    echo "Creating storage account with name '$container'"
    az storage container create -n "$container" --account-name "$storage_account" --account-key "${keys_array[0]}"
    echo
}

#Create new container or select one from list
container_setup() {
    retrieve_sa_keys
    echo List of currently available containers.
    print_out_containers
    if [ ${#containers_array[@]} -eq 0 ]; then
        echo "There is no container on the list. Please create one."
        check_container_not_available
        create_container
    else
        while true; do
            read -rp "Create new container? (yes|no): " cont_answer
            case $cont_answer in
            yes | YES | Yes | y | Y)
                echo "You answered yes."
                check_container_not_available
                create_container
                break
                ;;
            no | NO | No | n | N)
                echo "You answered no."
                check_containers_list
                break
                ;;
            *)
                echo "Invalid input. Only 'yes' or 'no' is accepted."
                ;;
            esac
        done
    fi
}
#---------------------------------------END CONTAINER SETUP---------------------------------------#

#---------------------------------------FILE UPLOAD SETUP------------------------------------------#
upload_file() {
    file=$(basename -- "$1")
    name=$file
    overwrite=true
    skip=false

    if [ "$(az storage blob exists --account-key "${keys_array[0]}" --account-name "$storage_account" --container-name "$container" --name "$file" --query "exists")" == true ]; then
        echo There is already a file with the same name. Do you wish to:
        echo "(O)overwrite the file"
        echo "(R)ename the file"
        echo "(S)kip the file"
        while true; do
            read -rp "Option: " file_answer
            case $file_answer in
            o | O | Overwrite | overwrite)
                overwrite=true
                break
                ;;
            r | R | rename | Remane)
                read -rp "Choose new file name: " name
                break
                ;;
            s | S | skip | Skip)
                echo "File upload canceled."
                skip=true
                break
                ;;
            *)
                echo "Invalid answer. Select an option from the list."
                ;;
            esac
        done
    fi

    if [ $skip = false ]; then
        if
            az storage blob upload --account-name "$storage_account" \
                --account-key "${keys_array[0]}" -c "$container" -f "$file" \
                -n "$name" --overwrite "$overwrite" >/dev/null 2>&1
        then
            echo The file was uploaded correctly.
        else
            echo There was an error trying to upload the file.
        fi
    fi
}

#---------------------------------------END FILE UPLOAD SETUP---------------------------------------#
setup
check_file_exists "$@"
echo
echo "REGION SETUP"
select_region
echo RESOURCE GROUP SETUP
rg_setup
echo STORAGE ACCOUNT SETUP
sa_setup
echo CONTAINER SETUP
container_setup
echo FILE UPLOAD
upload_file "$@"
