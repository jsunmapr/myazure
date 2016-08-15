#!/bin/bash
clear

azure config mode arm
subscriptionId="f1766062-4c0b-4112-b926-2508fecc5bdf"
azure account set $subscriptionId

storageAccountResourceGroupName="mapr"
storageAccountName="maprui"
containerName="deploy"
storageAccountKey=$(azure storage account keys list $storageAccountName --resource-group $storageAccountResourceGroupName --json | jq .[0].value | tr -d '"')

for f in *.*
do
    # Upload all the files from the current folder to an Azure storage container
    echo "Uploading $f"
    azure storage blob upload --blobtype block --blob $f --file $f --container $containerName --account-name $storageAccountName --account-key $storageAccountKey --quiet
done

#https://maprui.blob.core.windows.net/deploy/createUiDefinition.json
#https%3A%2F%2Fmaprui.blob.core.windows.net%2Fdeploy%2FcreateUiDefinition.json
#https://portal.azure.com/#blade/Microsoft_Azure_Compute/CreateMultiVmWizardBlade/internal_bladeCallId/anything/internal_bladeCallerParams/{"initialData":{},"providerConfig":{"createUiDefinition":"https%3A%2F%2Fmaprui.blob.core.windows.net%2Fdeploy%2FcreateUiDefinition.json"}}