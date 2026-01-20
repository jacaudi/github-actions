# Workflow Templates

Copy and adapt these templates for your own projects.

## Available Templates

| Template | Description |
|----------|-------------|
| [example-caller.yml](example-caller.yml) | Basic lint and test |
| [example-release-on-tag.yml](example-release-on-tag.yml) | Release when tag is pushed |
| [example-uplift-release.yml](example-uplift-release.yml) | Auto-tag + release (recommended) |
| [example-go-sdk-release.yml](example-go-sdk-release.yml) | Go SDK: lint, test, GoReleaser |
| [example-docker-helm-release.yml](example-docker-helm-release.yml) | Docker + Helm + security scan |
| [example-self-release.yml](example-self-release.yml) | For workflow-only repos |

## Key Concepts

### Conventional Commits

Uplift uses [Conventional Commits](https://www.conventionalcommits.org/) for automatic versioning:

| Prefix | Version Bump | Example |
|--------|--------------|---------|
| `feat:` | Minor (0.X.0) | `feat: add user auth` |
| `fix:` | Patch (0.0.X) | `fix: resolve timeout` |
| `feat!:` | Major (X.0.0) | `feat!: redesign API` |

### GitHub App Token

Tags created by `GITHUB_TOKEN` don't trigger other workflows. Use a GitHub App:

```yaml
version:
  uses: jacaudi/github-actions/.github/workflows/uplift.yml@main
  with:
    use-github-app: true
  secrets:
    app-id: ${{ secrets.APP_ID }}
    app-private-key: ${{ secrets.APP_PRIVATE_KEY }}
```

### Required Secrets

| Secret | Description |
|--------|-------------|
| `APP_ID` | GitHub App ID |
| `APP_PRIVATE_KEY` | GitHub App private key |
| `RENOVATE_TRIGGER_TOKEN` | Token with `workflow` scope (for webhook notifications) |
