#!/bin/bash
#
# Simple script to delete the VM (and all the extra resources)
# that had to be created in azure.  Check "azlaunch_script.sh" 
# for details on the lists that were created
#

ResourceGroup=deploymenttests

vmname=$1

if [ -z "$vmname" ] ; then
	echo "Usage: $0 <vmname>"
	exit 1
fi

azure vm delete -q -g $ResourceGroup -n $vmname

azure storage account delete -q -g $ResourceGroup ${vmname}storage
azure network nic delete -q -g $ResourceGroup -n ${vmname}-nic0
azure network public-ip delete -q -g $ResourceGroup -n ${vmname}-public

#
#	For VM's created as part of our pre-built image tests,
#	the boot container will be in our 'maprimages' account.
#	Make a separate call to delete that container.
#
IMAGE_ACCOUNT=maprimages
IMAGE_KEY="VkVyXnJ/eNzvMNXHFAWOsXB+MoG2991f05nROCRlASncLXA+dKKXsCeRCAjlfxKETCSlLGKbhX66dAbXJqPt4w=="

azure storage container delete -q -a $IMAGE_ACCOUNT -k $IMAGE_KEY --container ${vmname}-boot

