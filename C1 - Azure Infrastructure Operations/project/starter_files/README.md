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
**Your words here**

1. Login to Azure Portal/Azure CLI, upload the file tagging-policy.rule.json to your storage on cloud

2. Try to create and assign the policy to your subscribtion

    # Create the Policy Definition (Subscription scope)
    $definition = New-AzPolicyDefinition -Name 'tagging-policy' -DisplayName 'Audit any indexed resource if they do not have a tag' -description 'This policy audits if an indexed resource does not have at least one tag' -Policy 'tagging-policy.rule.json' -Mode Indexed

    # Set the scope to a resource group; may also be a subscription or management group
    $scope = Get-AzSubscription

    # Create the Policy Assignment
    $assignment = New-AzPolicyAssignment -Name 'audit-indexed-resource-assignment' -DisplayName 'Audit any indexed resource if they do not have a tag Assignment' -Scope "/subscriptions/$scope" -PolicyDefinition $definition

### Output
**Your words here**

