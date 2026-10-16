# Dependency and secret handling

## Principles

1. **Nothing sensitive in the repo.** Keystores, `key.properties`, `.env` files and
   certificates are in `.gitignore`, and gitleaks scans full history on every PR.
2. **Anything shipped in a client app is public.** API keys compiled into an APK or web
   bundle can be extracted. Treat them as identifiers, not secrets; keep real secrets on a
   server and protect endpoints with auth and quotas.
3. **Least privilege.** Every workflow declares `permissions: contents: read`. Only the
   release `publish` job gets `contents: write`.
4. **No untrusted input in shell.** Values like `github.ref_name` are passed through `env:`,
   never interpolated into `run:` scripts.

## Build-time configuration

Use compile-time defines for non-secret config:

```bash
flutter build web --dart-define=API_BASE_URL=https://api.example.com
```

```dart
const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
```

Commit a `.env.example` with names only, never values.

## Secrets in GitHub Actions

- Store values in **Settings → Secrets and variables → Actions**; scope sensitive ones to
  an **Environment** with required reviewers (e.g. `production`).
- Secrets are not exposed to workflows triggered from forks. This is why the PR pipeline
  here needs none.
- Prefer **OIDC** to long-lived cloud credentials when deploying to AWS, GCP or Azure.
- Never `echo` secrets or enable shell tracing (`set -x`) in steps that handle them.

## Dependencies

| Control | Where |
| --- | --- |
| Automated update PRs (pub + Actions) | `.github/dependabot.yml` |
| Block PRs adding known-vulnerable deps | `dependency-review` job in `security.yml` |
| Weekly outdated-package report | `outdated` job in `security.yml` |
| Reproducible installs | Commit `pubspec.lock` (this is an app) |

Review the diff of every dependency PR, including transitive changes in `pubspec.lock`.

**Hardening option:** pin third-party actions to full commit SHAs
(`uses: owner/action@<sha> # v4.1.0`). Dependabot keeps SHA pins updated.

## About the gitleaks action

`gitleaks/gitleaks-action` is free for personal accounts. For organisation-owned repos it
requires a `GITLEAKS_LICENSE` secret. If that isn't an option, replace the job with the
open-source `gitleaks` CLI or another scanner (e.g. TruffleHog), and enable GitHub's
built-in **secret scanning** and **push protection** under *Settings → Code security*.

## Adding signing later

The release workflow deliberately builds unsigned artifacts. When you're ready:

1. Create the upload keystore locally and store it **outside** the repo.
2. Save it base64-encoded as an Environment secret (plus store password and key alias).
3. In the release job, decode it to a temp file, write `android/key.properties`, build,
   then delete both files, so they never reach artifacts or caches.
4. Gate the job behind a protected Environment so only tagged releases can use it.

Consider Play App Signing so Google holds the app-signing key and you only manage an
upload key that can be reset if leaked.

## If a secret leaks

Rotate it first, remove it second. Deleting it from the latest commit does not remove it
from history, and the credential must be treated as compromised regardless.
