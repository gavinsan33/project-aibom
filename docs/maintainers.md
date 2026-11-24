# Maintainers

How this site is built, and what the project depends on outside its repositories. Nothing here is a secret. The values themselves live in each repository's settings.

## Repositories

| Repository | Role |
|------------|------|
| [`aibom-webhook-service`](https://github.com/gavinsan33/aibom-webhook-service) | Webhook, watcher, postprocess Job and the two Helm charts |
| [`oc-aibom`](https://github.com/gavinsan33/oc-aibom) | The `oc aibomrun` CLI and its krew manifest |
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
| `QUAY_ROBOT_USERNAME`, `QUAY_ROBOT_TOKEN` | Secrets in the webhook and plugin repos | A push-only Quay robot account that publishes the images and Helm charts. It needs push access to every image and chart repository below. | Image builds, chart publishing and releases fail. |
| `RELEASE_APP_ID`, `RELEASE_APP_PRIVATE_KEY` | Secrets in the CLI repo | A GitHub App whose token the release workflow uses to push the krew manifest commit to `main` | CLI releases fail at the manifest step. |
| Fork of `openshift-helm-charts/charts` | The releaser's GitHub account | `just catalog-submit` opens the OpenShift Helm catalog pull requests from it | Catalog submissions fail. Pass `--fork=<owner/repo>` to use another fork. |

## Quay

Everything is published under `quay.io/project-aibom`.

- **Images:** `aibom-webhook-service`, `aibom-postprocess` and `aibom-discovery` from the webhook repo, and `aibom-console-plugin` from the plugin repo. Each repo's `images` workflow rebuilds them on every push to `main` as `:latest` and `:<short sha>`. These workflows replaced Quay build triggers, so any triggers left in the Quay UI are unused.
- **Charts:** `aibom-webhook` and `aibom-workload-namespace` from the webhook repo, and `aibom-console` from the plugin repo, as OCI artifacts. The `chart-publish` workflow pushes dev builds on pushes to `main` that touch chart paths, versioned `X.Y.<Z+1>-dev.<commits>.g<sha>` from the last tag, with images at `:latest`.
- **Visibility:** the repositories must be public, or every installer needs pull credentials. Docs and install commands hard-code `quay.io/project-aibom`.

## Releasing the webhook and plugin

Push a `vX.Y.Z` tag to `aibom-webhook-service` or `aibom-console-plugin`. The `release` workflow builds the images as `:X.Y.Z`, publishes the charts with `version` and `appVersion` set to `X.Y.Z`, and attaches the chart tarballs to a GitHub release. For the webhook it also attaches `aibom-webhook-X.Y.Z-catalog.tgz`, the chart without its CRDs, and `aibom-crds.yaml`. A release fails rather than overwrite an existing image tag or chart version. Then run `just catalog-submit` in each repo to open the OpenShift Helm catalog pull requests, as a GitHub user listed in that repo's `catalog/**/OWNERS`.

## Releasing the CLI

Push a tag matching `v*` to `oc-aibom`. The `release` workflow builds the archives with `make dist`, creates the GitHub release with checksums, then updates `plugins/aibomrun.yaml` (version and sha256 values) on `main`. The repo itself is the krew index:

```sh
oc krew index add oc-aibom https://github.com/gavinsan33/oc-aibom.git
```

## Handing the project over

Things that are tied to the current owner and need recreating or moving:

- The three source repos and this one, which live under the `gavinsan33` account. Moving them changes `site_url`, every `repo_url`, the install commands in the docs, the submodule URLs in `.gitmodules`, the `notify-monorepo` target and the krew index URL.
- The Quay organization and its robot account.
- The fork of `openshift-helm-charts/charts` used by `just catalog-submit`, and the `users` in each `catalog/**/OWNERS` file. The catalog only accepts submissions from those GitHub users, so add the new owner there before their first submission.
- `MONOREPO_DISPATCH_TOKEN`, replaced by a token from the new owner. A GitHub App would avoid the personal expiry.
- The `oc-aibom` release GitHub App and its two secrets.
- The Pages setting, which isn't in version control.
