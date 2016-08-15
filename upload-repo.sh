#!/bin/bash

# Simple script to upload the contents of the github to a 
# WASB public bucket
#
#	Assumptions;
#		WASB_ACCOUNT and WASB_CONTAINER exist already


WASB_CONTAINER=deployment-v101
WASB_ACCOUNT=maprpublic
WASB_KEY="RySs9wl/Ny8kOmtL2HAn+A6j78L0xGEVjz+wy6umWEneoU54aA6cNCPjVCi6ZxPm0yUPtYt2eCWw0yN9cGwthA=="

TOP_LEVEL=private-azure

for f in `git ls-files` ; do
	azure storage blob upload $f $WASB_CONTAINER "$TOP_LEVEL/$f" \
		-a $WASB_ACCOUNT -k "$WASB_KEY" -q
done

