#!/usr/bin/env bash
# Instala as ferramentas de linha de comando usadas na oficina de GitOps com
# ArgoCD, em versoes fixas, sem precisar de sudo.
#
# Uso:
#   ./scripts/install-deps.sh                 # mostra esta ajuda
#   ./scripts/install-deps.sh all             # instala todos os grupos
#   ./scripts/install-deps.sh 1               # instala apenas o grupo 1
#   ./scripts/install-deps.sh 1 3             # instala os grupos 1 e 3
#   ./scripts/install-deps.sh base slides     # grupos tambem valem pelo nome
#   ./scripts/install-deps.sh --list          # lista grupos, ferramentas e versoes
#   ./scripts/install-deps.sh --force all     # reinstala mesmo se a versao ja bater
#
# Variaveis de ambiente:
#   INSTALL_DIR         destino dos binarios (padrao: ~/.local/bin)
#   <FERRAMENTA>_VERSION  sobrescreve a versao fixada
#                         (ex: KIND_VERSION=v0.30.0 ./scripts/install-deps.sh 1)
#
# O Docker NAO e instalado: o script apenas verifica se o daemon responde.
set -euo pipefail

# ---------------------------------------------------------------------------
# Versoes fixadas
#
# argocd CLI acompanha a versao do servidor instalada pela oficina
# (gitops/argocd/install/kustomization.yaml). helm fica na linha 3.x porque e
# a que o ArgoCD v2.12 usa para renderizar os charts. kubectl acompanha a
# node image padrao do kind (kindest/node:v1.36.1).
# ---------------------------------------------------------------------------
KUBECTL_VERSION="${KUBECTL_VERSION:-v1.36.3}"
KIND_VERSION="${KIND_VERSION:-v0.32.0}"
K9S_VERSION="${K9S_VERSION:-v0.51.0}"
ARGOCD_VERSION="${ARGOCD_VERSION:-v2.12.4}"
KUSTOMIZE_VERSION="${KUSTOMIZE_VERSION:-v5.8.1}"
HELM_VERSION="${HELM_VERSION:-v3.21.3}"
PRESENTERM_VERSION="${PRESENTERM_VERSION:-v0.16.1}"

INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"
FORCE=0
INSTALLED_SUMMARY=""

# ---------------------------------------------------------------------------
# Log
# ---------------------------------------------------------------------------
if [ -t 1 ]; then
  C_RESET=$'\033[0m'; C_BOLD=$'\033[1m'; C_YELLOW=$'\033[33m'; C_RED=$'\033[31m'
else
  C_RESET=""; C_BOLD=""; C_YELLOW=""; C_RED=""
fi

log()  { echo "${C_BOLD}==>${C_RESET} $*"; }
info() { echo "    $*"; }
warn() { echo "${C_YELLOW}aviso:${C_RESET} $*" >&2; }
die()  { echo "${C_RED}erro:${C_RESET} $*" >&2; exit 1; }

# Imprime o bloco de comentario do topo do arquivo, sem os '#'.
usage() {
  awk 'NR == 1 { next } /^#/ { sub(/^# ?/, ""); print; next } { exit }' "$0"
}

# ---------------------------------------------------------------------------
# Grupos
# ---------------------------------------------------------------------------
ALL_GROUPS="1 2 3 4"

group_tools() {
  case "$1" in
    1|base)      echo "kubectl kind k9s" ;;
    2|argocd)    echo "argocd" ;;
    3|manifests) echo "kustomize helm" ;;
    4|slides)    echo "presenterm" ;;
    *)           return 1 ;;
  esac
}

group_description() {
  case "$1" in
    1|base)      echo "base       cluster local e navegacao" ;;
    2|argocd)    echo "argocd     CLI do ArgoCD (login, app sync, troubleshooting)" ;;
    3|manifests) echo "manifests  renderizar manifests localmente" ;;
    4|slides)    echo "slides     apresentar gitops/argocd/SLIDES.md" ;;
    *)           return 1 ;;
  esac
}

tool_version() {
  case "$1" in
    kubectl)    echo "$KUBECTL_VERSION" ;;
    kind)       echo "$KIND_VERSION" ;;
    k9s)        echo "$K9S_VERSION" ;;
    argocd)     echo "$ARGOCD_VERSION" ;;
    kustomize)  echo "$KUSTOMIZE_VERSION" ;;
    helm)       echo "$HELM_VERSION" ;;
    presenterm) echo "$PRESENTERM_VERSION" ;;
    *)          return 1 ;;
  esac
}

list_groups() {
  echo "Grupos disponiveis ('all' instala todos):"
  echo
  local g tool
  for g in $ALL_GROUPS; do
    echo "  ${C_BOLD}${g}) $(group_description "$g")${C_RESET}"
    for tool in $(group_tools "$g"); do
      printf '       %-12s %s\n' "$tool" "$(tool_version "$tool")"
    done
    echo
  done
  echo "Destino: ${INSTALL_DIR}"
}

