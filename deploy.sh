#!/usr/bin/env bash
# =============================================================================
# deploy.sh — publica a Arraial Vibe LP em PRODUÇÃO (Hostinger)
#
# Fluxo:  local -> git push -> GitHub Pages (STAGING) -> ./deploy.sh -> PRODUÇÃO
#
# Uso:
#   bash deploy.sh              # deploy (com todas as travas de segurança)
#   bash deploy.sh --status     # o que está no ar vs. o que está no git
#   bash deploy.sh --dry-run    # roda as verificações, NÃO publica
#   bash deploy.sh --force      # pula a trava de "árvore limpa/sincronizada"
# =============================================================================
set -euo pipefail

SSH_ALIAS="vibearraial"
DOMAIN_DIR="domains/vibearraial.com.br"
REMOTE_DIR="$DOMAIN_DIR/public_html"
STAGING_REMOTE="$DOMAIN_DIR/.deploy_staging"
STAMP_FILE="$DOMAIN_DIR/.deployed-commit"
SITE_URL="https://vibearraial.com.br"
STAGING_URL="https://designconverte.github.io/arraial-vibe-lp/"
MIN_FILES=20   # trava: menos que isso = upload incompleto, aborta

# Nunca enviados ao servidor (artefatos de dev/repo)
EXCLUDES=(
  --exclude=./.git
  --exclude=./.github
  --exclude=./.nojekyll
  --exclude=./README.md
  --exclude=./DEPLOY.md
  --exclude=./deploy.sh
)

# Preservados no servidor mesmo com --delete (gerenciados pela Hostinger)
PROTECT=(--exclude='.well-known/' --exclude='.htaccess')

C_OK=$'\033[32m'; C_ERR=$'\033[31m'; C_WARN=$'\033[33m'; C_INFO=$'\033[36m'; C_OFF=$'\033[0m'
ok(){   echo "${C_OK}✓${C_OFF} $*"; }
err(){  echo "${C_ERR}✗${C_OFF} $*" >&2; }
warn(){ echo "${C_WARN}!${C_OFF} $*"; }
step(){ echo; echo "${C_INFO}▸ $*${C_OFF}"; }
die(){  err "$*"; exit 1; }

cd "$(dirname "$0")"
[ -f index.html ] || die "index.html não encontrado — rode este script dentro de arraial-vibe-lp/"

MODE="deploy"
case "${1:-}" in
  --status)  MODE="status" ;;
  --dry-run) MODE="dryrun" ;;
  --force)   MODE="force" ;;
  "")        ;;
  *) die "opção desconhecida: $1 (use --status, --dry-run ou --force)" ;;
esac

remote_commit(){ ssh "$SSH_ALIAS" "cat ~/$STAMP_FILE 2>/dev/null || echo '(nenhum registro)'" 2>/dev/null || echo "(inacessível)"; }

# ----------------------------------------------------------------------- STATUS
if [ "$MODE" = "status" ]; then
  step "Situação dos ambientes"
  LOCAL_SHA=$(git rev-parse --short HEAD)
  LOCAL_MSG=$(git log -1 --pretty=%s)
  echo "  local      : $LOCAL_SHA — $LOCAL_MSG"
  git fetch -q origin 2>/dev/null || true
  echo "  origin/main: $(git rev-parse --short origin/main 2>/dev/null || echo '?')"
  echo "  staging    : $STAGING_URL"
  echo "  PRODUÇÃO   : $(remote_commit)"
  echo "               $SITE_URL"
  if [ -n "$(git status --porcelain)" ]; then
    warn "há alterações não commitadas"
  else
    ok "árvore de trabalho limpa"
  fi
  exit 0
fi

# ------------------------------------------------------------------------ GATES
step "1/5 Verificações de segurança"

if [ "$MODE" != "force" ]; then
  [ -z "$(git status --porcelain)" ] \
    || die "há alterações não commitadas. Commite e dê push (staging precisa refletir o que vai pra produção). Use --force só se souber o que está fazendo."
  ok "árvore de trabalho limpa"

  git fetch -q origin
  LOCAL_SHA=$(git rev-parse HEAD)
  REMOTE_SHA=$(git rev-parse origin/main)
  [ "$LOCAL_SHA" = "$REMOTE_SHA" ] \
    || die "local e origin/main divergem — dê push antes (o staging precisa ser idêntico à produção)."
  ok "sincronizado com origin/main (staging = o que será publicado)"
