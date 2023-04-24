# Azure Infrastructure Operations Project: Deploying a scalable IaaS web server in Azure

### Introduction
For this project, you will write a Packer template and a Terraform template to deploy a customizable, scalable web server in Azure.

### Getting Started
1. Clone this repository

2. Create your infrastructure as code

3. Update this README to reflect how someone would use your code.

### Dependencies
1. Create an [Azure Account](https://portal.azure.com) 
2. Install the [Azure command line interface](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
3. Install [Packer](https://www.packer.io/downloads)
4. Install [Terraform](https://www.terraform.io/downloads.html)

### Instructions

I. Create Azure Policy

    1. Login to Azure Portal/Azure CLI, upload the file tagging-policy.rule.json to your storage on cloud

    2. Try to create and assign the policy to your subscribtion

        # Create the Policy Definition (Subscription scope)
        $definition=az policy definition create --name tagging-policy --rules tagging-policy.rule.json --mode Indexed


        # Set the scope to a subscription or management group
        subscription_id=$(az account show --query 'id' -o tsv)
        scope=/subscriptions/$(az account show --query 'id' -o tsv)

        # Create the Policy Assignment
        az policy assignment create --policy tagging-policy --name tagging-policy-assignment --scope  $scope

        # Check the new Azure Policy
        az policy definition show --name tagging-policy --subscription $subscription_id


II. Create new Image using Packer Template

    1. Create a new service principal (SP) with the role Contributor and the scope is your resource group where you create the image.

        az ad sp create-for-rbac --name yourCustomSP --role contributor --scopes /subscriptions/your_subscription_id/resourceGroups/your_resource_group_name

    2. After create the SP, you will receive these info:
        {
            "appId": "xxx-xxx-xxx--xxx",
            "displayName": "yourCustomSP",
            "password": "xxx-xxx-xxx--xxx",
            "tenant": "xxx-xxx-xxx--xxx"
        }
    3. Export those info above as environment variables along with the resource group where you will create and store Image:

        export ARM_CLIENT_ID="your_appID_above"
        export ARM_CLIENT_SECRET="your_password_above"
        export ARM_TENANT_ID="your_tenantID__above"
        export RG_NAME="your_resource_group_name"
        
    4. Run this command to build new Image with Packer template is the server.json file
        packer build server.json
    5. Wait until the process is complete.

III. Create new Virtual Machine Availability Set (VMAS) using Terraform and custom Image created by Packer.

    0. In the vars.tf, you can either change the default value or you can alter those values when you run the "terraform plan" command.
    1. Open the folder where you store the code and run CMD or Powershell from there.
    2. Run the terraform init command. This command downloads the Azure modules required to create the Azure resources in the Terraform configuration.

        terraform init

    3. Run this command to  creates a detailed execution plan from the main.tf file. Check what will be created from this.

            terraform plan -out solution.plan

       In case you want to alter the default value of any variable, you can use this command

            terraform plan -var var_name_in_vars.tf=your_new_value -out solution.plan

        for e.g: 

            terraform plan -var numberOfVMs=3 -out solution.plan

    4. If nothing's wrong, continue to apply that plan, which will create new resource.

            terraform apply .\solution.plan

    5. Wait until the process is complete. Then you can verify the new resources from Azure Portal.


### Output

I. New Policy definition and assignment be created
II. New image was created with Packer with the name and was stored at your specific resource group.
III. New resources was created, including: 
- A VNet, subnet
- A VMAS, VMs
- A PublicIP
- A Load Balancer using the public IP above and backend pool is the VMAS
- A NSG which will allow communication between VMs in that subnet.
- An attached disk for each VM.


### Clean resource

I. Delete resources created by Terraform:
- Run this command.
    terraform destroy
    (type yes to confirm)
II. delete the resource group which store the image created by Packer.
III. Delete the Azure Policy Assignment and Policy Definition.
