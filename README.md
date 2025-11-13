# Azure API Management Demo

This repository contains demonstrations and examples for Azure API Management (APIM) integration patterns and best practices.

## Repository Structure

```
.
├── modules/              # Reusable Bicep modules for Azure resources
├── passthrough-access-control/  # OAuth 2.0 passthrough authentication demo
├── shared/              # Shared utilities and snippets
└── requirements.txt     # Python dependencies for all demos
```

## Demos

### Passthrough Access Control

The `passthrough-access-control` folder contains a comprehensive demo showcasing OAuth 2.0 authorization using identity providers to enable fine-grained access control to backend APIs through Azure API Management.

#### Overview

This demo demonstrates how to:
- Implement OAuth 2.0 authorization using Microsoft Entra ID (formerly Azure AD)
- Configure Azure API Management as a secure gateway with JWT validation
- Enable passthrough authentication to backend services (ServiceNow, Cognigy, etc.)
- Apply fine-grained access control based on user roles and claims

#### Architecture

The solution uses Azure API Management to validate OAuth 2.0 tokens from Microsoft Entra ID before forwarding requests to backend services. This enables:
- Centralized authentication and authorization
- User-specific access control to backend APIs
- Token validation with role-based access control (RBAC)
- Secure passthrough of authenticated requests

#### Key Features

- **OAuth 2.0 Device Flow**: Interactive authentication using Microsoft Entra ID
- **JWT Token Validation**: APIM validates tokens and enforces claim requirements
- **Role-Based Access**: Fine-grained authorization using app roles
- **Backend Integration**: Supports multiple backend types (ServiceNow, Cognigy)
- **Infrastructure as Code**: Complete Bicep templates for automated deployment
- **Monitoring**: Integrated Application Insights and Log Analytics

#### Prerequisites

- [Python 3.12 or later](https://www.python.org/) installed
- [VS Code](https://code.visualstudio.com/) with [Jupyter extension](https://marketplace.visualstudio.com/items?itemName=ms-toolsai.jupyter)
- [Azure Subscription](https://azure.microsoft.com/free/) with Contributor + RBAC Administrator or Owner roles
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) installed and authenticated

#### Getting Started

1. **Install Dependencies**
   ```bash
   pip install -r requirements.txt
   ```

2. **Navigate to the Demo**
   ```bash
   cd passthrough-access-control
   ```

3. **Open the Notebook**
   - Open `demo.ipynb` in VS Code
   - Follow the step-by-step instructions
   - Execute cells sequentially or click "Run All"

#### What Gets Deployed

The demo deploys the following Azure resources:

- **Log Analytics Workspace**: Centralized logging and monitoring
- **Application Insights**: Application performance monitoring
- **API Management Service**: API gateway with OAuth validation
- **App Registration**: Microsoft Entra ID application for authentication
- **Backend Configuration**: Passthrough API with custom authentication

#### Files in the Demo

- `demo.ipynb`: Main interactive Jupyter notebook with step-by-step instructions
- `main.bicep`: Infrastructure as Code template defining all Azure resources
- `policy.xml`: APIM policy for JWT validation and backend routing
- `params.json`: Generated deployment parameters (created during execution)
- `clean-up-resources.ipynb`: Cleanup notebook to remove deployed resources

#### Security Features

The demo implements several security best practices:

- **JWT Token Validation**: Validates tokens from Microsoft Entra ID
- **Claim-Based Authorization**: Enforces role requirements using token claims
- **Secure Secrets**: Uses Azure Key Vault for certificate storage
- **Custom Domain Support**: Optional SSL/TLS configuration
- **App Roles**: Fine-grained access control using application roles

#### Fine-Grained Authorization

The demo supports advanced authorization scenarios:

- **Role-Based Access**: Define app roles and assign users/groups
- **Claim Validation**: Enforce specific claims in JWT tokens
- **Group Claims**: Authorize based on user group memberships
- **Custom Scopes**: Configure application-specific OAuth scopes

Example policy fragment for role validation:
```xml
<required-claims>
    <claim name="roles" match="any">
        <value>ServiceNow</value>
    </claim>
</required-claims>
```

#### Cleanup

When finished with the demo:

1. Open `clean-up-resources.ipynb`
2. Run all cells to delete:
   - Azure resource group and all resources
   - App registration in Microsoft Entra ID

This ensures no ongoing Azure charges and keeps your subscription clean.

## Additional Resources

- [Azure API Management Documentation](https://learn.microsoft.com/azure/api-management/)
- [OAuth 2.0 Authorization in APIM](https://learn.microsoft.com/azure/api-management/api-management-authenticate-authorize-azure-openai#oauth-20-authorization-using-identity-provider)
- [JWT Validation Policy](https://learn.microsoft.com/azure/api-management/validate-azure-ad-token-policy)
- [Zero Trust App Roles Best Practices](https://learn.microsoft.com/security/zero-trust/develop/configure-tokens-group-claims-app-roles)

## Contributing

This repository demonstrates Azure API Management patterns and best practices. Feel free to explore, modify, and adapt the demos for your specific use cases.

## License

See [LICENSE](LICENSE) file for details.
