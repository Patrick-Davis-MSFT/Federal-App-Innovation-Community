# Remote Debugging with an ASP.NET Core API on a Container in Docker and AKS
This example demonstrates how to debug a ASP.NET Core API deployed to a container on AKS and Docker. This tutorial is intended to demonstrate a useful developer tool utilizing AKS and enable developers to do more and remove roadblocks with existing tools. 

## Prerequisites  

* Powershell 7.2.5 or latest stable
* Azure Command Line (az)
* Bicep Command Line (bicep)
* An Azure subscription with contributor rights for a resource group
* Visual Studio *Enterprise* 2019 or later with the "ASP.NET and web development" and "Azure Development" Extensions installed. 
* Docker Desktop
* Local Kubectl 

### Upgrade all local tools
* Upgrade the bicep version (Tested with 0.4.1272)
    `az bicep upgrade`
* Upgrade Azure CLI (Tested with 2.38.0)
    `az upgrade`
* Upgrade Visual Studio
    1. Go to the "Help" menu
    1. Select "Check for Updates".
* Open Docker Desktop and verify that you have the latest version (Tested with 4.9.0)
* Upgrade kubectl (Tested with 1.24.0)

### Components
* ./infrastructure/ - The bicep code for AKS and Azure Container Registry
* ./Source/DebugAPI/ - The Visual Studio Project
* ./Source/DeployFolder/ - The target folder for deployment
* ./Source/DeployThis/ - The folder with default container for debugging

## Connectivity and Modules
#VERIFY THAT YOU NEED THE PORTS
Remote Debugging requires connectivity over ports <b>4026, 4024, and 4022</b> to the container from the instance of Visual Studio connecting to it. Visual Studio web publishing requires port <b>8172</b>. This is in addition to the standard ports for container (<b>80 and 443</b>). Building the apps service on a private network could prevent communication over these ports. If necessary Azure has pre-configured VM images with Visual Studio installed and can be used from within the network to remote debug your application. 

This example uses an open ASP.NET Core API container. There are no network protections in this example. In this example the dockerfile and deployment specification exposes all the necessary debug ports

## Setup 
An Azure Kubernetes Cluster Service (AKS) and a Azure Container Registry (ACR). To reduce cost the AKS instance can be stopped when not in use to reduce cost.

### Manual

1. Create a resource group for deployment. This name will be reused in the next several steps.
1. Download this repository.
1. Open a Powershell command line to this repo folder.
1. On the command line login to Azure
        `az login`
1. Set the subscription, this step is needed if you have multiple subscriptions associated with your account
        `az account set --subscription [Subscription ID]`
1. Run the bicep command to create the necessary resources. Note the default D1 App Service plan will incur some cost. 
    `az deployment group create -g [ResourceGroup] --template-file '.\infrastructure\template.bicep' --parameters '.\infrastructure\parameters.json'`
1. [1]Build and Deploy to Local Docker. Similar steps can be performed using the docker desktop UI.
    1. Create the docker image 
        
        ```[ps]
        docker build -f .\Source\DebugWebAPI\DebugWebAPI\Dockerfile -t debugwebapilocal .\Source\DebugWebAPI\
        ```
    1. In Docker Desktop, run the image or on the command line (this will start docker on standard ports)
        ```[ps]
        docker run --name debugwebapiimage -d -p 80:80 -p 443:443 -p 4026:4026 -p 4024:4024 -p 4022:4022 debugwebapilocal
        ```
    1. Verify the local image is running on http://localhost/swagger
1. Push build to Azure Container Registry
    1. Login to Azure CLI
        ```[ps]
        az login
        ```
    1. Login to your container registry 
        ```[ps]
        az acr login --name [Azure Container Registry Name]
        ```
    1. Create the local docker image (if necessary)
        ```[ps]
        docker build -f .\Source\DebugWebAPI\DebugWebAPI\Dockerfile -t debugwebapilocal .\Source\DebugWebAPI\
        ```
    1. Tag the local image with the container
        ```[ps]
        docker tag debugwebapilocal [Azure Container Registry Name].azurecr.io/debugwebapiaks
        ```
    1. Push the image to the Azure Container Registry.
        ```[ps]
        docker push [Azure Container Registry Name].azurecr.io/debugwebapiaks
        ```
        > __Note:__
        > Once a container is pushed to the Azure Container Registry you could pull and run the container from the Azure container registry rather than pulling and pushing from your local client.
