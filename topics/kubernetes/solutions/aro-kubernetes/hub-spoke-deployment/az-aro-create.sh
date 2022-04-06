az aro create \
    --name $ARO_NAME \
    --resource-group $ARO_RG \
    --location $ARO_LOCATION \
    --vnet-resource-group $VNET_RG \
    --vnet $VNET \
    --master-subnet $CONTROL_PLANE_SUBNET \
    --worker-subnet $WORKER_SUBNET \
    --location $ARO_LOCATION \
    --apiserver-visibility $ARO_VISIBILITY \
    --ingress-visibility $ARO_VISIBILITY \
    --worker-vm-size $ARO_WORKER_NODE_SIZE \
    --worker-count $ARO_WORKER_NODE_COUNT \
    --pull-secret=$(cat pull-secret.txt)