#!/usr/bin/env bash
# Gera o IPAddressPool do MetalLB a partir da subnet real da rede docker do cluster.
#
# A rede docker do kind (normalmente chamada "kind") e alocada dinamicamente
# pelo Docker e varia por host/execucao, entao um CIDR fixo em ippool.yml
# nao funciona de forma confiavel entre maquinas.
#
# Uso:
#   ./scripts/setup-metallb-pool.sh [rede-docker]
#
# Se a rede nao for informada, usa "kind".
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

NETWORK="${1:-kind}"

if ! docker network inspect "$NETWORK" >/dev/null 2>&1; then
  echo "Rede docker '$NETWORK' não encontrada. Suba o cluster primeiro (ex: kind create cluster --config k8s/clusters/kind/kind_cluster.yml)." >&2
  exit 1
fi

SUBNET="$(docker network inspect "$NETWORK" \
    -f '{{range .IPAM.Config}}{{.Subnet}}{{"\n"}}{{end}}' \
    | grep -E '^[0-9]+\.[0-9]+\.' | head -n1)"

if [ -z "$SUBNET" ]; then
  echo "Não encontrei subnet IPv4 na rede docker '$NETWORK' (rede dual-stack ou IPv6-only?)." >&2
  exit 1
fi

IFS='.' read -r OCT1 OCT2 _ <<< "$SUBNET"

RANGE="${OCT1}.${OCT2}.255.200-${OCT1}.${OCT2}.255.250"

cat > k8s/metallb/ippool.yml <<EOF
---
# Gerado por scripts/setup-metallb-pool.sh a partir da subnet da rede docker
# "${NETWORK}" (${SUBNET}). Regenere sempre que recriar o cluster.
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: first-pool
  namespace: metallb-system
spec:
  addresses:
    - ${RANGE}
EOF

echo "Pool do MetalLB atualizado para: ${RANGE} (rede docker '${NETWORK}', subnet ${SUBNET})"
