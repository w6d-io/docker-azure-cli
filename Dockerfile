# Dockerfile : CI image for Azure AKS / ACR / Terraform pipelines
#
# Includes: azure-cli, kubectl, kubelogin, helm, yq, jq, kustomize, kubeconform
# Removed:  azure-functions-core-tools-4 (~500 MB), libicu-dev (only needed by func)
#
# Build: docker build -t ghcr.io/w6d-io/azure-cli-tools:latest .
# Override tool versions at build time:
#   docker build --build-arg YQ_VERSION=v4.45.1 ...
FROM debian:12-slim

ENV DEBIAN_FRONTEND=noninteractive

# Tool version pins — override at build time to bump
ARG YQ_VERSION=v4.45.1
ARG KUSTOMIZE_VERSION=v5.6.0
ARG KUBECONFORM_VERSION=v0.7.0

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      ca-certificates curl wget gpg apt-transport-https lsb-release jq git; \
    \
    # Microsoft signing key + Azure CLI repo
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
      | gpg --dearmor > /usr/share/keyrings/microsoft-prod.gpg; \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft-prod.gpg] \
      https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" \
      > /etc/apt/sources.list.d/azure-cli.list; \
    \
    apt-get update; \
    apt-get install -y --no-install-recommends azure-cli; \
    \
    # kubectl + kubelogin (via az CLI)
    az aks install-cli; \
    \
    # Helm 3 + helm3 alias (expected by w6d helper scripts)
    curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash; \
    ln -sf /usr/local/bin/helm /usr/local/bin/helm3; \
    \
    # yq (YAML processor)
    wget -qO /usr/local/bin/yq \
      "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64"; \
    chmod +x /usr/local/bin/yq; \
    \
    # kustomize
    wget -qO- "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2F${KUSTOMIZE_VERSION}/kustomize_${KUSTOMIZE_VERSION}_linux_amd64.tar.gz" \
      | tar xz -C /usr/local/bin/; \
    \
    # kubeconform (K8s manifest validation)
    wget -qO- "https://github.com/yannh/kubeconform/releases/download/${KUBECONFORM_VERSION}/kubeconform-linux-amd64.tar.gz" \
      | tar xz -C /usr/local/bin/; \
    \
    # Verify all tools
    az version; \
    kubectl version --client; \
    kubelogin --version; \
    helm version; \
    helm3 version; \
    yq --version; \
    jq --version; \
    kustomize version; \
    kubeconform -v; \
    \
    # Cleanup: remove build-only deps + caches
    apt-get purge -y --auto-remove gpg lsb-release; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/* /tmp/* /root/.cache /root/.azure

WORKDIR /workspace

SHELL ["/bin/bash", "-lc"]