# ---------------------------------------------------------------------------
# Plataforma
# ---------------------------------------------------------------------------
detect_platform() {
  local kernel machine
  kernel="$(uname -s)"
  machine="$(uname -m)"

  case "$kernel" in
    Linux)  OS="linux";  OS_TITLE="Linux" ;;
    Darwin) OS="darwin"; OS_TITLE="Darwin" ;;
    *)      die "sistema operacional nao suportado: ${kernel} (o script cobre Linux e macOS)." ;;
  esac

  case "$machine" in
    x86_64|amd64)  ARCH="amd64"; ARCH_RUST="x86_64" ;;
    aarch64|arm64) ARCH="arm64"; ARCH_RUST="aarch64" ;;
    *)             die "arquitetura nao suportada: ${machine} (o script cobre amd64 e arm64)." ;;
  esac

  # presenterm publica os binarios com o nome do alvo do Rust.
  if [ "$OS" = "darwin" ]; then
    RUST_TRIPLE="${ARCH_RUST}-apple-darwin"
  else
    RUST_TRIPLE="${ARCH_RUST}-unknown-linux-gnu"
  fi
}

check_docker() {
  if ! command -v docker >/dev/null 2>&1; then
    die "Docker nao encontrado. Ele e pre-requisito da oficina e precisa ser instalado a parte: https://docs.docker.com/engine/install/"
  fi
  if ! docker info >/dev/null 2>&1; then
    die "Docker esta instalado mas o daemon nao respondeu ('docker info' falhou). Inicie o servico (sudo systemctl start docker) e confira se seu usuario esta no grupo 'docker'."
  fi
  log "Docker: $(docker --version)"
}

# ---------------------------------------------------------------------------
# Deteccao do que ja existe
# ---------------------------------------------------------------------------

# Caminho do binario: prioriza o que esta em INSTALL_DIR, senao o do PATH.
tool_path() {
  local tool="$1"
  if [ -x "${INSTALL_DIR}/${tool}" ]; then
    printf '%s' "${INSTALL_DIR}/${tool}"
  else
    command -v "$tool" 2>/dev/null || true
  fi
}

# Primeiro vX.Y.Z que aparece na saida de versao da ferramenta.
# Sem binario ou sem conseguir extrair, devolve string vazia.
installed_version() {
  local tool="$1" bin out=""
  bin="$(tool_path "$tool")"
  [ -n "$bin" ] || return 0

  case "$tool" in
    kubectl)    out="$("$bin" version --client 2>/dev/null || true)" ;;
    kind)       out="$("$bin" --version 2>/dev/null || true)" ;;
    k9s)        out="$("$bin" version -s 2>/dev/null || true)" ;;
    argocd)     out="$("$bin" version --client 2>/dev/null || true)" ;;
    kustomize)  out="$("$bin" version 2>/dev/null || true)" ;;
    helm)       out="$("$bin" version --short 2>/dev/null || true)" ;;
    presenterm) out="$("$bin" --version 2>/dev/null || true)" ;;
  esac

  printf '%s\n' "$out" \
    | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' \
    | head -n1 \
    | sed 's/^/v/' || true
}

# ---------------------------------------------------------------------------
# Download
# ---------------------------------------------------------------------------
fetch_binary() {
  local url="$1" name="$2"
  curl -fsSL --retry 3 -o "${WORKDIR}/${name}" "$url" \
    || die "falha ao baixar ${name} de ${url}"
  chmod +x "${WORKDIR}/${name}"
  mv -f "${WORKDIR}/${name}" "${INSTALL_DIR}/${name}"
}

# $2 e o caminho do binario dentro do tarball (helm e presenterm empacotam
# dentro de um diretorio; k9s e kustomize deixam na raiz).
fetch_tarball() {
  local url="$1" inner="$2" name="$3"
  curl -fsSL --retry 3 -o "${WORKDIR}/${name}.tar.gz" "$url" \
    || die "falha ao baixar ${name} de ${url}"
  tar -xzf "${WORKDIR}/${name}.tar.gz" -C "$WORKDIR" "$inner" \
    || die "falha ao extrair ${inner} do pacote de ${name}"
  chmod +x "${WORKDIR}/${inner}"
  mv -f "${WORKDIR}/${inner}" "${INSTALL_DIR}/${name}"
}

install_kubectl() {
  fetch_binary "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/${OS}/${ARCH}/kubectl" kubectl
}

install_kind() {
  fetch_binary "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-${OS}-${ARCH}" kind
}

install_k9s() {
  fetch_tarball \
    "https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_${OS_TITLE}_${ARCH}.tar.gz" \
    "k9s" k9s
}

install_argocd() {
  fetch_binary \
    "https://github.com/argoproj/argo-cd/releases/download/${ARGOCD_VERSION}/argocd-${OS}-${ARCH}" \
    argocd
}

