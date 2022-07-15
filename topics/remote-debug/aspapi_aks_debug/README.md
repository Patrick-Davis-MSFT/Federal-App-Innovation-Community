# Remote Debugging with an ASP.NET Core API on a Container in Docker and AKS
This example demonstrates how to debug a ASP.NET Core API deployed to an App Service. This tutorial is intended to demonstrate a useful developer tool utilizing Azure App Services and enable developers to do more and remove roadblocks with existing tools. 

## Prerequisites  

* Powershell
* Azure Command Line (az)
* Bicep Command Line (bicep)
* An Azure subscription with contributor rights for a resource group
* Visual Studio 2017 or later with the "ASP.NET and web development" and "Azure Development" Extensions installed. 
* Docker Desktop
* Local Kubectl 

> <b><i>Tested with Visual Studio 2022</i></b>
>  
> <b>Note</b>: When using earlier version use the cloud explorer to connect to the remote debugging. The cloud explorer was retired for Visual Studio 2022. 

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
* ./infrastructure/ - The bicep code for the App Service
* ./Source/DebugAPI/ - The Visual Studio Project
* ./Source/DeployFolder/ - The target folder for deployment
* ./Source/DeployThis/ - The folder with default container for debugging

## Connectivity
Remote Debugging requires connectivity over ports <b>4026, 4024, and 4022</b> to the App Service from the instance of Visual Studio connecting to it. Visual Studio web publishing requires port <b>8172</b>. This is in addition to the standard ports for App Services (<b>80 and 443</b>). Building the apps service on a private network could prevent communication over these ports. If necessary Azure has pre-configured VM images with Visual Studio installed and can be used from within the network to remote debug your application. 

This example uses an open ASP.NET Core API App Service. There are no network protections in this example. In this example the dockerfile exposes all the necessary debug ports

## Setup 
The Automatic Set up will only deploy 
Click here to set up the custer automatically.

Once Created skip to [here][1]

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
    1. Connect to your AKS cluster
        1. Go to the Azure Portal
        1. Browse to your AKS Cluster
        1. Click Connect. Note the first two commands
        1. In a local PowerShell Login to Azure CLI
            ```[ps]
            az login
            ```
        1. In the local PowerShell Set the subscription. The first command from the connect sidebar in the portal.
            ```[ps]
            az account set --subscription [Subscription ID]
            ```
        1. Connect to the AKS Cluster. The secondcommand from the connect sidebar in the portal.
            ```[ps]
            az aks get-credentials --resource-group [Resource Group Name] --name [AKS Cluster Name]
            ```

## Remote Debugging
Remote debugging requires the debugging symbols to be deployed to the remote target. This is done by building and deploying the project in the "Debug" configuration. The instructions below publish and deploy from Visual Studio.

> <b>Notes:</b> 
> 
> * Configuration for CI/CD will need to be changed in the build pipeline of your chosen CI/CD tool (Azure DevOps, GitHub, etc.).
>
> * The deployment and publishing settings are not included with this project. You will need to create a new deployment if you wish to make code changes for your own experimentation. 

1. Enable Remote Debugging. <i>Note: the application will restart at the end of this process.</i>
    In the Azure Portal:
    1. Go to the App Service resource
    1. Click on Configuration in the left hand menu
    1. Select "General Settings"
    1. Select "On" Under "Remote Debugging"
    1. Select your version of Visual Studio
    1. Click "Save" and "Continue" to save the settings and restart the App Service
1. Debugging remotely requires the solution be deployed from a "<i>Debug</i>" configuration. This was done earlier however may require a redeployment for remote debugging in your own App Service. To configure this setting on your own project...
    1. Right Click on the Project
    1. Select "Publish"
    1. If you have a publish configuration select look for configuration and click the edit button. 
    1. On the configuration screen select "Debug". The default is normally "Release" however this will strip all Debugging symbols and prevent the debugger from attaching. 
    1. Publish the App through the common means.
1. Attach the Visual Studio Debugger in 2022. 
    For earlier versions of Visual Studio use the Cloud Explorer (under the view menu) instead of the Connected Services
    In Visual Studio 2022
    1. Go to Connected Services in the Solution Explorer.
    1. Right Click and select "Managed Service Connections".
    1. Click "Add a Service Dependency".
    1. Login if necessary.
    1. Select the appropriate App Service and Click Select then Close.
    1. On the menu (three dots) to the right of the service open the menu. 
    1. Select Attach Debugger. This operation could take a while.
    1. Place a breakpoint in the WeatherForecastController.cs to view the code during execution. 

1. Once complete with the debugging disable the remote debugging on the app service. <i>Note: the application will restart at the end of this process.</i>
    In the Azure Portal:
    1. Go to the App Service resource
    1. Click on Configuration in the left hand menu
    1. Select "General Settings"
    1. Select "Off" Under "Remote Debugging"
    1. Click "Save" and "Continue" to save the settings and restart the App Service

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