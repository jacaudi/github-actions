# Workflow Templates

Copy and adapt these templates for your own projects.

## Available Templates

| Template | Description |
|----------|-------------|
| [example-caller.yml](example-caller.yml) | Basic lint and test |
| [example-semantic-release.yml](example-semantic-release.yml) | Auto-version + release (recommended) |
| [example-go-sdk-release.yml](example-go-sdk-release.yml) | Go SDK: lint, test, GoReleaser hooks |
| [example-docker-helm-release.yml](example-docker-helm-release.yml) | Docker + Helm + security scan |
| [example-self-release.yml](example-self-release.yml) | For workflow-only repos |

## Key Concepts

### Conventional Commits

go-semantic-release uses [Conventional Commits](https://www.conventionalcommits.org/) for automatic versioning.

**Version bumping behavior differs based on whether you're in initial development (0.x.x) or stable release (≥1.0.0):**

| Commit Type | Version Bump (0.x.x) | Version Bump (≥1.0.0) | Example Commit |
|-------------|---------------------|----------------------|----------------|
| `feat:` | Minor (0.X.0) | Minor (x.Y.0) | `feat: add user auth` |
| `fix:` | Patch (0.0.X) | Patch (x.y.Z) | `fix: resolve timeout` |
| `feat!:` | **Minor (0.X.0)** | **Major (X.0.0)** | `feat!: redesign API` |
| `fix!:` | **Minor (0.X.0)** | **Major (X.0.0)** | `fix!: breaking bugfix` |
| `chore:`, `docs:`, etc. | Patch (0.0.X) | Patch (x.y.Z) | `chore: update deps` |

**Key Points:**
- **0.x.x versions:** Breaking changes (`feat!`, `fix!`) bump **minor**, not major (per [semver spec #4](https://semver.org/#spec-item-4))
- **≥1.0.0 versions:** Breaking changes bump **major** as expected
- The `!` suffix or `BREAKING CHANGE:` footer marks breaking changes

#### Graduating to v1.0.0

When your project is ready for stable release, you have two options:

**Option 1: Disable initial development mode**
```yaml
release:
  uses: jacaudi/github-actions/.github/workflows/semantic-release.yml@main
  with:
    allow-initial-development-versions: false  # Enforces ≥1.0.0
```

**Option 2: Manually create v1.0.0 tag**
```bash
git tag v1.0.0
git push origin v1.0.0
```

After reaching v1.0.0, all future `feat!` commits will correctly bump major version.

### GitHub App Token

Releases created by `GITHUB_TOKEN` don't trigger other workflows. Use a GitHub App:

```yaml
release:
  uses: jacaudi/github-actions/.github/workflows/semantic-release.yml@main
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