install_kustomize() {
  fetch_tarball \
    "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2F${KUSTOMIZE_VERSION}/kustomize_${KUSTOMIZE_VERSION}_${OS}_${ARCH}.tar.gz" \
    "kustomize" kustomize
}

install_helm() {
  fetch_tarball \
    "https://get.helm.sh/helm-${HELM_VERSION}-${OS}-${ARCH}.tar.gz" \
    "${OS}-${ARCH}/helm" helm
}

install_presenterm() {
  fetch_tarball \
    "https://github.com/mfontanini/presenterm/releases/download/${PRESENTERM_VERSION}/presenterm-${PRESENTERM_VERSION#v}-${RUST_TRIPLE}.tar.gz" \
    "presenterm-${PRESENTERM_VERSION#v}/presenterm" presenterm
}

# ---------------------------------------------------------------------------
# Instalacao
# ---------------------------------------------------------------------------
install_tool() {
  local tool="$1" wanted current

  wanted="$(tool_version "$tool")"
  current="$(installed_version "$tool")"

  # Versao certa ja disponivel conta como instalada, mesmo que venha de outro
  # lugar (asdf, gerenciador de pacotes) — por isso o resumo mostra o caminho
  # real, e nao INSTALL_DIR.
  if [ "$FORCE" -eq 0 ] && [ "$current" = "$wanted" ]; then
    info "${tool} ${wanted} ja instalado ($(tool_path "$tool"))"
  else
    if [ -n "$current" ] && [ "$current" != "$wanted" ]; then
      log "${tool}: ${current} -> ${wanted}"
    else
      log "${tool} ${wanted}"
    fi
    "install_${tool}"
  fi

  INSTALLED_SUMMARY="${INSTALLED_SUMMARY}${tool}|${wanted}|$(tool_path "$tool")"$'\n'
}

# Um binario homonimo mais cedo no PATH continua ganhando do que instalamos.
check_shadowing() {
  local tool="$1" found
  [ -x "${INSTALL_DIR}/${tool}" ] || return 0
  found="$(command -v "$tool" 2>/dev/null || true)"
  if [ -n "$found" ] && [ "$found" != "${INSTALL_DIR}/${tool}" ]; then
    warn "'${tool}' no PATH resolve para ${found}, nao para ${INSTALL_DIR}/${tool}. Ajuste a ordem do PATH ou remova o binario antigo."
  fi
}

print_summary() {
  echo
  log "Ferramentas prontas:"
  printf '%s' "$INSTALLED_SUMMARY" | while IFS='|' read -r tool version path; do
    [ -n "$tool" ] || continue
    printf '    %-12s %-10s %s\n' "$tool" "$version" "$path"
  done

  echo
  case ":${PATH}:" in
    *":${INSTALL_DIR}:"*)
      local tool
      for tool in $(printf '%s' "$INSTALLED_SUMMARY" | cut -d'|' -f1); do
        check_shadowing "$tool"
      done
      ;;
    *)
      warn "${INSTALL_DIR} nao esta no seu PATH."
      info "Adicione com:"
      info "  echo 'export PATH=\"${INSTALL_DIR}:\$PATH\"' >> ~/.zshrc && exec zsh"
      ;;
  esac

  echo
  log "Proximo passo: subir o cluster da oficina"
  info "  kind create cluster --config k8s/clusters/kind/kind_cluster.yml"
  info "  (ou 'make kind-cluster-create', que cria o cluster com o nome 'test')"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
  local args=() selected=() tools=() tool group

  while [ $# -gt 0 ]; do
    case "$1" in
      --list|-l)   detect_platform; list_groups; exit 0 ;;
      --force|-f)  FORCE=1 ;;
      --help|-h)   usage; exit 0 ;;
      -*)          echo "opcao desconhecida: $1" >&2; echo >&2; usage >&2; exit 1 ;;
      *)           args+=("$1") ;;
    esac
    shift
  done

  # Sem nenhum grupo, so mostra a ajuda: instalar exige pedido explicito.
  if [ ${#args[@]} -eq 0 ]; then
    usage
    exit 0
  fi

  for group in "${args[@]}"; do
    if [ "$group" = "all" ]; then
      selected+=($ALL_GROUPS)
      continue
    fi
    group_tools "$group" >/dev/null 2>&1 \
      || { echo "grupo desconhecido: ${group}" >&2; echo >&2; usage >&2; exit 1; }
    selected+=("$group")
  done

  # Um grupo pedido duas vezes (ex: "1 base") nao deve instalar duas vezes.
  for group in "${selected[@]}"; do
    for tool in $(group_tools "$group"); do
      case " ${tools[*]-} " in
        *" ${tool} "*) ;;
        *) tools+=("$tool") ;;
      esac
    done
  done

  detect_platform
  check_docker

  mkdir -p "$INSTALL_DIR"
  WORKDIR="$(mktemp -d)"
  trap 'rm -rf "$WORKDIR"' EXIT

  for tool in "${tools[@]}"; do
    install_tool "$tool"
  done

  print_summary
}

main "$@"
