# Secret Scanner Demo Pipeline — GitHub Actions

A GitHub Actions CI/CD pipeline that automatically detects leaked secrets,
credentials, and vulnerabilities on every commit using Gitleaks, TruffleHog,
Snyk, and Trivy.

## What This Does

- Runs **Gitleaks** for fast pattern-based secret detection across full git history
- Runs **TruffleHog** for deeper entropy-based and verification-capable scanning
- Runs **Snyk** for dependency and code vulnerability scanning
- Runs **Trivy** for Docker image vulnerability and secret scanning
- Leverages **GitHub Push Protection** — blocks secrets before they even land in the repo
- Generates artifacts saved for 7 days as audit trail

## Tools Used

| Tool | Purpose | Detection Method |
|------|---------|-----------------|
| Gitleaks | Secret scanning | Regex pattern matching |
| TruffleHog | Deep secret scanning | Entropy analysis + verification |
| Snyk | Dependency scanning | CVE database + code analysis |
| Trivy | Image + secret scanning | CVE database + secret detection |
| GitHub Push Protection | Pre-push secret blocking | GitHub native secret scanning |

## Why All Four + Push Protection?

Each layer catches something different:

- **Gitleaks** catches credentials accidentally committed to git history
- **TruffleHog** catches high-entropy strings that don't match known patterns
- **Snyk** catches vulnerable dependencies and insecure code patterns
- **Trivy** catches vulnerabilities in the Docker image OS, packages, and secrets baked into image layers
- **GitHub Push Protection** blocks secrets before the push even completes — the earliest possible catch

## Pipeline Structure

```text
developer runs git push
         │
         ▼
┌─────────────────────────────┐
│   GitHub Push Protection    │  ← blocks secrets before repo accepts push
└─────────────────────────────┘
         │
         ▼
  push lands in repo
         │
         ▼
┌─────────────────────────────┐
│    GitHub Actions triggers  │
│                             │
│  ┌─────────────────────┐    │
│  │  gitleaks-scan      │    │
│  └─────────────────────┘    │
│  ┌─────────────────────┐    │
│  │  trufflehog-scan    │    │
│  └─────────────────────┘    │
│  ┌─────────────────────┐    │
│  │  snyk-scan          │    │
│  └─────────────────────┘    │
│  ┌─────────────────────┐    │
│  │  trivy-scan         │    │
│  └─────────────────────┘    │
└─────────────────────────────┘
         │
         ▼
  artifacts saved (7 days)
```

## GitLab vs GitHub Actions — Key Differences

| Feature | GitLab CI/CD | GitHub Actions |
|---------|-------------|----------------|
| Config file | `.gitlab-ci.yml` | `.github/workflows/*.yml` |
| Pipeline trigger | `push` to branch | `on: push` event |
| Secret storage | Settings → CI/CD → Variables | Settings → Secrets → Actions |
| Artifact storage | GitLab artifacts | `actions/upload-artifact` |
| Built-in push protection | ❌ | ✅ |
| Job visualization | Pipeline graph | Workflow graph |

## Test Results

### Secret Detection

The `test-data/fake-secrets.env` file contains intentionally planted fake
credentials to verify scanner detection worked correctly.

| Secret Type | Detected By | How |
|-------------|-------------|-----|
| Stripe Secret Key | GitHub Push Protection | Blocked push attempt |
| Stripe Secret Key | Gitleaks | Pattern match (stripe-access-token) |
| GitHub PAT | Gitleaks | Pattern match (github-pat) |

### Notable: GitHub Push Protection in Action

On the first push attempt, GitHub blocked the commit before it landed:
remote: - GITHUB PUSH PROTECTION
remote:   Push cannot contain secrets
remote:   —— Stripe Test API Secret Key ————————————
remote:   locations:
remote:     - commit: [commit-hash]
remote:       path: test-data/fake-secrets.env:5

This demonstrates pre-push protection vs post-push pipeline scanning —
two different layers of the same defense.

## Key Concepts Demonstrated

- **GitHub Actions** workflow triggered automatically on every push
- **Parallel jobs** — all four scanners run simultaneously, not sequentially
- **fetch-depth: 0** — full git history fetched for accurate secret scanning
- **continue-on-error** — pipeline reports findings without hard blocking
- **GitHub secrets** — SNYK_TOKEN stored securely, never exposed in logs
- **Job summaries** — Gitleaks renders a formatted findings table in the GitHub UI
- **Push Protection** — GitHub's native layer that catches secrets before pipeline even runs

## Why fetch-depth: 0 Matters

By default GitHub Actions only fetches the latest commit (shallow clone).
Setting fetch-depth to 0 forces a full history fetch. This matters because
secrets deleted from code still exist in git history and are still a risk.

## Comparison with GitLab Implementation

This project was also built on GitLab CI/CD. The security coverage is identical
— the same four tools, the same fake secrets test data, the same artifact
retention. The key differences are syntax and GitHub's native push protection
which adds an extra pre-push layer not present in the GitLab version.

## Local Usage

```bash
# Install Gitleaks (Windows)
choco install gitleaks

# Install TruffleHog (Windows)
choco install trufflehog

# Run Gitleaks locally
gitleaks detect --source . --verbose

# Run TruffleHog locally
trufflehog git file://. --no-verification

# Run Snyk locally
npm install -g snyk
snyk auth
snyk test

# Run Trivy locally (requires Docker)
docker build -t secret-scanner-demo .
trivy image secret-scanner-demo
```

## Author

Jerome — DevSecOps project
