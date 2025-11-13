# Azure APIM Demo

## passthrough-access-control

The `passthrough-access-control` folder contains a demonstration of OAuth 2.0 authorization using Azure API Management (APIM) with Microsoft Entra ID (formerly Azure Active Directory) for fine-grained access control to backend APIs.

### Overview

This demo implements a passthrough API that validates Azure AD tokens and enables role-based access control (RBAC) to backend services like ServiceNow or Cognigy. It demonstrates how to:

- Authenticate users using OAuth 2.0 device flow
- Validate JWT tokens with Azure AD claims (including roles)
- Route authenticated requests to backend APIs with custom authentication headers
- Implement fine-grained authorization using app roles

### Architecture

The solution uses Azure API Management as a gateway that:
1. Validates incoming Azure AD access tokens
2. Checks for required roles in the token claims
3. Forwards authenticated requests to the backend service with appropriate authentication headers

### Prerequisites

- [Python 3.12 or later](https://www.python.org/)
- [VS Code](https://code.visualstudio.com/) with [Jupyter notebook extension](https://marketplace.visualstudio.com/items?itemName=ms-toolsai.jupyter)
- Python environment with dependencies from `requirements.txt` (run `pip install -r requirements.txt`)
- [Azure Subscription](https://azure.microsoft.com/free/) with [Contributor](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles/privileged#contributor) + [RBAC Administrator](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles/privileged#role-based-access-control-administrator) or [Owner](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles/privileged#owner) roles
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) installed and authenticated

### Files in passthrough-access-control

| File | Description |
|------|-------------|
| `demo.ipynb` | Main Jupyter notebook containing step-by-step deployment and testing instructions |
| `main.bicep` | Bicep infrastructure-as-code template that defines all Azure resources (APIM, Log Analytics, Application Insights) |
| `params.json` | Parameters file generated during deployment with configuration values |
| `policy.xml` | APIM policy that validates Azure AD tokens and enforces role-based access control |
| `clean-up-resources.ipynb` | Notebook for removing deployed Azure resources |

### Getting Started

1. **Open the demo notebook**: Open `passthrough-access-control/demo.ipynb` in VS Code with Jupyter extension

2. **Configure variables**: In the first cell, adjust:
   - `resource_group_location`: Your preferred Azure region
   - `apim_sku`: API Management SKU (Developer, Basic, Standard, Premium, Standardv2)
   - `passthrough_backend_url`: Your backend API endpoint
   - `passthrough_api_type`: Backend service type (ServiceNow, Cognigy, etc.)
   - `auth_header_name` and `auth_key`: Backend authentication credentials

3. **Run the deployment**: Click "Run All" to execute all steps sequentially or run step-by-step:
   - **Step 0**: Initialize variables
   - **Step 1**: Create App Registration in Microsoft Entra ID
   - **Step 2**: Deploy Azure resources using Bicep
   - **Step 3**: (Optional) Create self-signed certificate for custom domain
   - **Step 4**: Get deployment outputs (APIM gateway URL, subscription keys)
   - **Step 5**: Initiate device flow for OAuth authentication
   - **Step 6**: Acquire access token and test the API

### Key Features

#### OAuth 2.0 Device Flow Authentication
The demo uses MSAL (Microsoft Authentication Library) to implement device flow authentication, which is ideal for:
- Command-line applications
- Devices with limited input capabilities
- Development and testing scenarios

#### Token Validation Policy
The `policy.xml` file implements:
- Azure AD token validation with tenant and client ID verification
- Role-based access control using token claims
- Backend routing with custom authentication headers

#### Role-Based Access Control (RBAC)
The solution demonstrates how to:
- Define app roles in Microsoft Entra ID
- Assign users/groups to app roles
- Validate role claims in APIM policies
- Implement fine-grained authorization

### Testing the API

After deployment, the notebook demonstrates how to:
1. Authenticate using device flow (sign in via browser with a code)
2. Obtain an access token with the required scopes and roles
3. Make authenticated requests to the APIM gateway
4. View the token claims (including roles) using JWT decoding

### Clean Up

To avoid Azure charges, use the `clean-up-resources.ipynb` notebook to:
1. Delete the resource group and all deployed resources
2. Remove the App Registration from Microsoft Entra ID

### Additional Resources

- [OAuth 2.0 authorization using identity provider](https://learn.microsoft.com/azure/api-management/api-management-authenticate-authorize-azure-openai#oauth-20-authorization-using-identity-provider)
- [Azure API Management policies](https://learn.microsoft.com/azure/api-management/api-management-policies)
- [JWT validation policy](https://learn.microsoft.com/azure/api-management/validate-azure-ad-token-policy)
- [Configure app roles and group claims](https://learn.microsoft.com/security/zero-trust/develop/configure-tokens-group-claims-app-roles)
