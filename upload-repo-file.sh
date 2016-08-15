#!/bin/bash

# Simple script to upload a selection of files to our target 
# WASB public bucket
#
#	Assumptions;
#		WASB_ACCOUNT and WASB_CONTAINER exist already


[ -z "$1" ] && exit 1

WASB_CONTAINER=deployment-v101
WASB_ACCOUNT=maprpublic
WASB_KEY="RySs9wl/Ny8kOmtL2HAn+A6j78L0xGEVjz+wy6umWEneoU54aA6cNCPjVCi6ZxPm0yUPtYt2eCWw0yN9cGwthA=="

TOP_LEVEL=private-azure

for f in "$@" ; do
	wasb_target=$TOP_LEVEL/`basename $f`

	azure storage blob upload $f $WASB_CONTAINER "$wasb_target" \
		-a $WASB_ACCOUNT -k "$WASB_KEY" -q
done

