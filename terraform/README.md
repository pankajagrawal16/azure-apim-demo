# Terraform Modules

This directory contains Terraform modules converted from the original Bicep templates in the `modules` directory.

## Structure

```
terraform/
├── modules/
│   ├── apim/
│   │   └── v2/
│   │       ├── main.tf                 # APIM service configuration
│   │       ├── passthrough-api.tf      # Passthrough API configuration
│   │       └── specs/
│   │           └── PassThrough.json    # OpenAPI specification
│   ├── monitor/
│   │   └── v1/
│   │       └── main.tf                 # Application Insights configuration
│   └── operational-insights/
│       └── v1/
│           └── main.tf                 # Log Analytics Workspace configuration
└── azure-roles.json                    # Azure RBAC role definitions
```

## Modules

### APIM Module (v2)

Located in `modules/apim/v2/`, this module provisions:
- Azure API Management instance
- Diagnostic settings with Log Analytics
- Application Insights logger
- APIM subscriptions
- Passthrough API with backends
- API policies and diagnostics

#### Usage

```hcl
module "apim" {
  source = "./modules/apim/v2"

  resource_group_name = "my-rg"
  location            = "eastus"
  resource_suffix     = "unique"
  
  apim_sku            = "Standardv2"
  publisher_email     = "admin@example.com"
  publisher_name      = "My Company"
  
  law_id              = module.log_analytics.id
  app_insights_id     = module.app_insights.id
  app_insights_instrumentation_key = module.app_insights.instrumentation_key
  
  apim_subscriptions_config = [
    {
      name        = "subscription1"
      displayName = "Subscription 1"
    }
  ]
}
```

### Application Insights Module (v1)

Located in `modules/monitor/v1/`, this module provisions:
- Azure Application Insights instance
- Optional workbook for usage analysis

#### Usage

```hcl
module "app_insights" {
  source = "./modules/monitor/v1"

  resource_group_name              = "my-rg"
  application_insights_location    = "eastus"
  resource_suffix                  = "unique"
  
  law_id                          = module.log_analytics.id
  custom_metrics_opted_in_type    = "Off"
  
  use_workbook                    = false
  workbook_location               = "eastus"
}
```

### Log Analytics Workspace Module (v1)

Located in `modules/operational-insights/v1/`, this module provisions:
- Azure Log Analytics Workspace with system-assigned managed identity

#### Usage

```hcl
module "log_analytics" {
  source = "./modules/operational-insights/v1"

  resource_group_name       = "my-rg"
  log_analytics_location    = "eastus"
  resource_suffix           = "unique"
}
```

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) installed and authenticated
- An Azure subscription

## Deployment Workflow

1. **Initialize Terraform**
   ```bash
   terraform init
   ```

2. **Validate Configuration**
   ```bash
   terraform validate
   ```

3. **Plan Deployment**
   ```bash
   terraform plan
   ```

4. **Apply Configuration**
   ```bash
   terraform apply -auto-approve
   ```

## Notes

### Differences from Bicep

Some features available in Bicep are not directly supported in the Terraform AzureRM provider:

1. **APIM Release Channel**: The `release_channel` property is not directly supported in Terraform and would need to be configured via ARM template deployment or Azure REST API.

2. **Circuit Breaker Configuration**: Backend circuit breaker rules are not directly supported in the current azurerm provider version and would need to be configured using ARM templates or the Azure API.

3. **Custom Metrics Opted In Type**: The Application Insights `CustomMetricsOptedInType` property is not directly supported and would need ARM template configuration.

4. **Large Language Model Diagnostics**: The LLM-specific diagnostic settings in API diagnostics are not yet available in the Terraform provider.

### Best Practices

- Always run `terraform validate` before `terraform plan`
- Use remote state storage (Azure Storage Account) for production deployments
- Leverage Terraform workspaces for environment separation
- Store sensitive values in Azure Key Vault and reference them using data sources
- Use `terraform fmt` to maintain consistent code formatting
- Review the [Terraform Azure Provider documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)

## Contributing

When converting additional Bicep files to Terraform:

1. Follow the [HashiCorp Terraform Style Guide](https://developer.hashicorp.com/terraform/language/style)
2. Use meaningful variable names and descriptions
3. Add validation rules for variables where appropriate
4. Document any limitations or differences from the Bicep implementation
5. Include usage examples in comments or documentation
