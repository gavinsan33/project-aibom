<p align="center">
  <img src="docs/assets/logo.svg" alt="" width="128">
</p>

<h1 align="center">Project AIBOM</h1>

<p align="center"><strong>A signed bill of materials for every AI workload run</strong></p>

<p align="center">
  <a href="https://gavinsan33.github.io/project-aibom/"><img src="https://img.shields.io/badge/docs-Project%20AIBOM-00897b?logo=materialformkdocs&logoColor=white" alt="Documentation"></a>
  <a href="https://github.com/gavinsan33/project-aibom/actions/workflows/docs.yml"><img src="https://img.shields.io/github/actions/workflow/status/gavinsan33/project-aibom/docs.yml?branch=main&label=docs%20build" alt="Docs build"></a>
  <a href="https://gavinsan33.github.io/project-aibom/aibom-webhook-service/"><img src="https://img.shields.io/badge/Kubernetes-1.29%2B-3f51b5?logo=kubernetes&logoColor=white" alt="Kubernetes 1.29+"></a>
</p>

An AI Bill of Materials (AIBOM) records what went into an AI workload run: the model, the dataset, the source code, the hardware, and how it performed. Project AIBOM collects that automatically on OpenShift and Kubernetes, with no changes to your workload manifests, and lets you browse and compare the results.

**Documentation: <https://gavinsan33.github.io/project-aibom/>**

> **This repo is a read-only mirror.** It aggregates the three repos below to build one combined documentation site. Issues, pull requests, and contributions belong in the source repos, not here.

## What it does

1. An admin installs the webhook and opts a namespace in with `aibom.io/enabled=true`.
2. Users run Jobs, JobSets, PyTorchJobs, or any pod requesting GPUs as usual. The webhook injects a hardware-discovery init container, dataset and training-config detection hooks, and a signing sidecar.
3. When the workload finishes, a postprocess Job compiles everything into an immutable, signed `AIBOM` custom resource in the workload's namespace.
4. Anyone with RBAC on `aiboms.aibom.io` can read, filter, and compare AIBOMs from the terminal or the OpenShift web console.

An AIBOM captures:

- **Model:** name, architecture, dtype, quantization, LoRA/fine-tuning settings, serving configuration (vLLM and trl are auto-detected).
- **Data:** datasets loaded at runtime, reconciled against what the job declared.
- **Source code:** git repository, commit, branch, and whether the tree was dirty.
- **Hardware:** CPU, GPUs, memory, network, storage, and benchmark results for the node it ran on.
- **Performance:** GPU, CPU, memory, network, and (for vLLM) serving metrics from Prometheus, with a time series that outlives Prometheus retention.
- **Outcome:** how each pod ended, including OOM kills and the limit they hit.

AIBOMs record what was declared and detected; they identify rather than verify. See the docs for the trust model and what the signatures do and do not guarantee.

For a diagram of how the pieces fit together, see [How they fit together](https://gavinsan33.github.io/project-aibom/#how-they-fit-together) on the docs site.

## The projects

| Repo | What it is |
|------|------------|
| [**aibom-webhook-service**](https://github.com/gavinsan33/aibom-webhook-service) | The admission webhook, watcher, and postprocess Job. This is where AIBOMs come from, and where you start. |
| [**oc-aibom**](https://github.com/gavinsan33/oc-aibom) | `oc aibomrun`, a `kubectl`/`oc` plugin to list, filter, inspect, diff, and compare AIBOMs, and to verify their signatures. |
| [**aibom-console-plugin**](https://github.com/gavinsan33/aibom-console-plugin) | An OpenShift web console plugin with list, detail, and compare views and telemetry charts. |

## Cloning

To get all three repos in one checkout:

```sh
git clone --recurse-submodules https://github.com/gavinsan33/project-aibom.git
```

If you already cloned without it, run `git submodule update --init`. Each submodule is pinned to the commit last synced here, so to work on one, clone its source repo instead.

## Where to start

- To learn what the project does and how to install it, read the [documentation site](https://gavinsan33.github.io/project-aibom/).
- To install, go to [aibom-webhook-service](https://github.com/gavinsan33/aibom-webhook-service) and follow its Getting Started guide.
- To read AIBOMs you already have, install [oc-aibom](https://github.com/gavinsan33/oc-aibom) or deploy the [console plugin](https://github.com/gavinsan33/aibom-console-plugin).