else
  warn "--force: pulando travas de git"
fi

FILE_COUNT=$(find . -path ./.git -prune -o -type f -print | wc -l | tr -d ' ')
[ "$FILE_COUNT" -ge "$MIN_FILES" ] || die "só $FILE_COUNT arquivos — esperado >= $MIN_FILES. Abortando."
ok "$FILE_COUNT arquivos prontos ($(du -sh --exclude=.git . 2>/dev/null | cut -f1))"

ssh -o BatchMode=yes -o ConnectTimeout=20 "$SSH_ALIAS" "test -d ~/$REMOTE_DIR" \
  || die "não consegui acessar ~/$REMOTE_DIR via ssh '$SSH_ALIAS'"
ok "servidor acessível e destino existe"

SHA=$(git rev-parse --short HEAD 2>/dev/null || echo "sem-git")
echo "  commit a publicar: $SHA"
echo "  no ar agora      : $(remote_commit)"

if [ "$MODE" = "dryrun" ]; then
  echo; ok "--dry-run: verificações passaram. NADA foi publicado."
  exit 0
fi

# ------------------------------------------------------------------------ UPLOAD
step "2/5 Enviando arquivos para área de preparo no servidor"
ssh "$SSH_ALIAS" "rm -rf ~/$STAGING_REMOTE && mkdir -p ~/$STAGING_REMOTE"
tar czf - "${EXCLUDES[@]}" . | ssh "$SSH_ALIAS" "cd ~/$STAGING_REMOTE && tar xzf -"
ok "upload concluído"

# ------------------------------------------------------------------- VALIDAÇÃO
step "3/5 Validando o pacote antes de tocar na produção"
UPLOADED=$(ssh "$SSH_ALIAS" "test -f ~/$STAGING_REMOTE/index.html && find ~/$STAGING_REMOTE -type f | wc -l || echo 0")
UPLOADED=$(echo "$UPLOADED" | tr -d ' ')
[ "$UPLOADED" -ge "$MIN_FILES" ] \
  || { ssh "$SSH_ALIAS" "rm -rf ~/$STAGING_REMOTE"; die "pacote incompleto ($UPLOADED arquivos). Produção NÃO foi alterada."; }
ok "pacote íntegro ($UPLOADED arquivos, index.html presente)"

# --------------------------------------------------------------------- PUBLICAR
step "4/5 Publicando em produção"
# --delete só aqui: escopo restrito ao public_html DESTE domínio, a partir de um
# pacote já validado. .well-known e .htaccess (Hostinger/SSL) são preservados.
ssh "$SSH_ALIAS" "rsync -a --delete ${PROTECT[*]} ~/$STAGING_REMOTE/ ~/$REMOTE_DIR/ \
  && printf '%s  %s\n' '$SHA' \"\$(date '+%Y-%m-%d %H:%M')\" > ~/$STAMP_FILE \
  && rm -rf ~/$STAGING_REMOTE"
ok "arquivos publicados"

# ------------------------------------------------------------------ VERIFICAÇÃO
step "5/5 Conferindo o site no ar"
sleep 2
CODE=$(curl -s -o /dev/null -m 30 -w '%{http_code}' "$SITE_URL/")
[ "$CODE" = "200" ] && ok "HTTPS responde 200" || err "HTTPS respondeu $CODE"

CANON=$(curl -s -m 30 "$SITE_URL/" | grep -o 'canonical" href="[^"]*"' | head -1)
echo "  $CANON"

for a in assets/brand/logo-branco.svg assets/video/gruta-azul-embarcacao.mp4; do
  AC=$(curl -s -o /dev/null -m 40 -r 0-500 -w '%{http_code}' "$SITE_URL/$a")
  case "$AC" in 200|206) ok "$a ($AC)";; *) err "$a ($AC)";; esac
done

echo
ok "DEPLOY CONCLUÍDO — commit $SHA no ar em $SITE_URL"
echo "  (staging permanece em $STAGING_URL)"
