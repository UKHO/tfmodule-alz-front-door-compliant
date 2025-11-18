# Platform Deployment Example

This example demonstrates how the Platform Team deploys the core Front Door infrastructure.

## Prerequisites

1. **Azure Subscription** with appropriate permissions
2. **Terraform** >= 1.0 installed
3. **Azure CLI** installed (recommended) or Service Principal credentials

## Authentication Options

### Option 1: Azure CLI (Recommended for Local Development)

```bash
# Login to Azure
az login

# Set the subscription (if you have multiple)
az account set --subscription "Your-Subscription-Name-or-ID"

# Verify you're logged in
az account show
```

### Option 2: Service Principal (Recommended for CI/CD)

Create environment variables:

```bash
# Linux/macOS
export ARM_CLIENT_ID="00000000-0000-0000-0000-000000000000"
export ARM_CLIENT_SECRET="your-client-secret"
export ARM_SUBSCRIPTION_ID="00000000-0000-0000-0000-000000000000"
export ARM_TENANT_ID="00000000-0000-0000-0000-000000000000"

# Windows PowerShell
$env:ARM_CLIENT_ID="00000000-0000-0000-0000-000000000000"
$env:ARM_CLIENT_SECRET="your-client-secret"
$env:ARM_SUBSCRIPTION_ID="00000000-0000-0000-0000-000000000000"
$env:ARM_TENANT_ID="00000000-0000-0000-0000-000000000000"

# Windows CMD
set ARM_CLIENT_ID=00000000-0000-0000-0000-000000000000
set ARM_CLIENT_SECRET=your-client-secret
set ARM_SUBSCRIPTION_ID=00000000-0000-0000-0000-000000000000
set ARM_TENANT_ID=00000000-0000-0000-0000-000000000000
```

### Option 3: Managed Identity (Azure Resources Only)

When running in Azure (e.g., Azure DevOps, GitHub Actions with Federated Identity), Managed Identity is automatically used.

## Required Permissions

The identity needs these permissions:
- `Microsoft.Cdn/*` - Full access to Front Door resources
- `Microsoft.Network/frontDoors/*` - Front Door management
- Resource Group Contributor role on the target resource group

## Deployment Steps

### 1. Initialize Terraform

```bash
cd c:\pgit\tfmodule-alz-front-door-compliant\examples\platform-deployment
terraform init
```

### 2. Review Configuration

Edit `main.tf` and customize:
- `front_door_name` - Your Front Door name (must be globally unique)
- `resource_group_name` - Target resource group
- `sku_name` - Standard or Premium
- `shared_endpoints` - Configure shared endpoints for teams
- `tags` - Add your tags

### 3. Plan Deployment

```bash
terraform plan -out=tfplan
```

Review the plan to ensure:
- Front Door profile will be created
- WAF policy is enabled
- Endpoints are configured correctly
- Security policies are attached

### 4. Apply Configuration

```bash
terraform apply tfplan
```

### 5. Share Outputs with Teams

After successful deployment, share these details with delivery teams:

```bash
terraform output
```

Delivery teams need:
- `front_door_name` - To reference in their modules
- `resource_group_name` - Location of the Front Door
- Shared endpoint names - For their routes

## Post-Deployment

### Verify WAF Policy

```bash
# Check WAF policy
az network front-door waf-policy show \
  --name wafplatform \
  --resource-group rg-platform-networking
```

### Monitor Front Door

```bash
# View Front Door details
az afd profile show \
  --name company-frontdoor \
  --resource-group rg-platform-networking
```

### Set Up Monitoring (Optional)

Create Log Analytics workspace and diagnostic settings to monitor:
- Access logs
- WAF logs
- Metrics

## Updating the Platform

When updating:

1. **Communicate with teams** before making changes
2. **Test in non-production** first
3. **Review plan carefully** - ensure no team routes are affected
4. **Safe changes:**
   - Adding new endpoints
   - Updating WAF managed rule versions
   - Adding tags
   - Adjusting WAF custom rules

5. **Risky changes (coordinate with teams):**
   - Changing SKU
   - Renaming endpoints
   - Changing WAF mode
   - Deleting resources

## Troubleshooting

### Authentication Errors

```
Error: building account: unable to configure ResourceManagerAccount
```

**Solution:** Ensure you're authenticated via Azure CLI or environment variables.

```bash
# Check current Azure CLI login
az account show

# Login if needed
az login
```

### Name Already Exists

```
Error: A resource with the ID already exists
```

**Solution:** Front Door names must be globally unique. Change `front_door_name` in `main.tf`.

### Insufficient Permissions

```
Error: authorization failed
```

**Solution:** Ensure your account has Contributor role on the resource group.

### Timeout Errors During Destroy

```
Error: polling after Delete: context deadline exceeded
```

**Cause:** Front Door deletions can take 30-60 minutes because it's a global service with DNS propagation.

**Solution:**

1. **Check if actually deleted:**
   ```bash
   az afd profile show \
     --name company-frontdoor \
     --resource-group rg-platform-networking
   ```

2. **If deleted (404 error):**
   ```bash
   # Clean up state
   cd c:\pgit\tfmodule-alz-front-door-compliant\examples\platform-deployment
   
   # Option 1: Remove specific resources from state
   terraform state list
   terraform state rm <resource_address>
   
   # Option 2: Start fresh (backup first!)
   Copy-Item terraform.tfstate terraform.tfstate.backup
   Remove-Item terraform.tfstate*
   ```

3. **If still exists:**
   ```bash
   # Wait and try again later (15-30 minutes)
   terraform destroy
   
   # Or manually delete in Azure Portal
   # Then clean up state as above
   ```

4. **Manual cleanup (if needed):**
   ```bash
   # Delete via Azure CLI (may also timeout but continues in background)
   az afd profile delete \
     --name company-frontdoor \
     --resource-group rg-platform-networking \
     --no-wait
   
   # Delete resource group
   az group delete \
     --name rg-platform-networking \
     --yes \
     --no-wait
   ```

**Prevention:** Front Door deletions are slow by design. Plan accordingly:
- Use `--target` to destroy specific resources first
- Delete in stages if you have dependencies
- Consider using shorter-lived test environments

### Long Creation Times

Front Door provisioning typically takes:
- **Standard SKU:** 10-15 minutes
- **Premium SKU:** 15-30 minutes
- **Global propagation:** Additional 5-10 minutes

This is normal - Front Door is provisioning across Microsoft's global network.

## Clean Up

To destroy the platform (⚠️ **this will break all team deployments**):

```bash
# WARNING: Coordinate with all teams first!
terraform destroy
```

## Cost Estimation

Expected monthly cost for this example:
- **Standard SKU:** ~$35/month base fee
- **Premium SKU:** ~$330/month base fee
- Plus usage costs (data transfer, requests)

See [COST_ESTIMATION.md](../../COST_ESTIMATION.md) for details.

## Support

For questions or issues:
- Platform Team: platform-team@company.com
- Documentation: [Platform Module README](../../modules/front-door-platform/README.md)
