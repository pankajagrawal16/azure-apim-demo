# Azure APIM Demo

This repository contains demonstrations and examples for Azure API Management (APIM) configurations and scenarios.

## Repository Structure

```
azure-apim-demo/
├── passthrough-access-control/    # OAuth 2.0 authorization demo for passthrough APIs
├── modules/                        # Reusable Bicep modules
│   ├── apim/                      # APIM-related modules
│   ├── monitor/                   # Azure Monitor modules
│   └── operational-insights/      # Log Analytics modules
├── shared/                         # Shared utilities and snippets
│   └── snippets/                  # Python code snippets for Jupyter notebooks
└── requirements.txt               # Python dependencies

```

## Passthrough Access Control

The `passthrough-access-control` folder contains a comprehensive demo for implementing OAuth 2.0 authorization with Azure API Management to enable fine-grained access control to backend services.

### Overview

This demo showcases how to:
- Implement OAuth 2.0 authorization using Microsoft Entra ID (formerly Azure AD)
- Configure Azure API Management to validate JWT tokens
- Enable fine-grained access control to backend APIs (ServiceNow, Cognigy, etc.)
- Use app roles for Zero Trust authorization
- Deploy infrastructure using Bicep templates

### Key Features

- **OAuth 2.0 Device Flow Authentication**: Authenticate users through Microsoft Entra ID
- **JWT Token Validation**: APIM validates Azure AD tokens with role-based claims
- **Backend Passthrough**: Route authenticated requests to various backend services
- **Custom Domain Support**: Configure custom domains with SSL certificates
- **Fine-Grained Authorization**: Use app roles and claims for precise access control

### Files

| File | Description |
|------|-------------|
| `demo.ipynb` | Main Jupyter notebook with step-by-step instructions |
| `main.bicep` | Bicep template for deploying Azure resources (APIM, Log Analytics, App Insights) |
| `policy.xml` | APIM policy configuration for JWT validation and backend routing |
| `params.json` | Deployment parameters (generated during execution) |
| `clean-up-resources.ipynb` | Notebook for cleaning up deployed resources |

### Prerequisites

- [Python 3.12 or later](https://www.python.org/)
- [VS Code](https://code.visualstudio.com/) with [Jupyter extension](https://marketplace.visualstudio.com/items?itemName=ms-toolsai.jupyter)
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) installed and authenticated
- [Azure Subscription](https://azure.microsoft.com/free/) with appropriate permissions:
  - [Contributor](https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/privileged#contributor) + [RBAC Administrator](https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/privileged#role-based-access-control-administrator), or
  - [Owner](https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/privileged#owner)

### Setup

1. Install Python dependencies:
   ```bash
   pip install -r requirements.txt
   ```

2. Sign in to Azure CLI:
   ```bash
   az login
   ```

3. Open `passthrough-access-control/demo.ipynb` in VS Code

4. Execute the notebook cells sequentially or click "Run All"

### What Gets Deployed

The demo deploys the following Azure resources:
- **Azure API Management** instance (Standardv2 SKU by default)
- **Log Analytics Workspace** for monitoring and diagnostics
- **Application Insights** for telemetry and logging
- **App Registration** in Microsoft Entra ID for OAuth 2.0
- **Passthrough API** configured with JWT validation policy

### How It Works

1. **App Registration**: Creates a client application in Microsoft Entra ID
2. **Infrastructure Deployment**: Uses Bicep to deploy APIM and monitoring resources
3. **Device Flow Authentication**: Users authenticate using device code flow
4. **Token Validation**: APIM validates JWT tokens from Azure AD
5. **Role-Based Access**: Policy checks for specific roles/claims in the token
6. **Backend Routing**: Authenticated requests are routed to backend services (ServiceNow, Cognigy, etc.)

### Security Features

- **JWT Validation**: APIM validates tokens against Microsoft Entra ID
- **Role-Based Access Control**: Uses app roles for fine-grained authorization
- **Zero Trust Architecture**: Implements least privilege access patterns
- **Secure Key Management**: Sensitive keys stored in Azure Key Vault

### Configuration

Key configuration parameters in the notebook:

- `resource_group_location`: Azure region for deployment
- `apim_sku`: APIM pricing tier (Developer, Basic, Standard, Premium, Standardv2)
- `passthrough_backend_url`: Backend service endpoint
- `passthrough_api_type`: Backend service type (ServiceNow, Cognigy)
- `auth_header_name`: Custom authentication header name
- `custom_domain_name`: Optional custom domain configuration

### Fine-Grained Authorization

The demo supports advanced authorization scenarios:

- **Group Claims**: Use Azure AD groups for authorization
- **App Roles**: Configure app role definitions and assign users/groups (recommended)
- **Custom Claims**: Validate any claims present in the JWT token

To configure app roles:
1. Navigate to "Expose an API" in the App Registration
2. Add an Application ID URI and scope
3. Create App Roles in the "App Roles" blade
4. Assign users/groups to the App Roles
5. Update the policy.xml with required roles

### Testing

After deployment, the notebook provides:
- Access token acquisition via device flow
- Sample API requests with Bearer token authentication
- Response validation and debugging tips

Use the included tracing tool for policy debugging.

### Cleanup

To remove all deployed resources:
1. Open `clean-up-resources.ipynb`
2. Run all cells to delete the resource group and app registration

## Modules

The `modules` folder contains reusable Bicep templates:
- **apim**: API Management configurations and passthrough API modules
- **monitor**: Application Insights configuration
- **operational-insights**: Log Analytics workspace setup

## Shared Resources

The `shared` folder contains:
- **snippets**: Reusable Python code snippets for Jupyter notebooks
  - See [shared/snippets/README.md](shared/snippets/README.md) for usage details

## Requirements

Python dependencies are listed in `requirements.txt`:
- Azure SDK libraries
- OpenAI SDK
- MSAL (Microsoft Authentication Library)
- Jupyter notebook support
- Various Azure service clients

## Contributing

This repository is a demonstration project. Contributions and suggestions are welcome.

## License

See [LICENSE](LICENSE) file for details.

## Additional Resources

- [Azure API Management Documentation](https://learn.microsoft.com/azure/api-management/)
- [OAuth 2.0 Authorization with Azure APIM](https://learn.microsoft.com/azure/api-management/api-management-authenticate-authorize-azure-openai)
- [Bicep Language Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [Microsoft Entra ID Documentation](https://learn.microsoft.com/entra/identity/)
- [Zero Trust Security Model](https://learn.microsoft.com/security/zero-trust/)
