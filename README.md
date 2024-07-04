# Project_CloudUploader_CLI
Small project to create a bash-based CLI tool that allows users to quickly upload files to a specified cloud storage solution (Azure in this case), providing a seamless upload experience similar to popular storage services.

## Usage
The script shall be used as follows: ./clouduploader.sh <i>path_to_file</i> <br>

### Log in and file existance check
The script will first check if the Azure CLI is installed, if not, it will install it. <br>
After that, will check if the user is logged in, if not, it will proceed to show a link to log in and a code to insert on the webpage. <br>
Finally, will check that the path provided is an actual file, if everything is correct it will move to the following steps. Otherwise, will show an error message an stop the script.

### Region setup
In this section, the script will show a list of the 10 most recommended regions to select the one where the file will be located.

### Resource group setup
In this section, the script will show a list of all the resource groups available. If there's none in the list, it will prompt the user to create one and continue to the next section.<br>
If there're groups available, the user can either select one from the list or create a new one.

### Storage account setup
In this section, the script will show a list of all the storage accounts available. If there's none in the list, it will prompt the user to create one and continue to the next section.<br>
If there're accounts available, the user can either select one from the list or create a new one.<br>
<b>Note: the options of the account created are the default, with the exception of the --sku parameter which is used "Standard_LRS" </b>

### Resource group setup
In this section, the script will show a list of all the containers available. If there's none in the list, it will prompt the user to create one and continue to the next section.<br>
If there're containers available, the user can either select one from the list or create a new one. <br>
<b>Note: the account key used for the creation of the container and the upload of the blob is always key number 1 </b>

### File upload
Once in this section, the script will check if the file already exist on the container (will check name and extension). If the name is unique, it will proceed to the upload of the file. <br>
In the case there's another file with the same name in the container, the script will ask the user to either:
- **Overwrite**: this option enables overwriting, replacing the file on the container.
- **Rename**: this option enables the user to rename the current file and upload it with another name.
- **Skip**: this option cancels the upload and finished the script execution.

In all the cases, except skip, the script will check if the file was uploaded correctly or if an error occurred during the process and will inform the user about it.