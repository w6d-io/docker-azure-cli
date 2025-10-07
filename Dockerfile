# Dockerfile : image CI pour publier une Azure Function (Core Tools v4 + Azure CLI)
FROM debian:13-slim

ARG DEBIAN_VERSION=12
ENV DEBIAN_FRONTEND=noninteractive

# Paquets de base + clés/répos Microsoft
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      ca-certificates curl wget gpg gnupg apt-transport-https lsb-release; \
    \
    # Clé Microsoft (pour Core Tools & Azure CLI)
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
      | gpg --dearmor > /usr/share/keyrings/microsoft-prod.gpg; \
    \
    # Dépôt Core Tools (Debian)
    wget -q https://packages.microsoft.com/config/debian/${DEBIAN_VERSION}/prod.list; \
    mv prod.list /etc/apt/sources.list.d/microsoft-prod.list; \
    chown root:root /usr/share/keyrings/microsoft-prod.gpg /etc/apt/sources.list.d/microsoft-prod.list; \
    \
    # Dépôt Azure CLI
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft-prod.gpg] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" \
      > /etc/apt/sources.list.d/azure-cli.list; \
    \
    # Installations
    apt-get update; \
    apt-get install -y --no-install-recommends \
      azure-functions-core-tools-4 \
      azure-cli \
      libicu-dev; \
    \
    # Vérifs rapides (garde en cache les couches si OK)
    func --version; \
    az version; \
    \
    # Nettoyage
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*

# Répertoire de travail par défaut (CI montera le projet ici)
WORKDIR /workspace

# Bash par défaut (utile pour les scripts set -euxo pipefail)
SHELL ["/bin/bash", "-lc"]

