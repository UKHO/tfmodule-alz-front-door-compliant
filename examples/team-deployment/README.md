# Team Deployment Example

This example shows how delivery teams deploy their routes to the shared Front Door.

## Prerequisites

1. **Platform team has deployed** the Front Door platform module
2. **Connection details** from platform team (run this in platform-deployment folder):
   ```bash
   cd ../platform-deployment
   terraform output front_door_info
   ```
3. **Azure authentication** configured:
   ```powershell
   # Set subscription ID
   $env:ARM_SUBSCRIPTION_ID = (az account show --query id -o tsv)
   ```
4. **RBAC permissions** on the Front Door resource

## Before Deploying

Get the platform information from the platform team's terraform output:

```bash
# Navigate to platform deployment
cd c:\pgit\tfmodule-alz-front-door-compliant\examples\platform-deployment

# Get the output values
terraform output front_door_info
```

Update the values in `main.tf`:
```hcl
front_door_profile_name   = "company-frontdoor"       # profile_name from output
front_door_resource_group = "rg-platform-networking"  # resource_group from output
shared_endpoint_name      = "shared-endpoint"         # shared_endpoint_name from output
```

## Deployment Steps

### 1. Authenticate

```powershell
# PowerShell
$env:ARM_SUBSCRIPTION_ID = (az account show --query id -o tsv)
```

### 2. Initialize

```bash
cd c:\pgit\tfmodule-alz-front-door-compliant\examples\team-deployment
terraform init
```

### 3. Plan

```bash
terraform plan
```

Verify:
- Data sources find the platform resources
- Your origins and routes will be created
- No conflicts with existing routes

### 4. Apply

```bash
terraform apply
```

## Verify Deployment

### Check Your Route

```bash
# Get Front Door endpoint
az afd endpoint show \
  --profile-name company-frontdoor \
  --resource-group rg-platform-networking \
  --endpoint-name shared-endpoint

# Test your route
curl https://shared-endpoint-xyz123.azurefd.net/team-a/
```

### View Your Resources

```bash
# List your origin groups
az afd origin-group list \
  --profile-name company-frontdoor \
  --resource-group rg-platform-networking

# List your routes
az afd route list \
  --profile-name company-frontdoor \
  --resource-group rg-platform-networking \
  --endpoint-name shared-endpoint
```

## Updating Your Routes

You can safely update:
- ✅ Origin configurations
- ✅ Route settings
- ✅ Custom domains
- ✅ Rules

You **cannot** modify:
- ❌ Platform Front Door profile
- ❌ WAF policy
- ❌ Shared endpoints
- ❌ Other teams' routes

## Troubleshooting

### Data Source Not Found

```
Error: Error retrieving Front Door Profile
```

**Solution:** Verify platform information is correct:
```bash
az afd profile show \
  --name company-frontdoor \
  --resource-group rg-platform-networking
```

### Insufficient Permissions

```
Error: authorization failed for action 'Microsoft.Cdn/profiles/write'
```

**Solution:** Request appropriate RBAC permissions from platform team.

### Route Path Conflicts

```
Error: Route patterns conflict with existing routes
```

**Solution:** Choose different path patterns or coordinate with other teams.

### Health Probe Failures

Check your origin health:
```bash
az afd origin show \
  --profile-name company-frontdoor \
  --resource-group rg-platform-networking \
  --origin-group-name team-a-origin-group \
  --origin-name team-a-app
```

Ensure:
- Origin is accessible from Azure Front Door
- Health probe path returns 200 OK
- NSG/Firewall rules allow Front Door traffic

## Cost Tracking

Your team's costs include:
- Data transfer through your routes
- Requests to your origins
- Custom WAF rules (after first 5)
- Private endpoints (if using Premium)

Platform base fee is shared across all teams.

## Clean Up

To remove your team's configuration:

```bash
terraform destroy
```

This only removes your origins and routes. Platform resources remain intact.

## Support

- Team Lead: team-lead@company.com
- Platform Team: platform-team@company.com
- Documentation: [Delivery Module README](../../modules/front-door-delivery/README.md)

## Private Link Example (Premium SKU)

If your platform team deployed Premium SKU, you can use Private Link:

```hcl
module "team_a_routes" {
  source = "../../modules/front-door-delivery"

  front_door_profile_name   = "company-frontdoor"
  front_door_resource_group = "rg-platform-networking"
  shared_endpoint_name      = "shared-endpoint"

  origin_groups = {
    // ...existing code...
  }

  origins = {
    private_app = {
      name                           = "team-a-private-app"
      origin_group_key               = "team_a_apps"
      enabled                        = true
      host_name                      = azurerm_linux_web_app.private_app.default_hostname
      http_port                      = 80
      https_port                     = 443
      origin_host_header             = azurerm_linux_web_app.private_app.default_hostname
      priority                       = 1
      weight                         = 1000
      certificate_name_check_enabled = true

      # Private Link configuration (Premium SKU only)
      private_link = {
        request_message        = "Team A Private Link"
        target_type            = "sites"  # App Service
        location               = "eastus"
        private_link_target_id = azurerm_linux_web_app.private_app.id
      }
    }
  }

  # ...existing routes...
}
```

**After deployment:**
1. Go to Azure Portal
2. Navigate to your App Service
3. Networking > Private Endpoints
4. Approve the pending Front Door connection
