#!/bin/bash
#
#
# Details on options
#	keypair : search for <keypair>.pub or <keypair>.pem 
#
# Pre-requisites
#	- VHD for boot disk will be allocated within the ResourceGroup's
#	  default storage account  OR  a newly created one.   For now,
#	  we'll create a new one each time (so that we can readily clean it up)
#	- ResourceGroup should have a VNET resource of the same name (that's
#	  the default when we use the template to create a group.
#		NOTE: we'll deploy to the default subnet unless otherwise directed
#

# set -x

THIS_SCRIPT=$0

instid=$(($RANDOM%1000))
uniqueid=`printf "%04d" $instid`

# Defaults for instance specification

ResourceGroup=deploymenttests
location="westus"
sysuser=azadmin
vmname=vm${uniqueid}
image="OpenLogic:CentOS:6.6:latest"
instance_type="Standard_D2"
keypair=jsun_azure
# keyfile=$HOME/.ssh/tucker-eng.pub


usage() {
  echo "
  Usage:
    $THIS_SCRIPT
       --location <azure-region>
       --image <AMI name>
       --instance-type <instance-type>
       [ --key-name <ssh-key>  |  --password <password> ]
       [ --storage-account <sa-name> ]
       [ --sysuser <username_for_privileged_user> ]
       [ --nametag <uniquifying instance tag> [[UNSUPPORTED]] ]
       [ --subnet <azure-subnet-name> [[UNSUPPORTED]] ]
       [ --data-disks <# of persistent drives> [[UNSUPPORTED]] ]
   "
  echo ""
  echo "EXAMPLES"
  echo "  $0 --location westus --key-name myKey --image OpenLogic:CentOS:6.6:latest --instance-type Standard_D12"
  echo ""
  echo "  $0 --location westus --key-name myKey --image OpenLogic:CentOS:6.6:latest --instance-type Standard_D12 --storage-account maprimages"
  echo ""
  echo "  $0 --location \"East US\" --key-name myCert --image <uri-to-image-boot-disk> --instance-type Standard_D4"
  echo ""
}

check_azure_env() {
		# Make sure azure command is in our path
	which azure &> /dev/null
	if [ $? -ne 0 ] ; then
		echo "Error: azure command line tool not in path"
		exit 1
	fi
}

# Sanity check key ... this is more complex than it should be
# At the end of this logic.
#	keypair is set to the TAG to use for Amazon ... not a full file
#	keyfile is the full file path to the *.pem or *.pub file for
#		use by azure command line.
#
# NOTE: this is designed to handle the case where users include
# a file as the "--key-name" argument.
#
check_ssh_key() {
	keypair=${keypair%.pub}		# strip off .pub just in case.

		# Prepend $PWD or $HOME/.ssh if keyfile is not a full path
	if [ "${keypair}" = "${keypair#/}" ] ; then
		if [ -f $PWD/${keypair}.pub ] ; then
			keyfile=$PWD/${keypair}.pub
		elif [ -f $PWD/${keypair}.pem ] ; then
			keyfile=$PWD/${keypair}.pem
		elif [ -f $HOME/.ssh/${keypair}.pub ] ; then
			keyfile=$HOME/.ssh/${keypair}.pub
		elif [ -f $HOME/.ssh/${keypair}.pem ] ; then
			keyfile=$HOME/.ssh/${keypair}.pem
		fi
	else
		if [ -f ${keypair}.pub ] ; then
			keyfile=${keypair}.pub
		elif [ -f ${keypair}.pem ] ; then
			keyfile=${keypair}.pem
		fi
	fi

	if [ -z "${keyfile}" ] ; then
		echo "Error: SSH KeyFile not found"
		echo "    (script checks for ${keypair}.pub and ${keypair}.pem)"
		exit 1
	else		# File exists ... test permssions
			# This is a kludge, since bash has no easy way to test
			# the GROUP and OTHER permissions on a file
		ssh -i $keyfile -o BatchMode=yes localhost -C exit 2>&1 | grep -q "UNPROTECTED PRIVATE KEY FILE"
		if [ $? -eq 0 ] ; then
			echo "Error: SSH KeyFile permissions are too open"
			echo "    change to read-write for USER only"
			exit 1
		fi
	fi
}


###############  START HERE ##################

# Before we start, make sure the env is set up properly
check_azure_env

# Parse and validate command line args 
while [ $# -gt 0 ]
do
  case $1 in
  --instance-type)   instance_type=$2  ;;
  --image)           image=$2 ;;
  --key-name)        keypair=$2  ;;
  --location)        location=$2  ;;
  --password)        password=$2; keypair=""  ;;
  --storage-account) storage_account=$2 ;;
  --subnet)          subnet=$2 ;;
  --sysuser)         sysuser=$2 ;;
  --data-disks)      dataDisks=$2 ;;
  --help)
     usage
     exit 0  ;;
  *)
     echo "**** Bad argument: " $1
     usage
     exit 1 ;;
  esac
  shift 2
done


if [ -z "${image}" ] ; then
	echo "No Azure image specified"
	exit 1
fi

if [ -z "${location}" ] ; then
	echo "No Azure location specified"
	exit 1
fi

[ -n "$keypair" ] && check_ssh_key

# For now, we need to use the same storage account for
# the boot disk of our instance when launching from our
# newly created image.
if [ -n "${storage_account}" ] ; then
	SA_ARG="--storage-account-name $storage_account"
elif [ -z "${image##OpenLogic*}" ] ; then
	SA_ARG="--storage-account-name ${vmname}storage"
else
	sa_name=${image%.blob.core.windows.net*}
	sa_name=${sa_name#https://}
	SA_ARG="--storage-account-name $sa_name"
fi

# Access to the VM will be via EITHER  ssh_key  OR  password .
if [ -n "$keypair" ] ; then
	ACCESS_ARG="--ssh-publickey-file $keyfile"
elif [ -n "$password" ] ; then 
	ACCESS_ARG="--admin-password $password"
else
	echo "Error: Invocation must specify key-file or password for VM access"
fi

# Non-obvious arguments
#	--public-ip-name : Name of the _resource_ representing IP address
#	--public-ip-domain-name : DNS hostname entry for the ip-name resource
#
azure vm create \
	-g $ResourceGroup \
	-n $vmname \
	-l "$location" \
	--nic-name ${vmname}-nic0 \
	--vnet-name $ResourceGroup \
	--vnet-subnet-name default \
	--public-ip-name ${vmname}-public \
	--public-ip-domain-name ${vmname} \
	--os-type Linux \
	--image-urn $image \
	$SA_ARG \
	--storage-account-container-name ${vmname}-boot \
	--vm-size $instance_type \
	--admin-username ${sysuser} \
	$ACCESS_ARG

if [ $? -eq 0 ] ; then
	vmloc=`echo "$location" | tr -d "[:space:]" | tr -s "[:upper:]" "[:lower:]"`
	vmhostname=${vmname}.${vmloc}.cloudapp.azure.com
	echo "Success !!!"
	echo "Access vm with the command 'ssh ${sysuser}@${vmhostname}'"
fi

set +x
