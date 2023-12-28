storageAccount=staciacazure

cd ./terraform-live

#Copy provider and backend file create locally to tffiles container
az storage blob download \
    --container-name prod-tf-files \
    --file provider.tf \
    --name provider.tf \
    --account-name $storageAccount \
    --overwrite

az storage blob download \
    --container-name prod-tf-files \
    --file backend.tf \
    --name backend.tf \
    --account-name $storageAccount \
    --overwrite

az storage blob download \
    --container-name states \
    --file prod.tfstate \
    --name prod.tfstate \
    --account-name $storageAccount \
    --overwrite