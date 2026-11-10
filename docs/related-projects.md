# Related projects

[k8s-aibom](https://github.com/GoogleCloudPlatform/k8s-aibom) is an unprivileged controller that inventories the AI workloads running in a cluster and writes one CycloneDX ML-BOM per serving workload, with evidence and a confidence tier on every attribute. It is the serving-side inventory for people who didn't run the workload; Project AIBOM is the run record for the people who did.

Both projects define a kind `AIBOM` with plural `aiboms`, in different API groups (`aibom.io` here, `aibom.k8saibom.dev` there), so they can be installed on the same cluster. Use the short name `aibomrun` (or `aiboms.aibom.io`) for this project's resources; `aibom` is k8s-aibom's short name, and a bare `kubectl get aiboms` resolves to whichever CRD the API server lists first. The CLI installs as `oc aibomrun`, leaving `kubectl aibom` to k8s-aibom's krew plugin.
