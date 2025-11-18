# Contributing to Azure Front Door Compliant Terraform Modules

Thank you for considering contributing to this project! 

## How to Contribute

### Reporting Issues

- Use the GitHub issue tracker
- Describe the issue clearly
- Include steps to reproduce
- Provide Terraform version and module version

### Pull Requests

1. **Fork the repository**
2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. **Make your changes**
4. **Test your changes**
   ```bash
   terraform fmt -recursive
   terraform validate
   ```
5. **Commit with clear messages**
   ```bash
   git commit -m "feat: add support for custom WAF rules"
   ```
6. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```
7. **Create a Pull Request**

## Commit Message Convention

We follow [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation changes
- `refactor:` - Code refactoring
- `test:` - Adding tests
- `chore:` - Maintenance tasks

Examples:
```
feat(platform): add support for multiple endpoints
fix(delivery): correct private link configuration
docs: update README with new examples
```

## Code Style

- Use consistent formatting: `terraform fmt -recursive`
- Follow Terraform best practices
- Add comments for complex logic
- Keep variable names descriptive

## Testing

Before submitting a PR:

1. **Format check**: `terraform fmt -check -recursive`
2. **Validation**: `terraform validate` in each module
3. **Test examples**: Ensure examples work with real Azure subscription
4. **Documentation**: Update README files if needed

## Module Structure

```
modules/
├── front-door-platform/   # Platform team module
└── front-door-delivery/   # Delivery team module
```

Changes should maintain clear separation between platform and delivery concerns.

## CI/CD Pipeline

### GitHub Actions (Automatic)
- **Purpose:** Code quality and validation
- **Trigger:** Every push and pull request
- **Actions:**
  - Terraform format validation
  - Terraform syntax validation
  - Documentation checks
  - Security scanning
- **No Azure access:** These workflows do NOT deploy to Azure

### Azure Pipelines (Manual/Controlled)
- **Purpose:** Infrastructure deployment
- **Trigger:** Manual or on main branch merge (with approvals)
- **Actions:**
  - Terraform plan
  - Approval gates
  - Terraform apply
- **Azure access:** Uses service principals with appropriate permissions

See `azure-pipelines.yml` for the deployment pipeline configuration.

## Questions?

Open an issue for discussion before starting work on major changes.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
