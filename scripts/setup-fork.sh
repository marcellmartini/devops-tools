#!/usr/bin/env bash
# Aponta os manifests do ArgoCD/preview-environment para o seu fork.
#
# Uso:
#   ./scripts/setup-fork.sh [seu-usuario-github]
#
# Se o usuário não for informado, tenta detectar a partir do remote "origin".
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

OWNER="${1:-}"
if [[ -z "$OWNER" ]]; then
  OWNER="$(git remote get-url origin | sed -E 's#.*[:/]([^/]+)/[^/]+(\.git)?$#\1#')"
fi

if [[ -z "$OWNER" ]]; then
  echo "Uso: $0 <seu-usuario-github>" >&2
  exit 1
fi

echo "Apontando manifests para o fork de: $OWNER"

while IFS= read -r f; do
  perl -pi -e "s{marcellmartini/devops-tools}{${OWNER}/devops-tools}g" "$f"
  echo "  repoURL atualizado: $f"
done < <(grep -rl "marcellmartini/devops-tools" --include="*.yaml" --include="*.yml" .)

while IFS= read -r f; do
  perl -pi -e "s{ghcr\.io/marcellmartini/go-web}{ghcr.io/${OWNER}/go-web}g" "$f"
  echo "  imagem atualizada: $f"
done < <(grep -rl "ghcr.io/marcellmartini/go-web" --include="*.yaml" --include="*.yml" .)

perl -pi -e "s{owner: marcellmartini}{owner: ${OWNER}}" \
  gitops/argocd/config/appsofapps/preview-environment.yaml
echo "  owner do generator atualizado: gitops/argocd/config/appsofapps/preview-environment.yaml"

echo
echo "Pronto. Revise as mudanças com: git diff"
echo "Depois: git add -A && git commit -m 'chore: point manifests to my fork'"
