# CyberSpeed Project
Infrastructure as Code solution for deploying a scalable web application stack

Naming convention on Azure resources was not applied on purposes, since this is a POC.
In a real scenario however, the following naming convention would be applied to all resources and forced through Terraform/Terragrunt:

    - {companyAbbreviation}-{EnvironmentName}-{ResourceType}-{BriefResourceDescription}

    An example on how some resources would look like:

    AKS:
    - cbs-dev-aks-cluster01

    Key Vault:
    - cbs-dev-kv-central

    Storage Account:
    - cbsdevsaterraform (here it must be all together as per the resource requirement)


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

    - Run 
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
    - Navigate to \container-images\application;
    - Build the image with: 
      ```bash
      docker build -t "<YOURACRNAME>.azurecr.io/application:v2" . --no-cache
      ```
    - Push The image to the container registry:
      ```bash
      docker push "pocacr2024.azurecr.io/web:v1"
      ```  

    The following steps will deploy the Kubernetes manifest files to AKS:

    - Navigate to '\kubernetes\poc';
    - Apply all files recursively (deployments, secrets, services, pv, pvc, ingress, ingress-controller)
        ```bash
        kubectl apply -R -f .
        ```

    We have now the application up and running.

    3. Any additional considerations or notes related to containerization and scalability.

    - Network Policies have been implemented with Calico to ensure no pods will communicate to each other, the only traffic allowed in the cluster is:
    [Ingress -> Application -> Database] in this order, the reverse is not allowed.
    Anything else is denied by a 'deny all' rule.

    - Naming Convention has been applied to the Kubernetes manifest files:
      - It starts with an environment folder;
      - Within the folder it has all the applications (e.g. app1, new-api, database);
      - within each folder, all the k8s components have their own folder (in plural, lowercase), and the file name will be the application name. To give an example:
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
