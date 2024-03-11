# CyberSpeed Project
Infrastructure as Code solution for deploying a scalable web application stack


## Instructions

To get started with Terragrunt, you will need the following prerequisites:
```bash
Terraform v1.3.9 or later
Terragrunt version v0.55.10 or later
Azure Service Principal
```
Once you have the prerequisites, follow these steps:

Clone the repository:

```bash
git clone https://github.com/RafaelM1994/cyberspeed-project.git
```

Add the following variables:
```powershell
$Env:TF_VAR_TF_STORAGE_ACCOUNT_NAME="value"
$Env:TF_VAR_TF_CONTAINER_NAME="value"
$Env:TF_VAR_TF_RESOURCE_GROUP_NAME="value"
$Env:TF_VAR_ENVIRONMENT_NAME="value"
$Env:TF_VAR_AZURE_CLIENT_ID = "value"
$Env:TF_VAR_AZURE_CLIENT_SECRET = "value"
$Env:TF_VAR_AZURE_SUBSCRIPTION_ID = "value"
$Env:TF_VAR_AZURE_TENANT_ID = "value"
```
Note: Some variables above will only be available when you Deploy terraform initial infrastructure, which will be shown in the step 1.1


> Grant "Contributor" and "User Access Administrator" permissions to the service principal for it to create the resources and to grant permissions to AKS to access the ACR


## 1. Set up and configuring the containerized infrastructure

  1. Bootstrapping Terraform

      To create the initial infrastructure for terraform/terragrunt to work, we create a resource group, a storage account and a key vault for secrets with the following script:

      'bootstrap\New-TerraformInfrastructure.ps1'

      - Open it, change the parameters you want;
      - Select all and run the code;

  2. Creating AKS Cluster and ACR

      The following Terragrunt module will provision the AKS cluster and the ACR, as well as the permission for AKS to pull images from the ACR:

      - Navigate to '\terragrunt\modules\azure-kubernetes-service';
      - Run:
        ```bash 
          terragrunt plan
        ```
          Check the changes and make sure all the resources are planned correctly;

      - Run: 
        ```bash
        terragrunt apply
        ```
      and accept the changes. 
      
      This will create the resources stated above.
      
      You have now the infrastructure properly set up.

## 2. Deploy the containerized web application stack
      
  The following steps will build the images:

  - First of all, authenticate with the ACR:
      ```bash
      az acr login --name "<YOURACRNAME>"
      ```
  - Navigate to \azure-devops\images\docker\application;
  - Build the image with: 
    ```bash
    docker build -t "<YOURACRNAME>.azurecr.io/application:v2" . --no-cache
    ```
  - Push The image to the container registry:
    ```bash
    docker push "<YOURACRNAME>.azurecr.io/application:v2"
    ```  

  The following steps will deploy the Kubernetes manifest files to AKS:

  - Navigate to '\kubernetes\poc';
  - Apply all files recursively (deployments, secrets, services, pv, pvc, ingress, ingress-controller)
      ```bash
      kubectl apply -R -f .
      ```

  We have now the application up and running.

## 3. Any additional considerations or notes related to containerization and scalability.

  # Containerization Notes:

  - **Network Policies** have been implemented with Calico to ensure no pods will communicate to each other, the only traffic allowed in the cluster is:
  [Ingress -> Application -> Database] in this order, the reverse is not allowed.
  Anything else is denied by a 'deny all' rule.

  - **Naming Convention** has been applied to the Kubernetes manifest files:
    - It starts with an environment folder;
    - Within the folder it has all the applications (e.g. app1, new-api, database);
    - within each folder, all the k8s components have their own folder (in plural, lowercase), and the file name will be the application name. To give an example:
    ```  
      .
      └──dev
          └── new-api
              ├── configmaps
                  └── new-api-infra.yaml
                  └── new-api-general.yaml
              ├── crons
              ├── deployments
                  └── new-api.yaml
              ├── hpas
              ├── pvcs
              ├── services
                  └── new-api.yaml
              ├── statefulsets
              └── ...
    ```
  - **Sealed Secrets** are being used to make sure the Github won't have any secret exposed. It uses a CRD called sealedsecrets that encrypt secrets that only the controller can decrypt using assymetric key.
  The normal kubernetes secret will be created in the cluster after applying the sealed secret, and the file can be uploaded to Github as any other file.

  - **Resource Limits** are defined in all the deployments. It is the maximum amount of a resource to be used by a container. This means that the container can never consume more than the memory amount or CPU amount indicated. On the other hand, it is defined the minimum guaranteed amount of a resource that is reserved for a container.
  
  - Application deployment had its **capabilities** removed except for the net_bind_service that is needed to start its main process.

# Scalability Notes:

  - **Horizontal Pod Autoscaler**: The HPA automatically increase or decrease the number of Pods in response to the workload's CPU consumption, in the application's case it is set to 50% with a minimum of 2 pods and maximum of 10.

  - **Node Affinity**: To ensure the application pods never go to the system node pool, it is being used Node affinity, where it tells to use only the nodes with "XX" label, in this case, these pods will only be scheduled in the nodes with label "agentpool=pool1". The system node pool is reserved to the Kubernetes system functionalities only, such as DNS, proxy and any other engine required by the system.

  - **Pod AntiAffinity**: Pods will NOT be scheduled on the same node as a Pod that matches the same label, e.g. 2 instances of aspnetapp, one goes to node01, and the other goes to node02

  - **Blue/Green deployment** has been implemented in a single cluster by having 2 different deployments and changing the selector labels the service should point to;
    To change it to green, simply run:
    ```bash
    kubectl apply -f \kubernetes\poc\application\services\aspnet-green.yaml
    ```
    To switch back:
    ```bash
    kubectl apply -f \kubernetes\poc\application\services\aspnet-blue.yaml
    ```
  # Future Azure DevOps Pipelines Improvements

  - A Pipeline to build, push and deploy to AKS has been added to the repo. As a future improvement, add unity testing and Dast scan
  
  # Future Security Improvements

  - Add users in the containers as non-root. Most of the images use root as default, which brings the challenge of creating another image from the base image just to set a different user.
  
  - Pods to user service accounts other than the default: By default, all pods use a service account called "default" on each namespace, and this should be changed to make sure each pod will access only their own secrets and volumes, and nothing else. This lowers the surface of attack in case of an account compromise.

  - Remove mysql pods capabilities to make it more secure. 

  - Add Authentication to Prometheus
  
  # Future Availability Improvements

  - Kubernetes blue-green deployment into multi-region multiple clusters;
  
  # Future IAC Improvements

  - More time is needed to finish ALL the manifest files to be deployed by Terraform, however, 2 modules (namespaces and ingresses) have been created to match the requirement of managing container configurations and deployments using IAC.

  # Future Monitoring Improvements

  - Finish Prometheus configuration, right now it is monitoring only itself;
  - Integrate Prometheus with Grafana to generate graphs and logs.

## Naming Conventions

  Naming convention on Azure resources was not applied on purpose, since this is a POC.
  In a real scenario however, the following naming convention would be applied to all resources and forced through Terraform/Terragrunt:

  - {companyAbbreviation}-{EnvironmentName}-{ResourceType}-{BriefResourceDescription}

  An example on how some resources would look like:

  AKS:
  - cbs-dev-aks-cluster01

  Key Vault:
  - cbs-dev-kv-central

  Storage Account:
  - cbsdevsaterraform (here it must be all together as per the resource requirement)