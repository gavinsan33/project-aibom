# Maintainers

How this site is built, and what the project depends on outside its repositories. Nothing here is a secret. The values themselves live in each repository's settings.

## Repositories

| Repository | Role |
|------------|------|
| [`aibom-webhook-service`](https://github.com/gavinsan33/aibom-webhook-service) | Webhook, watcher, postprocess Job and the two Helm charts |
| [`oc-aibom`](https://github.com/gavinsan33/oc-aibom) | The `oc aibom` CLI and its krew manifest |
| [`aibom-console-plugin`](https://github.com/gavinsan33/aibom-console-plugin) | The OpenShift console plugin and its Helm chart |
| [`project-aibom`](https://github.com/gavinsan33/project-aibom) | This repo: the three above as submodules, plus the combined docs site |

Edit docs in the source repo that owns them. This repo holds only the site theme, `mkdocs.yml` and the home page.

## How the site publishes

1. A push to `main` in a source repo runs its `notify-monorepo` workflow, which sends a `source-updated` dispatch to this repo.
2. The `Sync from source repos` workflow (`sync.yml`) runs `git submodule update --remote` and commits the new submodule pointers to `main`. It also runs nightly at 06:17 UTC, in case a dispatch was missed.
3. The `Docs` workflow (`docs.yml`) runs after a successful sync, and on pushes to the root docs config. It builds with `mkdocs build --strict` and deploys to GitHub Pages. Pull requests get the build but no deploy.

Each source repo also builds its own docs standalone on pull requests, so a broken link fails there first.

## Accounts, secrets and settings

| What | Where | Used for | If it lapses |
|------|-------|----------|--------------|
| `MONOREPO_DISPATCH_TOKEN` | Secret in the webhook, plugin and CLI repos | A fine-grained personal access token with Contents read/write on this repo, so the source repos can trigger the sync | Syncs fall back to the nightly run. The token has an expiry and belongs to one person. |
| GitHub Pages source | This repo's Settings, Pages | Must be set to "GitHub Actions" | The deploy job fails. |
| `QUAY_ROBOT_USERNAME`, `QUAY_ROBOT_TOKEN` | Secrets in the webhook and plugin repos | A push-only Quay robot account that publishes the Helm charts | Chart publishing fails. Images are unaffected, see below. |
| `RELEASE_APP_ID`, `RELEASE_APP_PRIVATE_KEY` | Secrets in the CLI repo | A GitHub App whose token the release workflow uses to push the krew manifest commit to `main` | CLI releases fail at the manifest step. |
| Quay build triggers | Quay web UI, per image repository | Builds each image from `main` and pushes `:latest` and `:<commit sha>` | Images stop updating. These triggers are not defined in any repo. |

## Quay

Everything is published under `quay.io/gsanders`.

- **Images:** `aibom-webhook-service`, `aibom-postprocess` and `aibom-console-plugin`. Each has a build trigger set up once in the Quay UI, pointing at the GitHub repository, branch `main` and the image's Dockerfile. The plugin's is `/Dockerfile`. Check the others in the Quay UI, since the trigger settings aren't in any repo.
- **Charts:** `aibom-webhook`, `aibom-workload-namespace` and `aibom-console-plugin`, as OCI artifacts. The `chart-publish` workflow pushes them on pushes to `main` that touch chart paths. Each gets a mutable `<version>` tag and an immutable `<version>-<sha>` tag.
- **Visibility:** the repositories must be public, or every installer needs pull credentials. Docs and install commands hard-code `quay.io/gsanders`.

## Releasing the CLI

Push a tag matching `v*` to `oc-aibom`. The `release` workflow builds the archives with `make dist`, creates the GitHub release with checksums, then updates `plugins/aibom.yaml` (version and sha256 values) on `main`. The repo itself is the krew index:

```sh
oc krew index add oc-aibom https://github.com/gavinsan33/oc-aibom.git
```

## Handing the project over

Things that are tied to the current owner and need recreating or moving:

- The three source repos and this one, which live under the `gavinsan33` account. Moving them changes `site_url`, every `repo_url`, the install commands in the docs, the submodule URLs in `.gitmodules`, the `notify-monorepo` target and the krew index URL.
- The Quay organization and its robot account.
- `MONOREPO_DISPATCH_TOKEN`, replaced by a token from the new owner. A GitHub App would avoid the personal expiry.
- The `oc-aibom` release GitHub App and its two secrets.
- The Pages setting and the three Quay build triggers, neither of which is in version control.
