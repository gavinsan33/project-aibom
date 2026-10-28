#!/usr/bin/env bash
# RBAC for the aibom developer/deployer account: cluster-scoped roles, plus
# admin in each of DEVELOPER_NAMESPACES. Run as a user who can impersonate
# system:admin. The helm field manager lets the aibom-webhook release adopt
# aibom-webhook and aibom-view without an ownership conflict.
set -euo pipefail

# Must match the aibom-webhook helm release (webhook_namespace in
# aibom-webhook-service/justfile). Override with the env var of the same name.
AIBOM_NAMESPACE="${AIBOM_NAMESPACE:-project-aibom}"
# Workload namespace(s) and the console plugin's namespace (aibom-console-plugin
# justfile default).
DEVELOPER_NAMESPACES="${DEVELOPER_NAMESPACES:-project-gavin-test aibom-console-plugin}"
# User bound to aibom-developer-cluster-resources and to admin in
# DEVELOPER_NAMESPACES. Not $(oc whoami): whoever runs this is the cluster admin.
DEVELOPER_USER="${DEVELOPER_USER:-gsanders@redhat.com}"

{
cat <<YAML
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: aibom-developer-cluster-resources
rules:
  - apiGroups: ["jobset.x-k8s.io"]
    resources: ["jobsets"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
  - apiGroups: ["aibom.io"]
    resources: ["aibomtelemetries"]
    verbs: ["create", "patch"]
  - apiGroups: ["aibom.io"]
    resources: ["aiboms/finalizers"]
    verbs: ["update"]
  # Bind (not hold, not edit) the webhook's roles and cluster-monitoring-view.
  - apiGroups: ["rbac.authorization.k8s.io"]
    resources: ["clusterroles"]
    resourceNames: ["aibom-webhook", "aibom-view", "cluster-monitoring-view"]
    verbs: ["bind"]
  - apiGroups: ["apiextensions.k8s.io"]
    resources: ["customresourcedefinitions"]
    resourceNames: ["aibomtelemetries.aibom.io"]
    verbs: ["get", "update", "patch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: aibom-webhook
  labels:
    app.kubernetes.io/managed-by: Helm
  annotations:
    meta.helm.sh/release-name: aibom-webhook
    meta.helm.sh/release-namespace: ${AIBOM_NAMESPACE}
rules:
  - apiGroups: [""]
    resources: ["pods", "namespaces"]
    verbs: ["list", "watch"]
  - apiGroups: ["batch"]
    resources: ["jobs"]
    verbs: ["list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: aibom-view
  labels:
    app.kubernetes.io/managed-by: Helm
    rbac.authorization.k8s.io/aggregate-to-view: "true"
  annotations:
    meta.helm.sh/release-name: aibom-webhook
    meta.helm.sh/release-namespace: ${AIBOM_NAMESPACE}
rules:
  - apiGroups: ["aibom.io"]
    resources: ["aiboms", "aibomtelemetries"]
    verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: aibom-developer-cluster-resources
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: aibom-developer-cluster-resources
subjects:
  - apiGroup: rbac.authorization.k8s.io
    kind: User
    name: ${DEVELOPER_USER}
YAML
for ns in $DEVELOPER_NAMESPACES; do
cat <<YAML
---
apiVersion: v1
kind: Namespace
metadata:
  name: $ns
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: aibom-developer-admin
  namespace: $ns
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: admin
subjects:
  - apiGroup: rbac.authorization.k8s.io
    kind: User
    name: $DEVELOPER_USER
YAML
done
} | oc apply --as=system:admin --server-side --field-manager=helm --force-conflicts -f -
