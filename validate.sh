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

# Create Resource Group
newResourceGroupName="rgmapr1234"
location="westus"

azure group create --name $newResourceGroupName --location $location

# Validate template
templateUri="https://$storageAccountName.blob.core.windows.net/$containerName/mainTemplate.json"
parametersFiles="mainTemplate.password.newVNet.parameters.json mainTemplate.ssh.newVNet.parameters.json mainTemplate.password.existingVNet.parameters.json mainTemplate.ssh.existingVNet.parameters.json"

for param in $parametersFiles
do
    echo "Testing $param"
    azure group template validate --resource-group $newResourceGroupName --template-uri $templateUri --parameters-file $param
done