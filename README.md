# VirtualMachine → OCI-BareMetal

Shell scripts to take a Virtual Machine inside Oracle VirtualBox and convert it to an image to be used by Oracle BareMetal Instance.

## IMPORTANT

Clone Virtual Machine before continuing. This process will render your Virtual Machine no longer bootable inside Oracle VirtualBox.

## Prerequirements

Your Virtual Machine must be set up to use VMDK, and the original OS must be installed with EFI and LVM enabled.

Your Virtualbox must be configured to export the VM to OCI Object storage after running the script.


## Requirements

Upload the appropriate shell script to your Virtual Machine and execute it.

From there, you will need to import a custom image with the following parameters:
	
	Image Type = VMDK
	Launch Mode = Native
	
Launch a BareMetal instance with new custom image that you created. Give the image ~30minutes to spin up. You can create a console connection into the BareMetal instance to watch the boot processes take place. After the instance is spun up, you can then ssh into it as you would your original Virtual Machine.
