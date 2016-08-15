#!/bin/bash
#
# Simple script to run the deployment scripts within an AMI.
# This is designed EXPLICITLY for a single-node deployment
#
# NOTE: Optional $1 argument will support downloading a trial license
# for use during installation.   
#
# PATCH DESIGN :
#	This is the right place to "patch" the AMI with updated scripts/etc.
#	The Azure Template process can be used to upload files into the 
#	same directory from which this script is executed ... so we 
#	have modified the logic to check for the presense of "patches" and move
#	them into place within /home/mapr before starting the deployment.
#

THIS=`readlink -f $0`
BINDIR=`dirname $THIS`


MAPR_USER=${MAPR_USER:-mapr}
MAPR_USER_DIR=`eval "echo ~${MAPR_USER}"`
MAPR_USER_DIR=${MAPR_USER_DIR:-/home/mapr}

patch_ami() {
	AMI_SBIN=${MAPR_USER_DIR}/sbin
	for f in $(cd ${AMI_SBIN}; ls) ; do
		[ ! -f $BINDIR/$f ] && continue

		cp -p ${AMI_SBIN}/$f ${AMI_SBIN}/${f}.ami
		cp ${BINDIR}/$f ${AMI_SBIN}/$f
	done
}

patch_ami


# Download the latest trial license in case we need it
if [ -n "$1" ] ; then
	LIC_TYPE=$1
	TGT_LIC_FILE=/home/mapr/licenses/MaprMarketplace${LIC_TYPE}License.txt

	if [ ${LIC_TYPE} = "M5"  -o  ${LIC_TYPE} = "M7" ] ; then
		curl -o /tmp/lic.txt http://msazure:MyCl0ud.ms@stage.mapr.com/license/LatestDemoLicense-${LIC_TYPE}.txt
		if [ $? -eq 0  -a  -d /home/mapr/licenses ] ; then
			echo ${LIC_TYPE} > /tmp/maprlicensetype
			chmod a+rw /tmp/lic.txt

			if [ ! -f $TGT_LIC_FILE  -o  grep -q -e "Trial Edition" $TGT_LIC_FILE ] ; then
				mv /tmp/lic.txt $TGT_LIC_FILE
			fi
		fi
	fi
fi

# Initialize data used by deploy-mapr-ami.sh to allow for M5/M7 even on sandbox
THIS_HOST=`hostname`
echo "$THIS_HOST MAPRNODE0" > /tmp/maprhosts
[ "${THIS_HOST}" != "{THIS_HOST%node*}" ] && \
	echo ${THIS_HOST%node*} > /tmp/mkclustername

# And now do the work !
/home/mapr/sbin/deploy-mapr-ami.sh
[ $? -eq 0 ] && /home/mapr/sbin/deploy-mapr-data-services.sh hiveserver drill spark


# Last, but not least, install a Community Edition license on top of
# trial license so license expiration does not confuse things.
#
# NOTE: If we installed a cloud license (non-Trial), no need for 
#	Community License
if [ -n "${LIC_TYPE:-}" ] ; then
	M3_LIC_FILE=/home/mapr/licenses/MaprMarketplaceM3License.txt

	maprcli license list -json | jq -r .data[0].description | grep -q -e "Trial Edition" 
	if [ $? -ne 0  -a  -f ${M3_LIC_FILE} ] ; then
		maprcli license add -license $M3_LIC_FILE -is_file true
	fi
fi