1. Deploy as a Pod to AKS and check access
    > No Namespaces are used in this creation. All pods are created in the default namespace
    1. Connect to your AKS cluster
        1. Go to the Azure Portal
        1. Browse to your AKS Cluster
        1. Click Connect. **Note** the first two commands
        1. In a local PowerShell Login to Azure CLI
            ```[ps]
            az login
            ```
        1. In the local PowerShell Set the subscription. The first command from the connect sidebar in the portal.
            ```[ps]
            az account set --subscription [Subscription ID]
            ```
        1. Connect to the AKS Cluster. The second command from the connect sidebar in the portal.
            ```[ps]
            az aks get-credentials --resource-group [Resource Group Name] --name [AKS Cluster Name]
            ```
        1. Update the `deployment.yaml` with the name of the Azure Container Registry. This will be on line ~17
        1. Create the deployment on the cluster
            ```[ps]
            kubectl apply -f ".\Source\DeployThis\deployment.yaml"
            ```
        1. Get the External IP address of the service. **Note** the EXTERNAL-IP Address
            ```[ps]
            kubectl get service
            ```
        1. Test to make sure the system is working by browsing to the site http://[EXTERNAL-IP]/swagger
        
## Remote Debugging
Remote debugging requires the debugging symbols to be deployed to the remote target. This is done by building and deploying the project in the "Debug" configuration. The instructions below publish and deploy from Visual Studio.

> <b>Notes:</b> 
> 
> * Configuration for CI/CD will need to be changed in the build pipeline of your chosen CI/CD tool (Azure DevOps, GitHub, etc.).
>
> * The deployment and configuration settings included with this project. 
> * The same Code must be deployed to the AKS cluster as what is running on the local 

### Debugging from a local Docker Desktop run
1. Enable docker on the project
1. Ensure that the docker file can be executed from the solution directory
1. Debug the program though the docker debug button
    ![docker debug button](./Files/dockerdebug.png)
1. The debugger will run as if it is hosted through IIS express with the ability to step through code

### Debugging from the AKS cluster
Note the ports in the deployment file are open and available. 
1. With AKS and the Service Running, Go to Visual Studio Enterprise and choose Debug -> "Attach Snapshot Debugger" 
    ![snapshot debugger](./Files/snapshotdebugger.png)
    1. Choose the following options
        1. In the Azure resource choose the AKS Cluster, 
        1. In the Azure Storage account choose the storage account created with the bicep file earlier. 
    1. Click Attach to enter Snapshot Debugging mode
    1. Wait for all the modules to load (about 45 seconds). The Module window is found under Debug -> Windows
1. Set a Snapshot Point
    1. Open the Code and Set a Snapshot Point like you would a breakpoint, Suggested line 25 to inspect the GUID 
    1. Click Start Collection (Adding a new snapshot location will require you to "Update Collection" using the same button)
        > *Note*: The Start Collection button will be grayed out until all modules are loaded
        ![Start Collection](./Files/startcollection.png)
        ![Update Collection](./Files/updatecollection.png)
    1. Call the Web API through the Swagger page displayed in the setup. 
    1. Click/View on the Snapshot that was created
        ![snapshot window](./Files/Snapshots.png)
    1. View the runtime values of the local variable
        ![Code Line View](./Files/codelineSnapshot.png)

## Clean Up

### Azure Resources
Delete the resource group and all contained components

### Remove local docker image
Stop the local image, then remove the image and the container

```[ps]
docker stop debugwebapiimage
docker rm debugwebapiimage 
docker rmi debugwebapilocal 
```

## References
* [dockerfiles for the profilier](https://github.com/Microsoft/vssnapshotdebugger-docker)
* [Snapshot Debugger walkthrough](https://github.com/MicrosoftDocs/visualstudio-docs/blob/10bae0fd2b2a58893d28aa1380141046704696ed/docs/debugger/debug-live-azure-kubernetes.md)