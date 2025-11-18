# Module Restructure - Cleanup Guide

## What Changed

The module has been restructured from a single monolithic module to a two-module architecture:

### Old Structure (Deprecated)
```
tfmodule-alz-front-door-compliant/
├── main.tf          ❌ DELETE
├── variables.tf     ❌ DELETE
├── outputs.tf       ❌ DELETE
├── versions.tf      ❌ DELETE
└── README.md        ✅ Updated
```

### New Structure (Current)
```
tfmodule-alz-front-door-compliant/
├── modules/
│   ├── front-door-platform/    ✅ NEW - Platform team
│   └── front-door-delivery/    ✅ NEW - Delivery teams
├── examples/
│   ├── platform-deployment/    ✅ NEW
│   └── team-deployment/        ✅ NEW
└── README.md                   ✅ Updated
```

## Files to Delete

### Root Level Files (No Longer Needed)

1. **main.tf** - All resources moved to modules
2. **variables.tf** - Variables moved to respective modules
3. **outputs.tf** - Outputs moved to respective modules
4. **versions.tf** - Providers moved to module-level files

### Old Example Files (If Any)

Delete any old example directories that don't follow the new structure:
- `examples/basic/` (replaced by `examples/platform-deployment/`)
- `examples/advanced/` (replaced by examples in both modules)
- `examples/private-link/` (now in `examples/team-deployment/`)

## Migration Steps

### For Existing Deployments

If you have existing Front Door deployments using the old module:

1. **Don't delete immediately** - You need to migrate state
2. **Option 1: Recreate** (Recommended for non-production)
   ```bash
   # Destroy old deployment
   terraform destroy
   
   # Deploy new platform module
   cd examples/platform-deployment
   terraform init
   terraform apply
   
   # Deploy team routes
   cd ../team-deployment
   terraform init
   terraform apply
   ```

3. **Option 2: State Migration** (For production)
   ```bash
   # Export resources from old state
   terraform state list
   
   # Move resources to new modules
   # Example:
   terraform state mv \
     azurerm_cdn_frontdoor_profile.this \
     module.front_door_platform.azurerm_cdn_frontdoor_profile.this
   
   # Repeat for all resources
   ```

### For New Deployments

1. Use the platform module for core infrastructure
2. Use the delivery module for team-specific routes
3. Follow the examples in `examples/` directory

## Cleanup Commands

### Safe Cleanup (After Migration)

```bash
# From repository root
git rm main.tf
git rm variables.tf
git rm outputs.tf
git rm versions.tf

# Remove old examples (if any)
git rm -r examples/basic/
git rm -r examples/advanced/
git rm -r examples/private-link/

# Commit changes
git commit -m "Clean up old module structure"
```

### Verify Cleanup

```bash
# Check for any remaining old files
find . -name "main.tf" -not -path "*/modules/*" -not -path "*/examples/*"
find . -name "variables.tf" -not -path "*/modules/*"
find . -name "outputs.tf" -not -path "*/modules/*"
```

## What to Keep

### Keep These Files
- ✅ `README.md` (updated)
- ✅ `.gitignore`
- ✅ `COST_ESTIMATION.md` (if exists)
- ✅ All files in `modules/` directory
- ✅ All files in `examples/` directory
- ✅ This file (`CLEANUP.md`)

### Directory Structure After Cleanup

```
tfmodule-alz-front-door-compliant/
├── .gitignore
├── README.md
├── CLEANUP.md
├── COST_ESTIMATION.md
├── modules/
│   ├── front-door-platform/
│   │   ├── providers.tf
│   │   ├── frontdoor.tf
│   │   ├── waf.tf
│   │   ├── endpoints.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   └── front-door-delivery/
│       ├── providers.tf
│       ├── data.tf
│       ├── origins.tf
│       ├── routes.tf
│       ├── custom_domains.tf
│       ├── rules.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── README.md
└── examples/
    ├── platform-deployment/
    │   └── main.tf
    └── team-deployment/
        └── main.tf
```

## Troubleshooting

### "Module not found" errors
- Ensure you're referencing the correct module path
- Platform: `./modules/front-door-platform`
- Delivery: `./modules/front-door-delivery`

### State conflicts
- If migrating from old module, use `terraform state mv`
- Consider using separate state files for platform and teams

### Old files still referenced
- Check for any custom scripts or CI/CD pipelines
- Update references to use new module paths

## Questions?

Contact: platform-team@company.com
