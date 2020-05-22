# RHEL → OCI-BareMetal

Shell scripts to take a Virtual Machine inside Oracle VirtualBox and convert it to an image to be used by Oracle BareMetal Instance.

## IMPORTANT

Clone your RHEL Virtual Machine before continuing. This process will render your Virtual Machine no longer bootable inside Oracle VirtualBox.

## Prerequirements

Your Virtual Machine must be set up to use VMDK, and the original OS must be installed with EFI and LVM enabled.

Your Virtualbox must be configured to export the VM to OCI Object storage after running the script.

From there, you will need to import a custom image with the following parameters:
	Image Type = VMDK
	Lauch Mode = Native
